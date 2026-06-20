import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:focusdeck/core/theme/app_theme.dart';
import 'package:focusdeck/features/deck/providers/deck_provider.dart';
import 'package:focusdeck/features/deck/data/deck_model.dart';
import 'package:focusdeck/features/session/providers/session_provider.dart';
import 'package:focusdeck/features/session/data/session_model.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';

class SessionPage extends ConsumerStatefulWidget {
  final String deckId;
  const SessionPage({super.key, required this.deckId});

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage>
    with TickerProviderStateMixin {
  static const int _plannedPomodoros = 4;
  final DateTime _startedAt = DateTime.now();
  bool _sessionSaved = false;
  int _activeCardIndex = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pomodoroProvider(_plannedPomodoros).notifier).reset();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop(TimerState timerState, Deck deck) async {
    if (!timerState.running && timerState.pomodorosCompleted == 0) {
      return true;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End session?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          timerState.pomodorosCompleted > 0
              ? 'You\'ve completed ${timerState.pomodorosCompleted} pomodoro${timerState.pomodorosCompleted != 1 ? 's' : ''}. Save progress?'
              : 'Session will be discarded.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Stay'),
          ),
          if (timerState.pomodorosCompleted > 0)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('Save & exit'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveSession(timerState, deck, SessionStatus.abandoned);
      return true;
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  Future<void> _saveSession(
      TimerState timerState, Deck deck, SessionStatus status) async {
    if (_sessionSaved) return;
    _sessionSaved = true;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref.read(sessionServiceProvider).saveSession(
            uid: user.uid,
            deckId: deck.id,
            deckTitle: deck.title,
            cardTitles: deck.cards.map((c) => c.title).toList(),
            plannedPomodoros: _plannedPomodoros,
            completedPomodoros: timerState.pomodorosCompleted,
            status: status,
            startedAt: _startedAt,
          );
      await ref.read(deckServiceProvider).incrementSessionCount(deck.id);
    } catch (_) {}
  }

