import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_words/english_words.dart';
import 'dart:math';
import '../screens/home_screen.dart';

class WordGameState {
  final String correctWord;
  final List<String> options;
  final List<String> answeredQuestions;
  final List<bool> answeredCorrectly;
  final List<String> userSelectedWords;
  final int startTime;
  final int elapsedTime;

  WordGameState({
    required this.correctWord,
    required this.options,
    this.answeredQuestions = const [],
    this.answeredCorrectly = const [],
    this.userSelectedWords = const [],
    int? startTime,
    this.elapsedTime = 0,
  }) : startTime = startTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  WordGameState copyWith({
    String? correctWord,
    List<String>? options,
    List<String>? answeredQuestions,
    List<bool>? answeredCorrectly,
    List<String>? userSelectedWords,
    int? startTime,
    int? elapsedTime,
  }) {
    return WordGameState(
      correctWord: correctWord ?? this.correctWord,
      options: options ?? this.options,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
      userSelectedWords: userSelectedWords ?? this.userSelectedWords,
      startTime: startTime ?? this.startTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }
}

class WordGameService {
  List<String> _getAllWordsOfLength(int length) {
    return nouns.where((word) => word.length == length).toList();
  }

  WordGameState generateNewRound(WordGameState? previousState, int wordLength) {
    final allWords = _getAllWordsOfLength(wordLength);

    if (allWords.isEmpty) {
      throw Exception('No words found for length $wordLength');
    }

    String correctWord = allWords[Random().nextInt(allWords.length)];
    List<String> options = _generateOptions(correctWord, allWords);

    return WordGameState(
      correctWord: correctWord,
      options: options,
      answeredQuestions: previousState?.answeredQuestions ?? [],
      answeredCorrectly: previousState?.answeredCorrectly ?? [],
      userSelectedWords: previousState?.userSelectedWords ?? [],
      startTime: previousState?.startTime,
    );
  }

  WordGameState handleAnswer(WordGameState currentState, String selectedWord) {
    bool isCorrect = selectedWord == currentState.correctWord;

    // Calculate elapsed time
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int elapsedTime = currentTime - currentState.startTime;

    return currentState.copyWith(
      answeredQuestions: [
        ...currentState.answeredQuestions,
        currentState.correctWord
      ],
      answeredCorrectly: [...currentState.answeredCorrectly, isCorrect],
      userSelectedWords: [...currentState.userSelectedWords, selectedWord],
      elapsedTime: elapsedTime,
    );
  }

  List<String> _generateOptions(String correctWord, List<String> allWords) {
    List<String> wrongWords =
        allWords.where((word) => word != correctWord).toList();
    wrongWords.shuffle();
    List<String> options = [correctWord, wrongWords[0], wrongWords[1]];
    options.shuffle();
    return options;
  }
}

// Riverpod Provider for WordGameService
final wordGameServiceProvider = Provider<WordGameService>((ref) {
  return WordGameService();
});

// Riverpod StateNotifierProvider for WordGameState
final wordGameStateProvider =
    StateNotifierProvider<WordGameStateNotifier, WordGameState>((ref) {
  final service = ref.read(wordGameServiceProvider);
  final wordLength = ref.watch(wordLengthProvider);
  return WordGameStateNotifier(service, wordLength);
});

class WordGameStateNotifier extends StateNotifier<WordGameState> {
  final WordGameService _service;
  final int _wordLength;

  WordGameStateNotifier(this._service, this._wordLength)
      : super(WordGameState(correctWord: '', options: [])) {
    initializeGame();
  }

  void initializeGame() {
    state = _service.generateNewRound(null, _wordLength);
  }

  void generateNewRound() {
    state = _service.generateNewRound(state, _wordLength);
  }

  void handleAnswer(String selectedWord) {
    state = _service.handleAnswer(state, selectedWord);
    generateNewRound();
  }

  void quitGame() {
    // Reset the game state completely
    state = WordGameState(
        correctWord: '',
        options: [],
        answeredQuestions: [],
        answeredCorrectly: [],
        userSelectedWords: []);
  }

  WordGameState getGameResults() {
    return state;
  }
}
