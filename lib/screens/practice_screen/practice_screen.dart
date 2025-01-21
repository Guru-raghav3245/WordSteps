import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/screens/result_screen.dart';
import '/modals/pause_modal.dart';
import '/modals/quit_modal.dart';
import '/questions/word_generator.dart';
import 'speech_mode_screen.dart';
import 'package:word_app/questions/tts_translator.dart';
import 'package:word_app/screens/home_screen.dart';

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
            _timer.cancel();
            ref.read(wordGameStateProvider.notifier).quitGame();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      },
    );
  }

  void _endQuiz() {
    _timer.cancel();
    final gameState = ref.read(wordGameStateProvider);
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameMode = ref.watch(gameModeProvider);

    if (gameMode == 'choose') {
      return ChooseModeScreen(
        elapsedTime: _elapsedTime,
        pauseTimer: _pauseTimer,
        resumeTimer: _resumeTimer,
        showQuitDialog: _showQuitDialog,
        endQuiz: _endQuiz,
      );
    } else if (gameMode == 'speech') {
      return SpeakModeScreen(
        elapsedTime: _elapsedTime,
        pauseTimer: _pauseTimer,
        resumeTimer: _resumeTimer,
        showQuitDialog: _showQuitDialog,
        endQuiz: _endQuiz,
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Unknown Mode'),
        ),
        body: const Center(
          child: Text(
            'Invalid game mode.',
            style: TextStyle(fontSize: 24, color: Colors.red),
          ),
        ),
      );
    }
  }
}

class ChooseModeScreen extends ConsumerWidget {
  final int elapsedTime;
  final VoidCallback pauseTimer;
  final VoidCallback resumeTimer;
  final VoidCallback showQuitDialog;
  final VoidCallback endQuiz;

  const ChooseModeScreen({
    super.key,
    required this.elapsedTime,
    required this.pauseTimer,
    required this.resumeTimer,
    required this.showQuitDialog,
    required this.endQuiz,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Mode'),
        backgroundColor: Colors.blueAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '${elapsedTime ~/ 60}:${(elapsedTime % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: showQuitDialog,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: endQuiz,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (wordGameState.isPaused)
                const Text(
                  'Game Paused',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 64),
                      color: Colors.deepOrange,
                      onPressed: () => ref
                          .read(ttsServiceProvider)
                          .speak(wordGameState.correctWord, ref),
                    ),
                    const SizedBox(height: 30),
                    ...wordGameState.options.map((word) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          onPressed: () =>
                              ref.read(wordGameStateProvider.notifier).handleAnswer(word),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            minimumSize: const Size(200, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            word,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              const SizedBox(height: 20),
              FloatingActionButton(
                onPressed: wordGameState.isPaused ? null : pauseTimer,
                backgroundColor: wordGameState.isPaused ? Colors.grey : Colors.redAccent,
                child: const Icon(Icons.pause),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
