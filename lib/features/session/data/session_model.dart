import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { completed, abandoned }

class Session {
  final String id;
  final String uid;
  final String deckId;
  final String deckTitle;
  final List<String> cardTitles;
  final int plannedPomodoros;
  final int completedPomodoros;
  final int focusMinutes;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  const Session({
    required this.id,
    required this.uid,
    required this.deckId,
    required this.deckTitle,
    required this.cardTitles,
    required this.plannedPomodoros,
    required this.completedPomodoros,
    required this.focusMinutes,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'deckId': deckId,
        'deckTitle': deckTitle,
        'cardTitles': cardTitles,
        'plannedPomodoros': plannedPomodoros,
        'completedPomodoros': completedPomodoros,
        'focusMinutes': focusMinutes,
        'status': status.name,
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as String,
        uid: map['uid'] as String,
        deckId: map['deckId'] as String,
        deckTitle: map['deckTitle'] as String,
        cardTitles: List<String>.from(map['cardTitles'] as List),
        plannedPomodoros: (map['plannedPomodoros'] as num).toInt(),
        completedPomodoros: (map['completedPomodoros'] as num).toInt(),
        focusMinutes: (map['focusMinutes'] as num).toInt(),
        status: SessionStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => SessionStatus.completed,
        ),
        startedAt: (map['startedAt'] as Timestamp).toDate(),
        endedAt: map['endedAt'] != null
            ? (map['endedAt'] as Timestamp).toDate()
            : null,
      );
}
