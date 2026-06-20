import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:focusdeck/features/session/data/session_model.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';
import 'package:focusdeck/core/constants/app_constants.dart';

const _uuid = Uuid();

// Timer state
enum TimerPhase { focus, shortBreak, longBreak }

class TimerState {
  final TimerPhase phase;
  final int totalSeconds;
  final int remainingSeconds;
  final bool running;
  final int pomodorosCompleted;
  final bool finished;

  const TimerState({
    required this.phase,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.running,
    required this.pomodorosCompleted,
    required this.finished,
  });

  double get progress =>
      totalSeconds > 0 ? 1 - (remainingSeconds / totalSeconds) : 0;

  int get minutesLeft => remainingSeconds ~/ 60;
  int get secondsLeft => remainingSeconds % 60;

  TimerState copyWith({
    TimerPhase? phase,
    int? totalSeconds,
    int? remainingSeconds,
    bool? running,
    int? pomodorosCompleted,
    bool? finished,
  }) =>
      TimerState(
        phase: phase ?? this.phase,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        running: running ?? this.running,
        pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
        finished: finished ?? this.finished,
      );

  factory TimerState.initial(int plannedPomodoros) {
    const seconds = AppConstants.defaultFocusMinutes * 60;
    return TimerState(
      phase: TimerPhase.focus,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      running: false,
      pomodorosCompleted: 0,
      finished: false,
    );
  }
}

class PomodoroNotifier extends StateNotifier<TimerState> {
  final int plannedPomodoros;
  Timer? _timer;

  PomodoroNotifier({required this.plannedPomodoros})
      : super(TimerState.initial(plannedPomodoros));

  void start() {
    if (state.running || state.finished) return;
    state = state.copyWith(running: true);
    _tick();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(running: false);
  }

  void reset() {
    _timer?.cancel();
    state = TimerState.initial(plannedPomodoros);
  }

  void skipPhase() {
    _timer?.cancel();
    _onPhaseComplete();
  }

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        _onPhaseComplete();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void _onPhaseComplete() {
    if (state.phase == TimerPhase.focus) {
      final newCompleted = state.pomodorosCompleted + 1;
      state = state.copyWith(pomodorosCompleted: newCompleted, running: false);

      if (newCompleted >= plannedPomodoros) {
        state = state.copyWith(finished: true);
        return;
      }
      _moveToNextPhase();
    } else {
      // Break over -> back to focus
      _setPhase(TimerPhase.focus);
    }
  }

  void _moveToNextPhase() {
    if (state.phase == TimerPhase.focus) {
      final isLongBreak = (state.pomodorosCompleted) %
          AppConstants.sessionsBeforeLongBreak ==
          0;
      _setPhase(isLongBreak ? TimerPhase.longBreak : TimerPhase.shortBreak);
    } else {
      _setPhase(TimerPhase.focus);
    }
  }

  void _setPhase(TimerPhase phase) {
    int secs;
    switch (phase) {
      case TimerPhase.focus:
        secs = AppConstants.defaultFocusMinutes * 60;
        break;
      case TimerPhase.shortBreak:
        secs = AppConstants.defaultShortBreakMinutes * 60;
        break;
      case TimerPhase.longBreak:
        secs = AppConstants.defaultLongBreakMinutes * 60;
        break;
    }
    state = state.copyWith(
      phase: phase,
      totalSeconds: secs,
      remainingSeconds: secs,
      running: false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider =
StateNotifierProvider.family<PomodoroNotifier, TimerState, int>(
      (ref, plannedPomodoros) =>
      PomodoroNotifier(plannedPomodoros: plannedPomodoros),
);

// Session service
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(firestore: FirebaseFirestore.instance);
});

final userSessionsProvider = StreamProvider<List<Session>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.read(sessionServiceProvider).watchUserSessions(user.uid);
});

class SessionService {
  final FirebaseFirestore _firestore;

  SessionService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _sessions => _firestore.collection('sessions');

  Stream<List<Session>> watchUserSessions(String uid) {
    return _sessions
        .where('uid', isEqualTo: uid)
        .orderBy('startedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Session.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<Session> saveSession({
    required String uid,
    required String deckId,
    required String deckTitle,
    required List<String> cardTitles,
    required int plannedPomodoros,
    required int completedPomodoros,
    required SessionStatus status,
    required DateTime startedAt,
  }) async {
    final id = _uuid.v4();
    final focusMinutes =
        completedPomodoros * AppConstants.defaultFocusMinutes;
    final session = Session(
      id: id,
      uid: uid,
      deckId: deckId,
      deckTitle: deckTitle,
      cardTitles: cardTitles,
      plannedPomodoros: plannedPomodoros,
      completedPomodoros: completedPomodoros,
      focusMinutes: focusMinutes,
      status: status,
      startedAt: startedAt,
      endedAt: DateTime.now(),
    );

    await _sessions.doc(id).set(session.toMap());

    // Only count toward streak/stats if at least one pomodoro was completed.
    if (completedPomodoros > 0) {
      await _updateUserStatsAndStreak(uid, focusMinutes);
    }

    return session;
  }

  Future<void> _updateUserStatsAndStreak(String uid, int focusMinutes) async {
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final lastTimestamp = data['lastSessionDate'] as Timestamp?;
      final currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;

      int newStreak;
      if (lastTimestamp == null) {
        // First session ever.
        newStreak = 1;
      } else {
        final lastDate = lastTimestamp.toDate();
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final dayDiff = today.difference(lastDay).inDays;

        if (dayDiff == 0) {
          // Already completed a session today, streak unchanged.
          newStreak = currentStreak == 0 ? 1 : currentStreak;
        } else if (dayDiff == 1) {
          // Consecutive day, streak continues.
          newStreak = currentStreak + 1;
        } else {
          // Missed a day or more, streak resets.
          newStreak = 1;
        }
      }

      tx.set(
        userRef,
        {
          'totalSessions': FieldValue.increment(1),
          'totalFocusMinutes': FieldValue.increment(focusMinutes),
          'currentStreak': newStreak,
          'lastSessionDate': Timestamp.fromDate(now),
        },
        SetOptions(merge: true),
      );
    });
  }
}