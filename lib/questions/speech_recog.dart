import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  Function(String)? _onResultCallback;
  bool _isContinuous = false;
  String? _currentLocaleId;

  Future<void> initializeSpeech() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception('Microphone permission denied');
    }

    bool available = await _speechToText.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if ((status == 'done' || status == 'notListening') && _isContinuous) {
          print('Auto-restarting continuous listening...');
          // Add a small delay to prevent rapid loops
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_isContinuous) {
              // We don't have the localeId here easily without storing it,
              // but for now let's assume it uses the last used or default.
              // To do this properly, we should store the current localeId in the service.
              _startListeningInternal(localeId: _currentLocaleId);
            }
          });
        }
      },
      onError: (error) {
        print('Speech error: $error');
        // Optionally handle error-based restarts here if needed
      },
    );
    if (!available) {
      throw Exception('Speech recognition not available');
    }
  }

  Future<List<stt.LocaleName>> getLocales() async {
    return await _speechToText.locales();
  }

  Future<void> startContinuousListening({
    required void Function(String) onResult,
    String? localeId,
  }) async {
    _onResultCallback = onResult;
    _isContinuous = true;
    _currentLocaleId = localeId;
    await _startListeningInternal(localeId: localeId);
  }

  Future<void> _startListeningInternal({String? localeId}) async {
    if (!_isContinuous) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            final recognizedText = result.recognizedWords.trim();
            // print('Continuous recognition: $recognizedText');
            _onResultCallback?.call(recognizedText);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        onDevice: true,
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
      );
    } catch (e) {
      print('Error starting listening: $e');
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
    _isContinuous = false;
  }

  bool get isListening => _speechToText.isListening;
  bool get isContinuous => _isContinuous;
}

final speechRecognitionServiceProvider =
    Provider<SpeechRecognitionService>((ref) {
  return SpeechRecognitionService();
});
