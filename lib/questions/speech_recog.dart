import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();

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
  }

  bool get isListening => _speechToText.isListening;
}

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>((ref) {
  return SpeechRecognitionService();
});