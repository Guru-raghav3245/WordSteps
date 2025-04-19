class WordGameState {
  final String correctWord;
  final List<String> options;
  final List<String> answeredQuestions;
  final List<bool> answeredCorrectly;
  final List<String> userSelectedWords;
  final int startTime;
  final int elapsedTime;
  final int incorrectAttempts;
  final bool isPaused;

  WordGameState({
    required this.correctWord,
    required this.options,
    this.answeredQuestions = const [],
    this.answeredCorrectly = const [],
    this.userSelectedWords = const [],
    this.startTime = 0,
    this.elapsedTime = 0,
    this.incorrectAttempts = 0,
    this.isPaused = false,
  });

  WordGameState copyWith({
    String? correctWord,
    List<String>? options,
    List<String>? answeredQuestions,
    List<bool>? answeredCorrectly,
    List<String>? userSelectedWords,
    int? startTime,
    int? elapsedTime,
    int? incorrectAttempts,
    bool? isPaused,
  }) {
    return WordGameState(
      correctWord: correctWord ?? this.correctWord,
      options: options ?? this.options,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
      userSelectedWords: userSelectedWords ?? this.userSelectedWords,
      startTime: startTime ?? this.startTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}