import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../questions/speech_recog.dart';
import '../../questions/tts_translator.dart';
import '/questions/word_generator.dart';
import 'package:word_app/models/word_game_state.dart';
import 'confetti_helper.dart';

class ReadModeScreen extends ConsumerStatefulWidget {
  final int elapsedTime;
  final VoidCallback pauseTimer;
  final VoidCallback resumeTimer;
  final VoidCallback showQuitDialog;
  final VoidCallback endQuiz;

  const ReadModeScreen({
    super.key,
    required this.elapsedTime,
    required this.pauseTimer,
    required this.resumeTimer,
    required this.showQuitDialog,
    required this.endQuiz,
  });

  @override
  _ReadModeScreenState createState() => _ReadModeScreenState();
}

class _ReadModeScreenState extends ConsumerState<ReadModeScreen> {
  bool isListening = false;
  String _recognizedWord = '';
  late final ConfettiManager confettiManager;

  late SpeechRecognitionService _speechRecognitionService;

  @override
  void initState() {
    super.initState();
    _speechRecognitionService = ref.read(speechRecognitionServiceProvider);
    confettiManager = ConfettiManager();
    _initializeSpeech();
    _speakInitialWord();
  }

  @override
  void dispose() {
    _speechRecognitionService.stopListening();
    confettiManager.dispose();
    super.dispose();
  }

  void _speakInitialWord() {
    final word = ref.read(wordGameStateProvider).correctWord;
    if (word.isNotEmpty) {
      ref.read(ttsServiceProvider).speak(word, ref);
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechRecognitionService.initializeSpeech();
    } catch (e) {
      print("Speech recognition initialization failed: $e");
      if (mounted) {
        setState(() {
          _recognizedWord = e.toString().contains('permission')
              ? 'Microphone permission required'
              : 'Speech recognition unavailable';
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Speech Recognition Error'),
            content: Text(
              e.toString().contains('permission')
                  ? 'Please grant microphone permission to use speech recognition.'
                  : 'Speech recognition is not available on this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _startSpeechRecognition() async {

    try {
      if (!_speechRecognitionService.isListening) {
        setState(() {
          isListening = true;
          _recognizedWord = '';
        });

        await _speechRecognitionService.startListening(
          timeout: const Duration(seconds: 10),
          onResult: (recognizedWord) {
            if (!mounted) return;

            print('Recognized word: $recognizedWord'); // Debug
            setState(() {
              _recognizedWord = recognizedWord.isEmpty ? 'No match' : recognizedWord;
            });

            final previousAttempts = ref.read(wordGameStateProvider).incorrectAttempts;
            final previousWord = ref.read(wordGameStateProvider).correctWord;
            ref.read(wordGameStateProvider.notifier).handleAnswer(
                recognizedWord.isEmpty || recognizedWord == 'NO_MATCH' ? 'NO_MATCH' : recognizedWord);

            final newState = ref.read(wordGameStateProvider);
            print('Incorrect attempts: ${newState.incorrectAttempts}'); // Debug
            if (recognizedWord.toLowerCase().trim() == previousWord.toLowerCase().trim()) {
              confettiManager.correctConfettiController.play();
            } else if (newState.incorrectAttempts == 0 && previousAttempts >= 2) {
              confettiManager.wrongConfettiController.play();
            } else {
              confettiManager.wrongConfettiController.play();
            }

            _speakNextWord();
          },
        );
      }
    } catch (e) {
      if (!mounted) return;

      print('Speech recognition exception: $e'); // Debug
      setState(() {
        isListening = false;
        _recognizedWord = 'Error occurred';
      });
    } finally {
      setState(() {
        isListening = false;
      });
    }
  }

  void _speakNextWord() {
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        final word = ref.read(wordGameStateProvider).correctWord;
        if (word.isNotEmpty) {
          _speakWord(word);
        }
      },
    );
  }

  void _speakWord(String word) {
    ref.read(ttsServiceProvider).speak(word, ref);
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(theme, wordGameState),
                Expanded(
                  child: Center(
                    child: !wordGameState.isPaused
                        ? _buildSpeechContent(theme, wordGameState)
                        : _buildPausedContent(theme),
                  ),
                ),
                _buildPauseButton(theme, wordGameState),
              ],
            ),
          ),
          _buildConfetti(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, WordGameState wordGameState) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Read Mode'),
      centerTitle: true,
      actions: [
        _buildTimerWidget(theme),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildTimerWidget(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatTime(widget.elapsedTime),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: widget.showQuitDialog,
        ),
        IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: widget.endQuiz,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSpeechContent(ThemeData theme, WordGameState wordGameState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeakerButton(theme),
            const SizedBox(height: 20),
            Text(
              'Attempts: ${wordGameState.incorrectAttempts}/3',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startSpeechRecognition,
              child: const Text('Start Speaking'),
            ),
            const SizedBox(height: 20),
            Text(
              'You said: $_recognizedWord',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerButton(ThemeData theme) {
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          ref.read(wordGameStateProvider).correctWord,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPausedContent(ThemeData theme) {
    return Center(
      child: Text(
        'Game Paused',
        style: theme.textTheme.headlineMedium,
      ),
    );
  }

  Widget _buildPauseButton(ThemeData theme, WordGameState wordGameState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: FloatingActionButton(
        onPressed: () {
          if (wordGameState.isPaused) {
            widget.resumeTimer();
            ref.read(wordGameStateProvider.notifier).togglePause();
          } else {
            widget.pauseTimer();
            ref.read(wordGameStateProvider.notifier).togglePause();
          }
        },
        backgroundColor:
            wordGameState.isPaused ? Colors.grey : theme.colorScheme.primary,
        child: Icon(
          wordGameState.isPaused ? Icons.play_arrow : Icons.pause,
          size: 48,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Stack(
      children: [
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
    );
  }
}