class WordGameState {
  final String correctWord;
  final List<String> options;
  final List<String> answeredQuestions;
  final List<bool> answeredCorrectly;
  final List<String> userSelectedWords;
  final int startTime;
  final int elapsedTime;
  final bool isPaused; // Add the pause state here

  WordGameState({
    required this.correctWord,
    required this.options,
    this.answeredQuestions = const [],
    this.answeredCorrectly = const [],
    this.userSelectedWords = const [],
    int? startTime,
    this.elapsedTime = 0,
    this.isPaused = false, // Default to not paused
  }) : startTime = startTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  WordGameState copyWith({
    String? correctWord,
    List<String>? options,
    List<String>? answeredQuestions,
    List<bool>? answeredCorrectly,
    List<String>? userSelectedWords,
    int? startTime,
    int? elapsedTime,
    bool? isPaused, // Add the isPaused argument here
  }) {
    return WordGameState(
      correctWord: correctWord ?? this.correctWord,
      options: options ?? this.options, 
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
      userSelectedWords: userSelectedWords ?? this.userSelectedWords,
      startTime: startTime ?? this.startTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isPaused: isPaused ?? this.isPaused, // Use the passed value or retain the current one
    );
  }
}
