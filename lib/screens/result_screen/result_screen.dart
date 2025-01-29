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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Widget _buildStatsCard(BuildContext context) {
  int minutes = widget.totalTime ~/ 60;
  int seconds = widget.totalTime % 60;
  
  // Prevent division by zero and handle empty list scenarios
  int totalQuestions = widget.answeredQuestions.length;
  int correctAnswers = widget.answeredCorrectly.where((correct) => correct).length;
  
  // Ensure safe division by using max to prevent division by zero
  double progressValue = totalQuestions > 0 
    ? correctAnswers / totalQuestions 
    : 0.0;

  return Container(
    width: MediaQuery.of(context).size.width * 0.9, // Limit width
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: [
        _buildStatRow('Time Taken', '$minutes:${seconds.toString().padLeft(2, '0')}'),
        const Divider(height: 20, color: Colors.black12),
        _buildStatRow('Questions Attended', '$totalQuestions'),
        const Divider(height: 20, color: Colors.black12),
        _buildStatRow('Correct Answers', '$correctAnswers'),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progressValue, // Use safe value
          backgroundColor: Colors.red.shade100,
          color: Colors.green,
          minHeight: 8,
        ),
      ],
    ),
  );
}

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      height: 60,
      child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.red),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
          ),
          iconAlignment: IconAlignment.start),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.red,
          title: const Text(
            'Quiz Results',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatsCard(context),
              const SizedBox(height: 30),
              Expanded(
                flex: 3,
                child: widget.answeredQuestions.isEmpty
                    ? Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'No questions attended',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : SlideTransition(
                        position: _slideAnimation,
                        child: ListView.builder(
                          // Add a null check to prevent potential issues
                          itemCount: widget.answeredQuestions.length,
                          itemBuilder: (context, index) {
                            // Also add null checks for accessing lists
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      widget.answeredCorrectly[index]
                                          ? Colors.green
                                          : Colors.red[600],
                                  child: Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'Correct Answer: ${widget.answeredQuestions[index]}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Selected Answer: ${widget.userSelectedWords[index]}',
                                  style: TextStyle(
                                    color: widget.answeredCorrectly[index]
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 15),
              _buildActionButton(
                label: 'Go to Home Page',
                onPressed: _handleExit,
                gradientColors: [Colors.red, Colors.deepOrange],
                icon: Icons.home,
              ),
              const SizedBox(height: 15),
              _buildActionButton(
                label: 'Share Report',
                onPressed: _sharePDFReport,
                gradientColors: [Colors.green, Colors.lightGreen],
                icon: Icons.share,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
