import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_words/english_words.dart';
import 'dart:math';
import 'package:word_app/models/word_game_state.dart';
import 'sentence_list.dart';

class WordGameService {
  List<String> _getSentencesFromList(String listType) {
    switch (listType) {
      case '7a':
        return EnglishSentences.kumon7aSentences;
      case '6a':
        return EnglishSentences.kumon6aSentences;
      case '5a':
        return EnglishSentences.kumon5aSentences;
      case '4a':
        return EnglishSentences.kumon4aSentences;
      case '3a':
        return EnglishSentences.kumon3aSentences;
      case '2a':
        return EnglishSentences.kumon2aSentences;
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
      case '10':
      case '11':
      case '12':
      case '13':
      case '14':
        return _getAllWordsOfLength(int.parse(listType));
      default:
        throw Exception('Invalid list type: $listType');
    }
  }

  List<String> _getAllWordsOfLength(int length) {
    return nouns.where((word) => word.length == length).toList();
  }

  WordGameState generateNewRound(
      WordGameState? previousState, String listType) {
    final allItems = _getSentencesFromList(listType);

    if (allItems.isEmpty) {
      throw Exception('No items found for type $listType');
    }

    print('List Type: $listType'); // Debug statement
    print('All Items: $allItems'); // Debug statement

    String correctItem = allItems[Random().nextInt(allItems.length)];
    List<String> options = _generateOptions(correctItem, allItems);

    return WordGameState(
      correctWord: correctItem,
      options: options,
      answeredQuestions: previousState?.answeredQuestions ?? [],
      answeredCorrectly: previousState?.answeredCorrectly ?? [],
      userSelectedWords: previousState?.userSelectedWords ?? [],
      startTime: previousState?.startTime ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  List<String> _generateOptions(String correctItem, List<String> allItems) {
    List<String> wrongItems =
        allItems.where((item) => item != correctItem).toList();
    wrongItems.shuffle();
    List<String> options = [correctItem, wrongItems[0], wrongItems[1]];
    options.shuffle();
    return options;
  }

  WordGameState handleAnswer(WordGameState currentState, String selectedItem) {
    bool isCorrect = selectedItem.toLowerCase().trim() ==
        currentState.correctWord.toLowerCase().trim();

    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int elapsedTime = currentTime - currentState.startTime;

    return currentState.copyWith(
      answeredQuestions: [
        ...currentState.answeredQuestions,
        currentState.correctWord
      ],
      answeredCorrectly: [...currentState.answeredCorrectly, isCorrect],
      userSelectedWords: [...currentState.userSelectedWords, selectedItem],
      elapsedTime: elapsedTime,
    );
  }
}

// Update the provider
final contentTypeProvider = StateProvider<String>((ref) => '3');

// Provider for the service
final wordLengthProvider = StateProvider<String>((ref) => '3');

// Provider for the service
final wordGameServiceProvider = Provider<WordGameService>((ref) {
  return WordGameService();
});

// Update the StateNotifierProvider to use String type
final wordGameStateProvider =
    StateNotifierProvider<WordGameStateNotifier, WordGameState>((ref) {
  final service = ref.read(wordGameServiceProvider);
  final listType = ref.watch(contentTypeProvider); // Ensure this is correct
  return WordGameStateNotifier(service, listType);
});

class WordGameStateNotifier extends StateNotifier<WordGameState> {
  final WordGameService _service;
  final String _listType; // Changed from int to String

  WordGameStateNotifier(this._service, this._listType)
      : super(WordGameState(correctWord: '', options: [])) {
    initializeGame();
  }

  void initializeGame() {
    state = _service.generateNewRound(null, _listType);
  }

  void generateNewRound() {
    state = _service.generateNewRound(state, _listType);
  }

  // Rest of the methods remain the same
  void handleAnswer(String selectedWord) {
    state = _service.handleAnswer(state, selectedWord);
    generateNewRound();
  }

  void quitGame() {
    state = WordGameState(
        correctWord: '',
        options: [],
        answeredQuestions: [],
        answeredCorrectly: [],
        userSelectedWords: []);
  }

  void clearGameState() {
    state = WordGameState(
      correctWord: '',
      options: [],
      answeredQuestions: [],
      answeredCorrectly: [],
      userSelectedWords: [],
      elapsedTime: 0,
    );
  }

  WordGameState getGameResults() {
    return state;
  }
}
