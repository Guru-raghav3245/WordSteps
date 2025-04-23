import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_app/questions/content_type.dart';

class QuizHistoryService {
  static const String _key = 'word_game_quiz_history';

  // Helper method to capitalize game mode
  static String _capitalizeGameMode(String gameMode) {
    return gameMode
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static Future<void> saveQuiz({
    required String title,
    required String timestamp,
    required ContentType contentType,
    required String gameMode,
    required int totalTime,
    required List<String> answeredQuestions,
    required List<bool> answeredCorrectly,
    required List<String> userSelectedWords,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> existingQuizzes = prefs.getStringList(_key) ?? [];

    Map<String, dynamic> quizData = {
      'title': title,
      'timestamp': timestamp,
      'contentType': contentType.name,
      'gameMode': gameMode,
      'totalTime': totalTime,
      'questions': answeredQuestions,
      'correctness': answeredCorrectly,
      'userSelectedWords': userSelectedWords,
      'correctCount': answeredCorrectly.where((c) => c).length,
      'totalQuestions': answeredQuestions.length,
    };

    existingQuizzes.add(jsonEncode(quizData));
    await prefs.setStringList(_key, existingQuizzes);
  }

  static Future<List<Map<String, dynamic>>> getQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> storedQuizzes = prefs.getStringList(_key) ?? [];
    return storedQuizzes.map((string) {
      final quizData = jsonDecode(string) as Map<String, dynamic>;
      quizData['contentType'] = ContentType.fromName(quizData['contentType']);
      return quizData;
    }).toList();
  }

  static Future<void> removeQuiz(String title) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> storedQuizzes = prefs.getStringList(_key) ?? [];
    storedQuizzes.removeWhere((quiz) {
      final quizData = jsonDecode(quiz) as Map<String, dynamic>;
      return quizData['title'] == title;
    });
    await prefs.setStringList(_key, storedQuizzes);
  }

  static Future<void> clearQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<String> generateUniqueTitle(String baseTitle) async {
    final quizzes = await getQuizzes();
    String newTitle = baseTitle;
    int suffix = 2;

    while (quizzes.any((quiz) => quiz['title'] == newTitle)) {
      newTitle = '$baseTitle #$suffix';
      suffix++;
    }
    return newTitle;
  }

  static Future<void> renameQuiz(String oldTitle, String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> storedQuizzes = prefs.getStringList(_key) ?? [];
    final quizzes = storedQuizzes
        .map((string) => jsonDecode(string) as Map<String, dynamic>)
        .toList();

    // Ensure the new title is valid
    if (newTitle.isEmpty || newTitle.length > 100) {
      throw Exception('Title must be between 1 and 100 characters.');
    }

    String uniqueNewTitle = newTitle;
    int suffix = 2;
    while (quizzes.any((quiz) =>
        quiz['title'] == uniqueNewTitle && quiz['title'] != oldTitle)) {
      uniqueNewTitle = '$newTitle #$suffix';
      suffix++;
    }

    for (int i = 0; i < storedQuizzes.length; i++) {
      Map<String, dynamic> quizData = jsonDecode(storedQuizzes[i]);
      if (quizData['title'] == oldTitle) {
        quizData['title'] = uniqueNewTitle;
        storedQuizzes[i] = jsonEncode(quizData);
        break;
      }
    }
    await prefs.setStringList(_key, storedQuizzes);
  }

  // Modified to generate human-friendly titles
  static String generateBaseTitle(ContentType contentType, String gameMode) {
    final contentDisplayName = contentType.displayName;
    final formattedGameMode = _capitalizeGameMode(gameMode);
    return '$contentDisplayName $formattedGameMode Quiz';
  }
}