  String _phaseLabel(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.focus:
        return 'FOCUS';
      case TimerPhase.shortBreak:
        return 'SHORT BREAK';
      case TimerPhase.longBreak:
        return 'LONG BREAK';
    }
  }

  Color _phaseColor(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.focus:
        return AppColors.accent;
      case TimerPhase.shortBreak:
        return AppColors.success;
      case TimerPhase.longBreak:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync =
        ref.watch(deckByIdProvider(widget.deckId));
    final timerState =
        ref.watch(pomodoroProvider(_plannedPomodoros));
    final timerNotifier =
        ref.read(pomodoroProvider(_plannedPomodoros).notifier);

    return deckAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 2)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e')),
      ),
      data: (deck) {
        if (deck == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: Text('Deck not found')),
          );
        }

        // Handle session finished
        if (timerState.finished && !_sessionSaved) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _saveSession(timerState, deck, SessionStatus.completed);
            if (mounted) _showCompletionSheet(timerState, deck);
          });
        }

        final phaseColor = _phaseColor(timerState.phase);
        final colorIndex =
            deck.colorIndex % AppColors.cardColors.length;
        final accentColor = AppColors.cardAccents[colorIndex];

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final shouldPop = await _onWillPop(timerState, deck);
            if (shouldPop && mounted) {
              context.pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            timerNotifier.pause();
                            final shouldPop =
                                await _onWillPop(timerState, deck);
                            if (shouldPop && mounted) context.pop();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.textSecondary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            deck.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Pomodoro dots
                        Row(
                          children: List.generate(
                            _plannedPomodoros,
                            (i) => Container(
                              margin: const EdgeInsets.only(left: 5),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i < timerState.pomodorosCompleted
                                    ? AppColors.accent
                                    : AppColors.border,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 36),

                            // Phase label
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey(timerState.phase),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: phaseColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: phaseColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _phaseLabel(timerState.phase),
                                  style: TextStyle(
                                    color: phaseColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(),

                            const SizedBox(height: 36),

                            // Timer ring
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final glowOpacity = timerState.running
                                    ? 0.05 +
                                        (_pulseController.value * 0.08)
                                    : 0.0;
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: phaseColor
                                            .withOpacity(glowOpacity),
                                        blurRadius: 40,
                                        spreadRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                );
                              },
                              child: CircularPercentIndicator(
                                radius: 110,
                                lineWidth: 6,
                                percent: timerState.progress
                                    .clamp(0.0, 1.0),
                                backgroundColor: AppColors.border,
                                progressColor: phaseColor,
                                circularStrokeCap:
                                    CircularStrokeCap.round,
                                center: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (timerState.running) {
                                      timerNotifier.pause();
                                    } else {
                                      timerNotifier.start();
                                    }
                                  },
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        child: Text(
                                          '${timerState.minutesLeft.toString().padLeft(2, '0')}:${timerState.secondsLeft.toString().padLeft(2, '0')}',
                                          key: ValueKey(timerState
                                              .remainingSeconds),
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge
                                              ?.copyWith(
                                                fontSize: 46,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                                letterSpacing: -2,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        child: Icon(
                                          timerState.running
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          key: ValueKey(timerState.running),
                                          color:
                                              AppColors.textSecondary,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate(delay: 100.ms).fadeIn().scale(
                                begin: const Offset(0.9, 0.9)),

                            const SizedBox(height: 28),

                            // Skip button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                timerNotifier.skipPhase();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.skip_next_rounded,
                                      color: AppColors.textMuted, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Skip phase',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(delay: 200.ms).fadeIn(),

                            const SizedBox(height: 36),

                            // Focus cards section
                            if (deck.cards.isNotEmpty) ...[
                              Row(
                                children: [
                                  Text(
                                    'YOUR INTENTION',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                ],
                              ).animate(delay: 250.ms).fadeIn(),
                              const SizedBox(height: 12),

                              // Card pager
                              SizedBox(
                                height: 130,
                                child: PageView.builder(
                                  itemCount: deck.cards.length,
                                  onPageChanged: (i) =>
                                      setState(() => _activeCardIndex = i),
                                  itemBuilder: (ctx, i) {
                                    final card = deck.cards[i];
                                    return _FocusCardDisplay(
                                      card: card,
                                      index: i,
                                      accentColor: accentColor,
                                      bgColor: AppColors.cardColors[colorIndex],
                                    );
                                  },
                                ),
                              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

                              if (deck.cards.length > 1) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    deck.cards.length,
                                    (i) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin:
                                          const EdgeInsets.only(right: 5),
                                      width:
                                          _activeCardIndex == i ? 16 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _activeCardIndex == i
                                            ? accentColor
                                            : AppColors.border,
                                        borderRadius:
                                            BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCompletionSheet(TimerState timerState, Deck deck) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accentDim,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.accent, size: 30),
            )
                .animate()
                .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut),

            const SizedBox(height: 20),

            Text(
              'Session complete',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 8),

            Text(
              '${timerState.pomodorosCompleted} pomodoro${timerState.pomodorosCompleted != 1 ? 's' : ''} · ${timerState.pomodorosCompleted * 25} minutes of focus',
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate(delay: 150.ms).fadeIn(),

            const SizedBox(height: 8),

            Text(
              deck.title,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/home');
                },
                child: const Text('Back to home'),
              ),
            ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _sessionSaved = false);
                  ref
                      .read(pomodoroProvider(_plannedPomodoros).notifier)
                      .reset();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start another session'),
              ),
            ).animate(delay: 300.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _FocusCardDisplay extends StatelessWidget {
  final FocusCard card;
  final int index;
  final Color accentColor;
  final Color bgColor;

  const _FocusCardDisplay({
    required this.card,
    required this.index,
    required this.accentColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CARD ${index + 1}',
                style: TextStyle(
                  color: accentColor.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (card.note != null && card.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card.note!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
