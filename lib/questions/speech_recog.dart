import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  Function(String)? _onResultCallback;
  bool _isContinuous = false;

  Future<void> initializeSpeech() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception('Microphone permission denied');
    }

    bool available = await _speechToText.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    if (!available) {
      throw Exception('Speech recognition not available');
    }
  }

  Future<void> startContinuousListening({
    required void Function(String) onResult,
  }) async {
    _onResultCallback = onResult;
    _isContinuous = true;

    await _speechToText.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          final recognizedText = result.recognizedWords.trim();
          print('Continuous recognition: $recognizedText');
          
          // Call the callback with the recognized text
          _onResultCallback?.call(recognizedText);
        }
      },
      listenFor: Duration(minutes: 5), // Longer duration for continuous listening
      pauseFor: Duration(seconds: 3),
      cancelOnError: true,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<String?> startListening({
    required Duration timeout,
    required void Function(String) onResult,
  }) async {
    String? recognizedSentence;

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          recognizedSentence = result.recognizedWords;
          onResult(recognizedSentence ?? '');
        }
      },
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
    );

    return recognizedSentence;
  }

  void stopListening() {
    _speechToText.stop();
    _isContinuous = false;
  }

  bool get isListening => _speechToText.isListening;
  bool get isContinuous => _isContinuous;
}

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>((ref) {
  return SpeechRecognitionService();
});