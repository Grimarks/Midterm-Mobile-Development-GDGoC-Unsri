import 'package:cloud_firestore/cloud_firestore.dart';

class FocusCard {
  final String id;
  final String title;
  final String? note;

  const FocusCard({
    required this.id,
    required this.title,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'note': note,
      };

  factory FocusCard.fromMap(Map<String, dynamic> map) => FocusCard(
        id: map['id'] as String,
        title: map['title'] as String,
        note: map['note'] as String?,
      );

  FocusCard copyWith({String? id, String? title, String? note}) => FocusCard(
        id: id ?? this.id,
        title: title ?? this.title,
        note: note ?? this.note,
      );
}

class Deck {
  final String id;
  final String uid;
  final String title;
  final List<FocusCard> cards;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sessionCount;

  const Deck({
    required this.id,
    required this.uid,
    required this.title,
    required this.cards,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
    this.sessionCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'title': title,
        'cards': cards.map((c) => c.toMap()).toList(),
        'colorIndex': colorIndex,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'sessionCount': sessionCount,
      };

  factory Deck.fromMap(Map<String, dynamic> map) => Deck(
        id: map['id'] as String,
        uid: map['uid'] as String,
        title: map['title'] as String,
        cards: (map['cards'] as List<dynamic>)
            .map((c) => FocusCard.fromMap(c as Map<String, dynamic>))
            .toList(),
        colorIndex: (map['colorIndex'] as num?)?.toInt() ?? 0,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        sessionCount: (map['sessionCount'] as num?)?.toInt() ?? 0,
      );

  Deck copyWith({
    String? title,
    List<FocusCard>? cards,
    int? colorIndex,
    int? sessionCount,
  }) =>
      Deck(
        id: id,
        uid: uid,
        title: title ?? this.title,
        cards: cards ?? this.cards,
        colorIndex: colorIndex ?? this.colorIndex,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        sessionCount: sessionCount ?? this.sessionCount,
      );
}
