import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'result_screen.dart';
import '../questions/tts_translator.dart';
import '../questions/word_generator.dart';
import 'home_screen.dart';
import '../modals/pause_modal.dart';
import '../modals/quit_modal.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  _PracticeScreenState createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late Timer _timer;
  int _elapsedTime = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    // Start timer
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedTime++;
        });
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
    });
    _timer.cancel();
    _showPauseDialog();
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    _startTimer();
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PauseDialog(
          onResume: () {
            Navigator.of(context).pop();
            _resumeTimer();
          },
        );
      },
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuitDialog(
          onQuit: () {
            // Cancel timer and reset game state
            _timer.cancel();

            // Reset the game state
            ref.read(wordGameStateProvider.notifier).quitGame();

            // Return to home screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Cancel timer when screen is disposed
    _timer.cancel();
    super.dispose();
  }

  void _endQuiz() {
    // Cancel the timer
    _timer.cancel();

    // Get the final game state
    final gameState = ref.read(wordGameStateProvider.notifier).getGameResults();

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ResultScreen(
                  gameState.answeredQuestions,
                  gameState.answeredCorrectly,
                  _elapsedTime,
                  () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  userSelectedWords: gameState.userSelectedWords,
                )));
  }

  // Format time as MM:SS
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ttsService = ref.read(ttsServiceProvider);
    final wordGameState = ref.watch(wordGameStateProvider);
    final wordGameNotifier = ref.read(wordGameStateProvider.notifier);
    final wordLength = ref.watch(wordLengthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$wordLength Letter Word Game'),
        actions: [
          // Display elapsed time
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                _formatTime(_elapsedTime),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showQuitDialog,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _endQuiz,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isPaused
              ? const Center(
                  child: Text(
                    'Game Paused',
                    style: TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 64),
                        onPressed: () =>
                            ttsService.speak(wordGameState.correctWord, ref),
                      ),
                      const SizedBox(height: 50),
                      Column(
                        children: wordGameState.options.map((word) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              onPressed: () =>
                                  wordGameNotifier.handleAnswer(word),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 50),
                              ),
                              child: Text(word),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

          // Pause button in bottom left
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: _isPaused ? null : _pauseTimer,
              backgroundColor: _isPaused ? Colors.grey : null,
              child: const Icon(Icons.pause),
            ),
          ),
        ],
      ),
    );
  }
}
