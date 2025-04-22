import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:english_words/english_words.dart';
import 'dart:math';
import 'package:word_app/models/word_game_state.dart';
import 'package:word_app/questions/content_type.dart';
import 'sentence_list.dart';
import 'package:string_similarity/string_similarity.dart';

class WordGameService {
  List<String> _getSentencesFromList(ContentType contentType) {
    switch (contentType) {
      case ContentType.kumon7a:
        return EnglishSentences.kumon7aSentences;
      case ContentType.kumon6a:
        return EnglishSentences.kumon6aSentences;
      case ContentType.kumon5a:
        return EnglishSentences.kumon5aSentences;
      case ContentType.kumon4a:
        return EnglishSentences.kumon4aSentences;
      case ContentType.kumon3a:
        return EnglishSentences.kumon3aSentences;
      case ContentType.kumon2a:
        return EnglishSentences.kumon2aSentences;
      case ContentType.wordLength3:
        return _getAllWordsOfLength(3);
      case ContentType.wordLength4:
        return _getAllWordsOfLength(4);
      case ContentType.wordLength5:
        return _getAllWordsOfLength(5);
      case ContentType.wordLength6:
        return _getAllWordsOfLength(6);
      case ContentType.wordLength7:
        return _getAllWordsOfLength(7);
      case ContentType.wordLength8:
        return _getAllWordsOfLength(8);
      case ContentType.wordLength9:
        return _getAllWordsOfLength(9);
      case ContentType.wordLength10:
        return _getAllWordsOfLength(10);
      case ContentType.wordLength11:
        return _getAllWordsOfLength(11);
      case ContentType.wordLength12:
        return _getAllWordsOfLength(12);
      case ContentType.wordLength13:
        return _getAllWordsOfLength(13);
      case ContentType.wordLength14:
        return _getAllWordsOfLength(14);
    }
  }

  List<String> _getAllWordsOfLength(int length) {
    return nouns.where((word) => word.length == length).toList();
  }

  WordGameState generateNewRound(
      WordGameState? previousState, ContentType contentType) {
    final allItems = _getSentencesFromList(contentType);

    if (allItems.isEmpty) {
      throw Exception('No items found for type $contentType');
    }

    print('Generating new round with Content Type: $contentType'); // Debug
    print('All Items: $allItems'); // Debug

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
      elapsedTime: previousState?.elapsedTime ?? 0,
      incorrectAttempts: 0,
      isPaused: previousState?.isPaused ?? false,
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

  WordGameState handleAnswer(WordGameState currentState, String selectedItem,
      ContentType contentType) {
    // Normalize both strings: remove punctuation, extra spaces, and convert to lowercase
    String normalizedSelected = selectedItem
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(
            RegExp(r'\s+'), ' ') // Normalize multiple spaces to single space
        .trim();
    String normalizedCorrect = currentState.correctWord
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    bool isCorrect = normalizedSelected == normalizedCorrect;

    // Optional: Use string similarity if exact match fails (e.g., for minor typos)
    if (!isCorrect && normalizedSelected.isNotEmpty) {
      double similarity = normalizedSelected.similarityTo(normalizedCorrect);
      if (similarity > 0.9) {
        // Threshold for similarity (adjust as needed)
        isCorrect = true;
      }
    }

    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int elapsedTime = currentTime - currentState.startTime;

    print(
        'Handling answer: $selectedItem, Normalized: $normalizedSelected, Correct: $normalizedCorrect, IsCorrect: $isCorrect, Attempts: ${currentState.incorrectAttempts}'); // Debug

    if (isCorrect) {
      print('Correct answer, resetting attempts'); // Debug
      return currentState.copyWith(
        answeredQuestions: [
          ...currentState.answeredQuestions,
          currentState.correctWord
        ],
        answeredCorrectly: [...currentState.answeredCorrectly, true],
        userSelectedWords: [...currentState.userSelectedWords, selectedItem],
        elapsedTime: elapsedTime,
        incorrectAttempts: 0,
      );
    } else {
      final newAttempts = currentState.incorrectAttempts + 1;
      print('Incorrect answer, new attempts: $newAttempts'); // Debug
      if (newAttempts >= 3) {
        print('Regenerating word after 3 incorrect attempts'); // Debug
        final allItems = _getSentencesFromList(contentType);
        String newCorrectItem = allItems[Random().nextInt(allItems.length)];
        List<String> newOptions = _generateOptions(newCorrectItem, allItems);
        return currentState.copyWith(
          correctWord: newCorrectItem,
          options: newOptions,
          incorrectAttempts: 0,
          elapsedTime: elapsedTime,
        );
      } else {
        return currentState.copyWith(
          incorrectAttempts: newAttempts,
          elapsedTime: elapsedTime,
        );
      }
    }
  }
}

final contentTypeProvider =
    StateProvider<ContentType>((ref) => ContentType.wordLength3);

final wordLengthProvider = StateProvider<String>((ref) => '3');

final wordGameServiceProvider = Provider<WordGameService>((ref) {
  return WordGameService();
});

final wordGameStateProvider =
    StateNotifierProvider<WordGameStateNotifier, WordGameState>((ref) {
  final service = ref.read(wordGameServiceProvider);
  final contentType = ref.watch(contentTypeProvider);
  return WordGameStateNotifier(service, contentType);
});

class WordGameStateNotifier extends StateNotifier<WordGameState> {
  final WordGameService _service;
  final ContentType _contentType;

  WordGameStateNotifier(this._service, this._contentType)
      : super(WordGameState(correctWord: '', options: [])) {
    initializeGame();
  }

  void initializeGame() {
    state = _service.generateNewRound(null, _contentType);
  }

  void generateNewRound() {
    state = _service.generateNewRound(state, _contentType);
  }

  void handleAnswer(String selectedWord) {
    state = _service.handleAnswer(state, selectedWord, _contentType);
    if (state.answeredCorrectly.isNotEmpty &&
        state.answeredCorrectly.last == true) {
      generateNewRound();
    }
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void quitGame() {
    state = WordGameState(
      correctWord: '',
      options: [],
      answeredQuestions: [],
      answeredCorrectly: [],
      userSelectedWords: [],
      incorrectAttempts: 0,
      isPaused: false,
    );
  }

  void clearGameState() {
    state = WordGameState(
      correctWord: '',
      options: [],
      answeredQuestions: [],
      answeredCorrectly: [],
      userSelectedWords: [],
      elapsedTime: 0,
      incorrectAttempts: 0,
      isPaused: false,
    );
  }

  WordGameState getGameResults() {
    return state;
  }
}
