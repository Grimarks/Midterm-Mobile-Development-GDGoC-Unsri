import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:focusdeck/features/deck/data/deck_model.dart';
import 'package:focusdeck/features/auth/providers/auth_provider.dart';

const _uuid = Uuid();

final deckServiceProvider = Provider<DeckService>((ref) {
  return DeckService(firestore: FirebaseFirestore.instance);
});

final userDecksProvider = StreamProvider<List<Deck>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.read(deckServiceProvider).watchUserDecks(user.uid);
});

final deckByIdProvider = FutureProvider.family<Deck?, String>((ref, deckId) async {
  return ref.read(deckServiceProvider).getDeck(deckId);
});

class DeckService {
  final FirebaseFirestore _firestore;

  DeckService({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference get _decks => _firestore.collection('decks');

  Stream<List<Deck>> watchUserDecks(String uid) {
    return _decks
        .where('uid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Deck.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<Deck?> getDeck(String deckId) async {
    final doc = await _decks.doc(deckId).get();
    if (!doc.exists) return null;
    return Deck.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<Deck> createDeck({
    required String uid,
    required String title,
    required List<FocusCard> cards,
    required int colorIndex,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final deck = Deck(
      id: id,
      uid: uid,
      title: title,
      cards: cards,
      colorIndex: colorIndex,
      createdAt: now,
      updatedAt: now,
    );
    await _decks.doc(id).set(deck.toMap());
    return deck;
  }

  Future<void> updateDeck(Deck deck) async {
    await _decks.doc(deck.id).update({
      'title': deck.title,
      'cards': deck.cards.map((c) => c.toMap()).toList(),
      'colorIndex': deck.colorIndex,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteDeck(String deckId) async {
    await _decks.doc(deckId).delete();
  }

  Future<void> incrementSessionCount(String deckId) async {
    await _decks.doc(deckId).update({
      'sessionCount': FieldValue.increment(1),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
