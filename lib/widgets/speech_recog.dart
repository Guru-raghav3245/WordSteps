import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognitionService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  
  Future<void> initializeSpeech() async {
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
    String? recognizedWord;
    
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          recognizedWord = result.recognizedWords.toLowerCase().trim();
          onResult(recognizedWord ?? '');
        }
      },
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: false,
    );

    return recognizedWord;
  }

  void stopListening() {
    _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}

// Riverpod Provider for SpeechRecognitionService
final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>((ref) {
  return SpeechRecognitionService();
});