import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/questions/word_generator.dart';
import 'package:share_plus/share_plus.dart';
import 'pdf_generator.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final List<String> answeredQuestions;
  final List<bool> answeredCorrectly;
  final int totalTime;
  final Function switchToStartScreen;
  final List<String> userSelectedWords;

  const ResultScreen(
    this.answeredQuestions,
    this.answeredCorrectly,
    this.totalTime,
    this.switchToStartScreen, {
    super.key,
    required this.userSelectedWords,
  });

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleExit() async {
    ref.read(wordGameStateProvider.notifier).clearGameState();
    widget.switchToStartScreen();
  }

  Future<void> _sharePDFReport() async {
    try {
      final file = await QuizPDFGenerator.generateQuizPDF(
        answeredQuestions: widget.answeredQuestions,
        userAnswers: widget.userSelectedWords,
        answeredCorrectly: widget.answeredCorrectly,
        totalTime: widget.totalTime,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Word Game Quiz Results',
        text: 'Check out my quiz results! Attached is the detailed report.',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int minutes = widget.totalTime ~/ 60;
    int seconds = widget.totalTime % 60;
    int totalQuestions = widget.answeredQuestions.length;
    int correctAnswers =
        widget.answeredCorrectly.where((correct) => correct).length;
    double progressValue =
        totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Quiz Results'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Icon(Icons.timer,
                                      size: 28,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$minutes:${seconds.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'Time',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.question_answer,
                                      size: 28,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalQuestions',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'Questions',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 28,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$correctAnswers',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'Correct',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor:
                                  theme.colorScheme.primary.withOpacity(0.2),
                              color: theme.colorScheme.primary,
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Question Review Header
                Text(
                  'Question Review',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                // Question List
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: widget.answeredQuestions.isEmpty
                      ? FadeTransition(
                          opacity: _fadeAnimation,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.quiz,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No questions answered yet!',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a quiz to see your results here.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back to Home'),
                                  onPressed: _handleExit,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    backgroundColor: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SlideTransition(
                          position: _slideAnimation,
                          child: ListView.builder(
                            itemCount: widget.answeredQuestions.length,
                            itemBuilder: (context, index) {
                              final isCorrect = widget.answeredCorrectly[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: isCorrect
                                          ? Colors.green
                                          : theme.colorScheme.error,
                                      child: Icon(
                                        isCorrect ? Icons.check : Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Correct: ${widget.answeredQuestions[index]}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      'Your Answer: ${widget.userSelectedWords[index]}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: isCorrect
                                            ? Colors.green
                                            : theme.colorScheme.error,
                                      ),
                                    ),
                                    trailing: Text(
                                      '#${index + 1}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _sharePDFReport,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.share,
                            color: theme.colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.home, color: theme.colorScheme.onPrimary),
                          label: const Text('Home'),
                          onPressed: _handleExit,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onPrimary,
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}