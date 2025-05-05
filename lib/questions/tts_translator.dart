import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  double _volume = 1.0; // Default volume (0.0 to 1.0)
  double _pitch = 1.0; // Default pitch
  double _speechRate = 0.5; // Default speech rate

  // Getter for volume
  double get volume => _volume;

  // Setter for volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0); // Ensure volume is within valid range
    await _flutterTts.setVolume(_volume);
  }

  Future<void> speak(String text, WidgetRef ref) async {
    await _flutterTts.setLanguage('en-GB');
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.speak(text);
  }
}

final ttsServiceProvider = Provider<TTSService>((ref) => TTSService());