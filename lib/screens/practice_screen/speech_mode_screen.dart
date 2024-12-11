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

  Future<void> _initializeSpeech() async {
    try {
      await _speechRecognitionService.initializeSpeech();
    } catch (e) {
      print("Speech recognition initialization failed: $e");
    }
  }

  void _startSpeechRecognition() async {
    final wordGameState = ref.read(wordGameStateProvider);

    if (!_speechRecognitionService.isListening) {
      setState(() {
        isListening = true;
      });
      await _speechRecognitionService.startListening(
        timeout: const Duration(seconds: 10),
        onResult: (recognizedWord) {
          setState(() {
            _recognizedWord = recognizedWord;
          });
          if (recognizedWord == wordGameState.correctWord.toLowerCase()) {
            ref.read(wordGameStateProvider.notifier).handleAnswer(recognizedWord);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Speak Mode'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.volume_up, size: 64),
              onPressed: () => ref.read(ttsServiceProvider).speak(wordGameState.correctWord, ref),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _startSpeechRecognition,
              child: Text('Start Speaking'),
            ),
            Text('You said: $_recognizedWord'),
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                onPressed: wordGameState.isPaused ? null : widget.pauseTimer,
                backgroundColor: wordGameState.isPaused ? Colors.grey : null,
                child: const Icon(Icons.pause),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
