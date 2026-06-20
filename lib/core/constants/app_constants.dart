class AppConstants {
  // Firestore collections
  static const usersCollection = 'users';
  static const decksCollection = 'decks';
  static const sessionsCollection = 'sessions';
  static const cardsCollection = 'cards';

  // Pomodoro defaults
  static const defaultFocusMinutes = 25;
  static const defaultShortBreakMinutes = 5;
  static const defaultLongBreakMinutes = 15;
  static const sessionsBeforeLongBreak = 4;

  // Card limits
  static const maxCardsPerDeck = 3;
  static const maxDeckTitleLength = 40;
  static const maxCardTitleLength = 60;
  static const maxCardNoteLength = 120;
}
