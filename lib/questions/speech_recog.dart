import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  Function(String)? _onResultCallback;
  bool _isContinuous = false;
  String? _currentLocaleId;
  bool _shouldAutoRestart = true;
  Timer? _restartTimer;

  Future<void> initializeSpeech() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception('Microphone permission denied');
    }

    bool available = await _speechToText.initialize(
      onStatus: (status) {
        print('Speech status: $status');

        // Only restart for specific statuses and if continuous mode is active
        if (_isContinuous && _shouldAutoRestart) {
          if (status == 'done' || status == 'notListening') {
            print('Auto-restarting continuous listening...');

            // Cancel any existing restart timer
            _restartTimer?.cancel();

            // Use a more reasonable delay to prevent rapid restarts
            _restartTimer = Timer(const Duration(milliseconds: 500), () {
              if (_isContinuous &&
                  _shouldAutoRestart &&
                  !_speechToText.isListening) {
                _startListeningInternal(localeId: _currentLocaleId);
              }
            });
          }
        }
      },
      onError: (error) {
        print('Speech error: $error');
        // For errors, wait longer before restarting
        if (_isContinuous && _shouldAutoRestart) {
          _restartTimer?.cancel();
          _restartTimer = Timer(const Duration(seconds: 2), () {
            if (_isContinuous &&
                _shouldAutoRestart &&
                !_speechToText.isListening) {
              _startListeningInternal(localeId: _currentLocaleId);
            }
          });
        }
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
    _shouldAutoRestart = true;
    _currentLocaleId = localeId;

    // Cancel any pending restart
    _restartTimer?.cancel();

    await _startListeningInternal(localeId: localeId);
  }

  Future<void> _startListeningInternal({String? localeId}) async {
    if (!_isContinuous || _speechToText.isListening) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            final recognizedText = result.recognizedWords.trim();
            _onResultCallback?.call(recognizedText);
          }
        },
        // Increased listen duration to reduce restart frequency
        listenFor: const Duration(minutes: 5), // Increased from 30 seconds
        pauseFor: const Duration(seconds: 10), // Increased pause time
        partialResults: true,
        onDevice: true,
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        // Add these to reduce start/stop sounds
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      print('Error starting listening: $e');
      // If error occurs, wait before retrying
      if (_isContinuous) {
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(seconds: 2), () {
          if (_isContinuous && !_speechToText.isListening) {
            _startListeningInternal(localeId: localeId);
          }
        });
      }
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
    _shouldAutoRestart = false;
    _isContinuous = false;
    _restartTimer?.cancel();
    _speechToText.stop();
  }

  void pauseAutoRestart() {
    _shouldAutoRestart = false;
  }

  void resumeAutoRestart() {
    _shouldAutoRestart = true;
  }

  bool get isListening => _speechToText.isListening;
  bool get isContinuous => _isContinuous;
}

final speechRecognitionServiceProvider =
    Provider<SpeechRecognitionService>((ref) {
  return SpeechRecognitionService();
});
