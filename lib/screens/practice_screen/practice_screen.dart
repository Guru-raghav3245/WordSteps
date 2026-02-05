// File: lib/screens/practice_screen/practice_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/screens/result_screen/result_screen.dart';
import 'modals/quit_modal.dart';
import 'modals/inactivity_modal.dart';
import '/questions/word_generator.dart';
import 'read_screen.dart';
import 'package:word_app/screens/home_screen/home_screen.dart';
import 'listen_screen.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  final int? sessionTimeLimit;
  const PracticeScreen({super.key, this.sessionTimeLimit});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late Timer _gameTimer;
  Timer? _inactivityTimer;

  int _elapsedTime = 0;
  bool _isPaused = false;

  DateTime _lastInteractionTime = DateTime.now();

  static const int inactivityThresholdSeconds = 10;

  @override
  void initState() {
    super.initState();
    _lastInteractionTime = DateTime.now();
    _startGameTimer();
    _scheduleInactivityCheck();
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedTime++;
        });

        if (widget.sessionTimeLimit != null &&
            _elapsedTime >= widget.sessionTimeLimit!) {
          _navigateToResults();
        }
      }
    });
  }

  void _scheduleInactivityCheck() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      Duration(seconds: inactivityThresholdSeconds),
      _checkInactivityAndShowModalIfNeeded,
    );
  }

  void _checkInactivityAndShowModalIfNeeded() {
    if (!mounted || _isPaused) return;

    final now = DateTime.now();
    final inactiveSeconds = now.difference(_lastInteractionTime).inSeconds;

    if (inactiveSeconds >= inactivityThresholdSeconds) {
      // 1. Pause the timer immediately
      setState(() {
        _isPaused = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => InActivityModal(
          onResume: () {
            Navigator.of(dialogContext).pop();
            // 2. Resume the timer and reset inactivity tracking
            setState(() {
              _isPaused = false;
            });
            _resetInactivity();
          },
        ),
      );
    }
  }

  void _resetInactivity() {
    _lastInteractionTime = DateTime.now();
    _scheduleInactivityCheck();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _inactivityTimer?.cancel();
    } else {
      _resetInactivity();
    }
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (context) => QuitDialog(
        onQuit: () {
          Navigator.pop(context);
          _navigateToHome();
        },
      ),
    );
  }

  void _navigateToResults() {
    final gameState = ref.read(wordGameStateProvider);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          answeredQuestions: gameState.answeredQuestions,
          answeredCorrectly: gameState.answeredCorrectly,
          totalTime: _elapsedTime,
          userSelectedWords: gameState.userSelectedWords,
          shouldSave: true,
        ),
      ),
    );
  }

  void _navigateToHome() {
    ref.read(wordGameStateProvider.notifier).clearGameState();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
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
      sessionTimeLimit: widget.sessionTimeLimit,
      onUserInteraction: _resetInactivity,
    );

    return _buildGameScreen(gameMode, screenProps);
  }

  Widget _buildGameScreen(String gameMode, GameScreenProps props) {
    switch (gameMode) {
      case 'read':
        return ListenModeScreen(props: props);
      case 'listen':
        return ReadModeScreen(props: props);
      default:
        return Scaffold(
          body: Center(child: Text('Invalid game mode: $gameMode')),
        );
    }
  }
}

class GameScreenProps {
  final int elapsedTime;
  final VoidCallback pauseTimer;
  final VoidCallback resumeTimer;
  final VoidCallback showQuitDialog;
  final VoidCallback endQuiz;
  final int? sessionTimeLimit;
  final VoidCallback onUserInteraction;

  GameScreenProps({
    required this.elapsedTime,
    required this.pauseTimer,
    required this.resumeTimer,
    required this.showQuitDialog,
    required this.endQuiz,
    this.sessionTimeLimit,
    required this.onUserInteraction,
  });
}