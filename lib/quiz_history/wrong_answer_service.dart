import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WrongAnswer {
  final String question;
  final String correctAnswer;
  final String userAnswer;
  final String category;
  final int timestamp;
  int correctCount;

  WrongAnswer({
    required this.question,
    required this.correctAnswer,
    required this.userAnswer,
    required this.category,
    required this.timestamp,
    this.correctCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'correctAnswer': correctAnswer,
    'userAnswer': userAnswer,
    'category': category,
    'timestamp': timestamp,
    'correctCount': correctCount,
  };

  factory WrongAnswer.fromJson(Map<String, dynamic> json) => WrongAnswer(
    question: json['question'],
    correctAnswer: json['correctAnswer'],
    userAnswer: json['userAnswer'],
    category: json['category'],
    timestamp: json['timestamp'],
    correctCount: json['correctCount'] ?? 0,
  );
}

class WrongAnswerService {
  static const String _storageKey = 'wordsteps_wrong_answers';

  Future<void> saveWrongAnswer(WrongAnswer mistake) async {
    final prefs = await SharedPreferences.getInstance();
    List<WrongAnswer> currentMistakes = await getWrongAnswers();
    
    // Check if mistake already exists to avoid duplicates
    int index = currentMistakes.indexWhere((m) => m.question == mistake.question);
    if (index != -1) {
      currentMistakes[index].correctCount = 0; // Reset mastery if failed again
    } else {
      currentMistakes.add(mistake);
    }
    
    await _saveToPrefs(prefs, currentMistakes);
  }

  Future<void> updateMastery(String question, bool isCorrect) async {
    final prefs = await SharedPreferences.getInstance();
    List<WrongAnswer> mistakes = await getWrongAnswers();
    int index = mistakes.indexWhere((m) => m.question == question);

    if (index != -1) {
      if (isCorrect) {
        mistakes[index].correctCount++;
        if (mistakes[index].correctCount >= 3) {
          mistakes.removeAt(index); // Remove after 3 correct hits
        }
      } else {
        mistakes[index].correctCount = 0; // Reset streak
      }
      await _saveToPrefs(prefs, mistakes);
    }
  }

  Future<List<WrongAnswer>> getWrongAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_storageKey);
    if (data == null) return [];
    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => WrongAnswer.fromJson(j)).toList();
  }

  Future<void> _saveToPrefs(SharedPreferences prefs, List<WrongAnswer> list) async {
    String encoded = jsonEncode(list.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> deleteMistake(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<WrongAnswer> mistakes = await getWrongAnswers();
    mistakes.removeAt(index);
    await _saveToPrefs(prefs, mistakes);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}