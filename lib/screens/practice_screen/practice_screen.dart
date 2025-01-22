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
import 'confetti_helper.dart';

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

class ChooseModeScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ChooseModeScreen> createState() => _ChooseModeScreenState();
}

class _ChooseModeScreenState extends ConsumerState<ChooseModeScreen> {
  late final ConfettiManager confettiManager;

  @override
  void initState() {
    super.initState();
    confettiManager = ConfettiManager();
  }

  @override
  void dispose() {
    confettiManager.dispose();
    super.dispose();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Choose Mode',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                formatTime(widget.elapsedTime),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            iconSize: 28,
            onPressed: widget.showQuitDialog,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            iconSize: 28,
            onPressed: widget.endQuiz,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade600,
                  Colors.red.shade100,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(),
                      if (!wordGameState.isPaused) ...[
                        Container(
                          width:  MediaQuery.of(context).size.width * 0.9,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.volume_up),
                                  iconSize: 70,
                                  color: Colors.red.shade700,
                                  onPressed: () => ref
                                      .read(ttsServiceProvider)
                                      .speak(wordGameState.correctWord, ref),
                                ),
                              ),
                              const SizedBox(height: 50),
                              ...wordGameState.options.map((word) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Handle the selected answer
                                      if (word == wordGameState.correctWord) {
                                        confettiManager
                                            .correctConfettiController
                                            .play();
                                      } else {
                                        confettiManager.wrongConfettiController
                                            .play();
                                      }
                                      ref
                                          .read(wordGameStateProvider.notifier)
                                          .handleAnswer(word);

                                      // Automatically speak the next word
                                      Future.delayed(
                                          const Duration(milliseconds: 500),
                                          () {
                                        if (ref
                                            .read(wordGameStateProvider)
                                            .correctWord
                                            .isNotEmpty) {
                                          ref.read(ttsServiceProvider).speak(
                                              ref
                                                  .read(wordGameStateProvider)
                                                  .correctWord,
                                              ref);
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red.shade700,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        side: BorderSide(
                                            color: Colors.red.shade200),
                                      ),
                                      minimumSize: const Size(double.infinity, 48),
                                    ),
                                    child: Text(
                                      word,
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ] else
                        const Center(
                          child: Text(
                            'Game Paused',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: FloatingActionButton(
                          onPressed:
                              wordGameState.isPaused ? null : widget.pauseTimer,
                          backgroundColor: wordGameState.isPaused
                              ? Colors.grey
                              : Colors.red.shade700,
                          elevation: 4,
                          child: Icon(
                            wordGameState.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: confettiManager.buildCorrectConfetti(),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: confettiManager.buildWrongConfetti(),
            ),
          ),
        ],
      ),
    );
  }
}
