import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:english_words/english_words.dart';
import 'dart:math';
import 'package:word_app/models/word_game_state.dart';
import 'package:word_app/questions/content_type.dart';
import 'sentence_list.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:word_app/quiz_history/wrong_answer_service.dart';

class WordGameService {
  final WrongAnswerService _wrongAnswerService = WrongAnswerService();

  final List<String> _bannedWords = [
    'sex', 'ass', 'damn', 'hell', 'crap', 'bastard', 
    'dumb', 'stupid', 'idiot', 'piss', 'shit', 'fuck'
  ];

  // ==================== WRONG ANSWER PRIORITIZATION (from Math app) ====================
  List<WrongAnswer> _pendingWrongAnswers = [];
  List<String> _wrongQuestionsToShowThisSession = [];
  List<String> _shownWrongQuestionsThisSession = [];
  bool _currentIsWAQ = false;

  Future<void> loadPendingWrongAnswers(ContentType contentType) async {
    final allMistakes = await _wrongAnswerService.getWrongAnswers();
    _pendingWrongAnswers = [];
    _wrongQuestionsToShowThisSession = [];
    final currentCategory = contentType.toString().split('.').last;

    for (var mistake in allMistakes) {
      if (mistake.category == currentCategory) {
        _pendingWrongAnswers.add(mistake);
        _wrongQuestionsToShowThisSession.add(mistake.question);
      }
    }
    _shownWrongQuestionsThisSession.clear();
    _currentIsWAQ = false;
  }

  void resetSessionWrongAnswers() {
    _pendingWrongAnswers.clear();
    _wrongQuestionsToShowThisSession.clear();
    _shownWrongQuestionsThisSession.clear();
    _currentIsWAQ = false;
  }

  String _pickNextCorrectItem(List<String> allItems, ContentType contentType) {
    if (_wrongQuestionsToShowThisSession.isNotEmpty) {
      final nextWAQ = _wrongQuestionsToShowThisSession.firstWhere(
        (q) => !_shownWrongQuestionsThisSession.contains(q),
        orElse: () => '',
      );
      if (nextWAQ.isNotEmpty) {
        _shownWrongQuestionsThisSession.add(nextWAQ);
        _currentIsWAQ = true;
        return nextWAQ;
      }
    }
    _currentIsWAQ = false;
    return allItems[Random().nextInt(allItems.length)];
  }
  // ====================================================================================

  List<String> _filterBannedWords(List<String> words) {
    return words
        .where((word) => !_bannedWords.contains(word.toLowerCase()))
        .toList();
  }

  List<String> _getSentencesFromList(ContentType contentType) {
    switch (contentType) {
      case ContentType.kumon7a: return EnglishSentences.kumon7aSentences;
      case ContentType.kumon6a: return EnglishSentences.kumon6aSentences;
      case ContentType.kumon5a: return EnglishSentences.kumon5aSentences;
      case ContentType.kumon4a: return EnglishSentences.kumon4aSentences;
      case ContentType.kumon3a: return EnglishSentences.kumon3aSentences;
      case ContentType.kumon2a: return EnglishSentences.kumon2aSentences;
      case ContentType.wordLength3: return _getAllWordsOfLength(3);
      case ContentType.wordLength4: return _getAllWordsOfLength(4);
      case ContentType.wordLength5: return _getAllWordsOfLength(5);
      case ContentType.wordLength6: return _getAllWordsOfLength(6);
      case ContentType.wordLength7: return _getAllWordsOfLength(7);
      case ContentType.wordLength8: return _getAllWordsOfLength(8);
      case ContentType.wordLength9: return _getAllWordsOfLength(9);
      case ContentType.wordLength10: return _getAllWordsOfLength(10);
      case ContentType.wordLength11: return _getAllWordsOfLength(11);
      case ContentType.wordLength12: return _getAllWordsOfLength(12);
      case ContentType.wordLength13: return _getAllWordsOfLength(13);
      case ContentType.wordLength14: return _getAllWordsOfLength(14);
    }
  }

  List<String> _getAllWordsOfLength(int length) {
    return _filterBannedWords(
        nouns.where((word) => word.length == length).toList());
  }

