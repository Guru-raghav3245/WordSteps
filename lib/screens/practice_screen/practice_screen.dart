import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/screens/result_screen/result_screen.dart';
import '/modals/pause_modal.dart';
import '/modals/quit_modal.dart';
import '/questions/word_generator.dart';
import 'read_screen.dart';
import 'package:word_app/screens/home_screen/home_screen.dart';
import 'listen_screen.dart';

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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!_isPaused) {
          setState(() => _elapsedTime++);
        }
      },
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer.cancel();
        _showPauseDialog();
      } else {
        _startTimer();
      }
    });
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          _togglePause();
        },
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (context) => QuitDialog(
        onQuit: () {
          _timer.cancel();
          ref.read(wordGameStateProvider.notifier).quitGame();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  void _navigateToResults() {
    _timer.cancel();
    final gameState = ref.read(wordGameStateProvider);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          gameState.answeredQuestions,
          gameState.answeredCorrectly,
          _elapsedTime,
          () => Navigator.of(context).popUntil((route) => route.isFirst),
          userSelectedWords: gameState.userSelectedWords,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameMode = ref.watch(gameModeProvider);
    final screenProps = GameScreenProps(
      elapsedTime: _elapsedTime,
      pauseTimer: _togglePause,
      resumeTimer: _togglePause,
      showQuitDialog: _showQuitDialog,
      endQuiz: _navigateToResults,
    );

    return _buildGameScreen(gameMode, screenProps);
  }

  Widget _buildGameScreen(String gameMode, GameScreenProps props) {
    switch (gameMode) {
      case 'read':
        return ListenModeScreen(props: props);
      case 'listen':
        return ReadModeScreen(
          elapsedTime: props.elapsedTime,
          pauseTimer: props.pauseTimer,
          resumeTimer: props.resumeTimer,
          showQuitDialog: props.showQuitDialog,
          endQuiz: props.endQuiz,
        );
      default:
        return _buildErrorScreen();
    }
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Unknown Mode')),
      body: const Center(
        child: Text(
          'Invalid game mode.',
          style: TextStyle(fontSize: 24, color: Colors.red),
        ),
      ),
    );
  }
}