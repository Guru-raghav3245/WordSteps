import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/widgets/speech_recog.dart';
import '/widgets/tts_translator.dart';
import '/questions/word_generator.dart';

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

  late SpeechRecognitionService _speechRecognitionService;

  @override
  void initState() {
    super.initState();
    _speechRecognitionService = ref.read(speechRecognitionServiceProvider);
    _initializeSpeech();
  }

  @override
  void dispose() {
    // Cancel any ongoing speech recognition
    _speechRecognitionService.stopListening();
    super.dispose();
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
              _recognizedWord = recognizedWord ?? '';
            });

            if (recognizedWord != null &&
                recognizedWord.toLowerCase() ==
                    wordGameState.correctWord.toLowerCase()) {
              ref
                  .read(wordGameStateProvider.notifier)
                  .handleAnswer(recognizedWord);
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

  @override
  Widget build(BuildContext context) {
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speak Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: widget.showQuitDialog,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: widget.endQuiz,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.volume_up, size: 64),
            onPressed: () => ref
                .read(ttsServiceProvider)
                .speak(wordGameState.correctWord, ref),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: _startSpeechRecognition,
            child: const Text('Start Speaking'),
          ),
          Text('You said: $_recognizedWord'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: wordGameState.isPaused ? null : widget.pauseTimer,
        backgroundColor: wordGameState.isPaused ? Colors.grey : null,
        child: const Icon(Icons.pause),
      ),
    );
  }
}
