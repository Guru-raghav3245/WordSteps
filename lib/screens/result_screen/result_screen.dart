// lib/screens/result_screen/result_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/questions/word_generator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:word_app/quiz_history/quiz_history_service.dart';
import 'pdf_generator.dart';
import 'package:intl/intl.dart';
import 'package:word_app/screens/home_screen/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final List<String> answeredQuestions;
  final List<bool> answeredCorrectly;
  final int totalTime;
  final List<String> userSelectedWords;
  final bool shouldSave;

  const ResultScreen({
    required this.answeredQuestions,
    required this.answeredCorrectly,
    required this.totalTime,
    required this.userSelectedWords,
    this.shouldSave = true,
    super.key,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  // ignore: unused_field
  String? _quizTitle;

  @override
  void initState() {
    super.initState();
    if (widget.shouldSave) {
      _saveQuizWithTitle();
    }
  }

  Future<void> _saveQuizWithTitle() async {
    final now = DateTime.now();
    final baseTitle = DateFormat('dd-MM-yyyy').format(now);
    final uniqueTitle = await QuizHistoryService.generateUniqueTitle(baseTitle);

    if (!mounted) return;

    final titleController = TextEditingController(text: uniqueTitle);

    final newTitle = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Save Quiz', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: "Enter quiz title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, titleController.text.trim().isEmpty ? uniqueTitle : titleController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && mounted) {
      setState(() => _quizTitle = newTitle);
      _saveQuiz(newTitle);
    }
  }

  Future<void> _saveQuiz(String title) async {
    try {
      final contentType = ref.read(contentTypeProvider);
      final gameMode = ref.read(gameModeProvider);
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      await QuizHistoryService.saveQuiz(
        title: title,
        timestamp: timestamp,
        contentType: contentType,
        gameMode: gameMode,
        totalTime: widget.totalTime,
        answeredQuestions: widget.answeredQuestions,
        answeredCorrectly: widget.answeredCorrectly,
        userSelectedWords: widget.userSelectedWords,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz saved as "$title"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _sharePDFReport() async {
    try {
      final file = await QuizPDFGenerator.generateQuizPDF(
        answeredQuestions: widget.answeredQuestions,
        userAnswers: widget.userSelectedWords,
        answeredCorrectly: widget.answeredCorrectly,
        totalTime: widget.totalTime,
      );
      await Share.shareXFiles([XFile(file.path)], subject: 'WordSteps Quiz Results');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int minutes = widget.totalTime ~/ 60;
    int seconds = widget.totalTime % 60;
    int totalQuestions = widget.answeredQuestions.length;
    int correctAnswers = widget.answeredCorrectly.where((c) => c).length;

    return WillPopScope(
      onWillPop: () async {
        ref.read(wordGameStateProvider.notifier).clearGameState();
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Quiz Results'), centerTitle: true),
        body: Column(
          children: [
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStat(Icons.timer, '$minutes:${seconds.toString().padLeft(2, '0')}', 'Time'),
                                _buildStat(Icons.question_answer, '$totalQuestions', 'Questions'),
                                _buildStat(Icons.check_circle, '$correctAnswers', 'Correct'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Question Review', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Natural-height list (no more fixed 45% height)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.answeredQuestions.length,
                      itemBuilder: (context, index) {
                        final isCorrect = widget.answeredCorrectly[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(isCorrect ? Icons.check : Icons.close, color: isCorrect ? Colors.green : Colors.red),
                            title: Text(widget.answeredQuestions[index]),
                            subtitle: Text('Your Answer: ${widget.userSelectedWords[index]}'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Buttons pinned to the very bottom (no gap!)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share Report'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _sharePDFReport,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        ref.read(wordGameStateProvider.notifier).clearGameState();
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 28),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}