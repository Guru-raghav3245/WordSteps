import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../questions/speech_recog.dart';
import '/questions/word_generator.dart';
import 'package:word_app/models/word_game_state.dart';
import 'confetti_helper.dart';
import 'package:string_similarity/string_similarity.dart';

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
  bool _isProcessing = false; // To prevent multiple processing

  late SpeechRecognitionService _speechRecognitionService;

  @override
  void initState() {
    super.initState();
    _speechRecognitionService = ref.read(speechRecognitionServiceProvider);
    confettiManager = ConfettiManager();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speechRecognitionService.stopListening();
    confettiManager.dispose();
    super.dispose();
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

  void _startContinuousSpeechRecognition() async {
    try {
      if (!_speechRecognitionService.isListening) {
        setState(() {
          isListening = true;
          _recognizedWord = 'Listening...';
          _isProcessing = false;
        });

        await _speechRecognitionService.startContinuousListening(
          onResult: (recognizedWord) {
            if (!mounted || _isProcessing) return;

            print('Continuous Recognized: $recognizedWord');

            setState(() {
              _recognizedWord =
                  recognizedWord.isEmpty ? 'Listening...' : recognizedWord;
            });

            // Only process if we have substantial text
            if (recognizedWord.isNotEmpty && recognizedWord != 'Listening...') {
              _processSpeechResult(recognizedWord);
            }
          },
        );
      }
    } catch (e) {
      if (!mounted) return;

      print('Speech recognition exception: $e');
      setState(() {
        isListening = false;
        _recognizedWord = 'Error occurred';
      });
    }
  }

  void _processSpeechResult(String recognizedWord) {
    if (_isProcessing) return;

    _isProcessing = true;

    final currentState = ref.read(wordGameStateProvider);
    final correctWord = currentState.correctWord;

    // Normalize both strings for comparison
    String normalizedRecognized = recognizedWord
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    String normalizedCorrect = correctWord
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    print('Normalized Recognized: $normalizedRecognized');
    print('Normalized Correct: $normalizedCorrect');

    double similarity = normalizedRecognized.similarityTo(normalizedCorrect);
    print('Similarity score: $similarity');

    // Check if the recognized text contains the correct word or has high similarity
    bool isCorrect =
        normalizedRecognized.contains(normalizedCorrect) || similarity > 0.7;

    if (isCorrect) {
      print('Correct answer detected! Moving to next question...');

      // Handle the correct answer
      ref.read(wordGameStateProvider.notifier).handleAnswer(recognizedWord);

      // Show confetti
      confettiManager.correctConfettiController.play();

      // Reset for next question after a short delay
      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _recognizedWord = 'Correct! Next word...';
            _isProcessing = false;
          });

          // The wordGameStateProvider will automatically update with the next word
          // Continue listening for the next word
          Future.delayed(Duration(milliseconds: 1000), () {
            if (mounted && _speechRecognitionService.isContinuous) {
              setState(() {
                _recognizedWord = 'Listening...';
              });
              _isProcessing = false;
            }
          });
        }
      });
    } else {
      // Incorrect attempt - call handleAnswer with the incorrect response
      // This should increment the incorrect attempts counter
      ref.read(wordGameStateProvider.notifier).handleAnswer(recognizedWord);

      // Show wrong confetti for incorrect attempts
      if (ref.read(wordGameStateProvider).incorrectAttempts >= 2) {
        confettiManager.wrongConfettiController.play();
      }

      // Update the display but keep listening
      setState(() {
        _recognizedWord = recognizedWord;
      });

      _isProcessing = false;

      print(
          'Incorrect attempt. Current attempts: ${ref.read(wordGameStateProvider).incorrectAttempts}');
    }
  }

  void _stopSpeechRecognition() {
    _speechRecognitionService.stopListening();
    setState(() {
      isListening = false;
      _recognizedWord = '';
      _isProcessing = false;
    });
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

  PreferredSizeWidget _buildAppBar(
      ThemeData theme, WordGameState wordGameState) {
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
            if (!isListening)
              ElevatedButton(
                onPressed: _startContinuousSpeechRecognition,
                child: const Text('Start Continuous Listening'),
              )
            else
              ElevatedButton(
                onPressed: _stopSpeechRecognition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Stop Listening'),
              ),
            const SizedBox(height: 20),
            Text(
              'You said: $_recognizedWord',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (isListening) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Speak the word above...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
