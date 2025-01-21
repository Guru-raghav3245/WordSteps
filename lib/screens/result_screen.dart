import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/questions/word_generator.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart'; // Add this import

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

class _ResultScreenState extends ConsumerState<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward(); // Start the animations
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
    // Generate the detailed PDF using the QuizPDFGenerator class
    final file = await QuizPDFGenerator.generateQuizPDF(
      answeredQuestions: widget.answeredQuestions,
      userAnswers: widget.userSelectedWords,
      answeredCorrectly: widget.answeredCorrectly,
      totalTime: widget.totalTime,
    );

    // Use SharePlus to share the PDF file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Word Game Quiz Results',
      text: 'Check out my quiz results! Attached is the detailed report.',
    );
  } catch (e) {
    // Handle any errors during PDF generation or sharing
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: ${e.toString()}'),
          backgroundColor: Colors.red.shade700, // Darker red for better contrast
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int minutes = widget.totalTime ~/ 60;
    int seconds = widget.totalTime % 60;

    int correctAnswers =
        widget.answeredCorrectly.where((correct) => correct).length;

    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Quiz Results',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Time Taken: $minutes:${seconds.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Questions Attended: ${widget.answeredQuestions.length}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Correct Answers: $correctAnswers',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: widget.answeredQuestions.isEmpty
                    ? Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'No questions attended',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.error,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : SlideTransition(
                        position: _slideAnimation,
                        child: ListView.separated(
                          itemCount: widget.answeredQuestions.length,
                          separatorBuilder: (context, index) =>
                              const Divider(),
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    widget.answeredCorrectly[index]
                                        ? theme.colorScheme.primary
                                        : Colors.red,
                                child: Text(
                                  (index + 1).toString(),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                'Correct Word: ${widget.answeredQuestions[index]}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                'Selected Word: ${widget.userSelectedWords[index]}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: widget.answeredCorrectly[index]
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _fadeAnimation,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: _handleExit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 24.0),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  label: const Text(
                    'Go to Start Screen',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _sharePDFReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                label: const Text('Share Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizPDFGenerator {
  static Future<File> generateQuizPDF({
    required List<String> answeredQuestions,
    required List<String> userAnswers,
    required List<bool> answeredCorrectly,
    required int totalTime,
  }) async {
    final pdf = pw.Document();
    
    // Calculate statistics
    final correctAnswers = answeredCorrectly.where((correct) => correct).length;
    final wrongAnswers = answeredCorrectly.where((correct) => !correct).length;
    final totalQuestions = answeredQuestions.length;
    final score = totalQuestions > 0 
        ? ((correctAnswers / totalQuestions) * 100).toStringAsFixed(1) 
        : '0';
    final minutes = totalTime ~/ 60;
    final seconds = totalTime % 60;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Quiz Results',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),

          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.symmetric(vertical: 20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Quiz Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Time Taken', '$minutes:${seconds.toString().padLeft(2, '0')}'),
                    _buildSummaryItem('Score', '$score%'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Total Questions', totalQuestions.toString()),
                    _buildSummaryItem('Correct Answers', correctAnswers.toString()),
                    _buildSummaryItem('Wrong Answers', wrongAnswers.toString()),
                  ],
                ),
              ],
            ),
          ),

          // Questions Section
          pw.Header(
            level: 1,
            text: 'Detailed Questions & Answers',
            textStyle: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          ...List.generate(answeredQuestions.length, (index) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: answeredCorrectly[index] 
                      ? PdfColors.green 
                      : PdfColors.red,
                  width: 0.5,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 24,
                        height: 24,
                        decoration: pw.BoxDecoration(
                          color: answeredCorrectly[index] 
                              ? PdfColors.green 
                              : PdfColors.red,
                          shape: pw.BoxShape.circle,
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          (index + 1).toString(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'Question: ${answeredQuestions[index]}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Your Answer: ${userAnswers[index]}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Correct: ${answeredCorrectly[index] ? 'Yes' : 'No'}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: answeredCorrectly[index] 
                          ? PdfColors.green 
                          : PdfColors.red,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/quiz_results.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: PdfColors.grey700,
            fontSize: 12,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}