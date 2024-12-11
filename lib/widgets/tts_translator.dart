import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  Future<void> speak(String text, WidgetRef ref) async {
    // Get the values from Riverpod providers using ref.read
    final double volume = 1.0;
    final double pitch = 1.0;
    final double speechRate = 1.0;
    // Apply TTS settings
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(pitch);
    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.setVolume(volume);
    // Speak the text
    await _flutterTts.speak(text);
  }
}

final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService(); // Replace with your TTS service initialization
});