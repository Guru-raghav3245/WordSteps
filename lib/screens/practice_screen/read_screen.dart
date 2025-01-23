import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../questions/speech_recog.dart';
import '../../questions/tts_translator.dart';
import '/questions/word_generator.dart';
import 'confetti_helper.dart';

class SpeakModeScreen extends ConsumerStatefulWidget {
  final int elapsedTime;
  final VoidCallback pauseTimer;
  final VoidCallback resumeTimer;
  final VoidCallback showQuitDialog;
  final VoidCallback endQuiz;

  const SpeakModeScreen({
    super.key,
    required this.elapsedTime,
    required this.pauseTimer,
    required this.resumeTimer,
    required this.showQuitDialog,
    required this.endQuiz,
  });

  @override
  _SpeakModeScreenState createState() => _SpeakModeScreenState();
}

class _SpeakModeScreenState extends ConsumerState<SpeakModeScreen> {
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
    // Cancel any ongoing speech recognition
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
    }
  }

  void _startSpeechRecognition() async {
    final wordGameState = ref.read(wordGameStateProvider);

    try {
      if (!_speechRecognitionService.isListening) {
        setState(() {
          isListening = true;
          _recognizedWord = ''; // Clear previous recognition
        });

        await _speechRecognitionService.startListening(
          timeout: const Duration(seconds: 10),
          onResult: (recognizedWord) {
            if (!mounted) return; // Check if widget is still in the tree

            print('Speech Recognition Result: $recognizedWord');

            setState(() {
              _recognizedWord = recognizedWord;
            });

            if (recognizedWord.toLowerCase() ==
                wordGameState.correctWord.toLowerCase()) {
              confettiManager.correctConfettiController.play();
              ref
                  .read(wordGameStateProvider.notifier)
                  .handleAnswer(recognizedWord);
              _speakNextWord();
            } else {
              confettiManager.wrongConfettiController.play();
            }
          },
        );
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still in the tree

      print('Speech Recognition Exception: $e');
      setState(() {
        isListening = false;
        _recognizedWord = 'Error occurred';
      });
    }
  }

  void _speakNextWord() {
    Future.delayed(
      const Duration(milliseconds: 0),
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
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          _buildBackground(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                _buildAppBar(wordGameState),

                // Main Content
                Expanded(
                  child: Center(
                    child: !wordGameState.isPaused
                        ? _buildSpeechContent(wordGameState)
                        : _buildPausedContent(),
                  ),
                ),

                // Pause Button
                _buildPauseButton(wordGameState),
              ],
            ),
          ),

          // Confetti
          _buildConfetti(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
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
    );
  }

  PreferredSizeWidget _buildAppBar(wordGameState) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Speak Mode',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        elevation: 0,
        actions: [
          _buildTimerWidget(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTimerWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          _formatTime(widget.elapsedTime),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
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
    );
  }

  Widget _buildSpeechContent(wordGameState) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSpeakerButton(),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: _startSpeechRecognition,
            style: _buildStartSpeakButtonStyle(),
            child: Text(
              'Start Speaking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You said: $_recognizedWord',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  ButtonStyle _buildStartSpeakButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.red.shade200),
      ),
    );
  }

  Widget _buildSpeakerButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: /*IconButton(
        icon: const Icon(Icons.volume_up),
        iconSize: 70,
        color: Colors.red.shade700,
        onPressed: () => _speakWord(ref.read(wordGameStateProvider).correctWord),
      ),*/
      Center(
        child: Text(
          ref.read(wordGameStateProvider).correctWord,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildPausedContent() {
    return const Center(
      child: Text(
        'Game Paused',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPauseButton(wordGameState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: FloatingActionButton(
        onPressed: wordGameState.isPaused ? null : widget.pauseTimer,
        backgroundColor:
            wordGameState.isPaused ? Colors.grey : Colors.red.shade700,
        elevation: 4,
        child: Icon(
          wordGameState.isPaused ? Icons.play_arrow : Icons.pause,
          size: 48,
          color: Colors.white,
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