  WordGameState generateNewRound(WordGameState? previousState, ContentType contentType) {
    final allItems = _getSentencesFromList(contentType);
    if (allItems.isEmpty) throw Exception('No items found for type $contentType');

    final correctItem = _pickNextCorrectItem(allItems, contentType);
    final options = _generateOptions(correctItem, allItems);

    return WordGameState(
      correctWord: correctItem,
      options: options,
      answeredQuestions: previousState?.answeredQuestions ?? [],
      answeredCorrectly: previousState?.answeredCorrectly ?? [],
      userSelectedWords: previousState?.userSelectedWords ?? [],
      startTime: previousState?.startTime ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      elapsedTime: previousState?.elapsedTime ?? 0,
      incorrectAttempts: 0,
      isPaused: previousState?.isPaused ?? false,
      isWAQ: _currentIsWAQ,
    );
  }

  List<String> _generateOptions(String correctItem, List<String> allItems) {
    List<String> wrongItems = allItems.where((item) => item != correctItem).toList();
    wrongItems.shuffle();
    List<String> options = [correctItem, wrongItems[0], wrongItems[1]];
    options.shuffle();
    return options;
  }

  WordGameState handleAnswer(WordGameState currentState, String selectedItem, ContentType contentType) {
    String normalizedSelected = selectedItem.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    String normalizedCorrect = currentState.correctWord.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

    bool isCorrect = normalizedSelected == normalizedCorrect;
    if (!isCorrect && normalizedSelected.isNotEmpty) {
      double similarity = normalizedSelected.similarityTo(normalizedCorrect);
      if (similarity > 0.9) isCorrect = true;
    }

    if (!isCorrect) {
      _wrongAnswerService.saveWrongAnswer(WrongAnswer(
        question: currentState.correctWord,
        correctAnswer: currentState.correctWord,
        userAnswer: selectedItem,
        category: contentType.toString().split('.').last,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    } else {
      _wrongAnswerService.updateMastery(currentState.correctWord, true);
    }

    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int elapsedTime = currentTime - currentState.startTime;

    final allItems = _getSentencesFromList(contentType);
    final newCorrectItem = _pickNextCorrectItem(allItems, contentType);
    final newOptions = _generateOptions(newCorrectItem, allItems);

    return WordGameState(
      correctWord: newCorrectItem,
      options: newOptions,
      answeredQuestions: [...currentState.answeredQuestions, currentState.correctWord],
      answeredCorrectly: [...currentState.answeredCorrectly, isCorrect],
      userSelectedWords: [...currentState.userSelectedWords, selectedItem],
      startTime: currentState.startTime,
      elapsedTime: elapsedTime,
      incorrectAttempts: 0,
      isPaused: currentState.isPaused,
      isWAQ: _currentIsWAQ,
    );
  }
}

final contentTypeProvider = StateProvider<ContentType>((ref) => ContentType.wordLength3);
final wordGameServiceProvider = Provider<WordGameService>((ref) => WordGameService());

final wordGameStateProvider = StateNotifierProvider<WordGameStateNotifier, WordGameState>((ref) {
  final service = ref.read(wordGameServiceProvider);
  final contentType = ref.watch(contentTypeProvider);
  return WordGameStateNotifier(service, contentType);
});

class WordGameStateNotifier extends StateNotifier<WordGameState> {
  final WordGameService _service;
  final ContentType _contentType;

  WordGameStateNotifier(this._service, this._contentType) : super(WordGameState(correctWord: '', options: []));

  Future<void> initializeGame() async {
    await _service.loadPendingWrongAnswers(_contentType);
    state = _service.generateNewRound(null, _contentType);
  }

  void generateNewRound() {
    state = _service.generateNewRound(state, _contentType);
  }

  void handleAnswer(String selectedWord) {
    state = _service.handleAnswer(state, selectedWord, _contentType);
  }

  void togglePause() => state = state.copyWith(isPaused: !state.isPaused);

  void quitGame() {
    _service.resetSessionWrongAnswers();
    state = WordGameState(correctWord: '', options: []);
  }

  void clearGameState() {
    _service.resetSessionWrongAnswers();
    state = WordGameState(correctWord: '', options: [], elapsedTime: 0);
  }
}