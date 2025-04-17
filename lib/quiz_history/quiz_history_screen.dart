import 'package:flutter/material.dart';
import 'package:word_app/quiz_history/quiz_history_service.dart';
import 'package:word_app/screens/result_screen/result_screen.dart';

class QuizHistoryScreen extends StatefulWidget {
  final Function switchToStartScreen;

  const QuizHistoryScreen(this.switchToStartScreen, {super.key});

  @override
  _QuizHistoryScreenState createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });
    final quizzes = await QuizHistoryService.getQuizzes();
    setState(() {
      _quizzes = quizzes
        ..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      _isLoading = false;
    });
  }

  Future<void> _removeQuiz(String title) async {
    final quizToRemove = _quizzes.firstWhere((q) => q['title'] == title);
    setState(() {
      _quizzes.removeWhere((q) => q['title'] == title);
    });
    try {
      await QuizHistoryService.removeQuiz(title);
    } catch (e) {
      setState(() {
        _quizzes.add(quizToRemove);
        _quizzes.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove quiz: $e')),
      );
    }
  }

  Future<void> _clearAllQuizzes() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Quiz History'),
        content: const Text(
            'Are you sure you want to clear all quiz history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await QuizHistoryService.clearQuizzes();
        setState(() {
          _quizzes.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz history cleared')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear history: $e')),
        );
      }
    }
  }

  Future<void> _renameQuiz(String oldTitle) async {
    final controller = TextEditingController(text: oldTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Quiz'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Title',
            hintText: 'Enter a new title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != oldTitle) {
      try {
        await QuizHistoryService.renameQuiz(oldTitle, newTitle);
        setState(() {
          final quiz = _quizzes.firstWhere((q) => q['title'] == oldTitle);
          quiz['title'] = newTitle;
          _quizzes.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz renamed successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename quiz: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz History'),
        actions: [
          if (!_isLoading && _quizzes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all quizzes',
              onPressed: _clearAllQuizzes,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text('No quiz history yet!',
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Complete a quiz to save it here',
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _quizzes.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    return Dismissible(
                      key: ValueKey(quiz['title']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _removeQuiz(quiz['title']),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            quiz['title'],
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Score: ${quiz['correctCount']}/${quiz['totalQuestions']} | Time: ${(quiz['totalTime'] ~/ 60)}:${(quiz['totalTime'] % 60).toString().padLeft(2, '0')}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _renameQuiz(quiz['title']),
                            tooltip: 'Rename quiz',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  shouldSave: false,
                                  answeredQuestions:
                                      List<String>.from(quiz['questions']),
                                  answeredCorrectly:
                                      List<bool>.from(quiz['correctness']),
                                  totalTime: quiz['totalTime'],
                                  userSelectedWords: List<String>.from(
                                      quiz['userSelectedWords']),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
