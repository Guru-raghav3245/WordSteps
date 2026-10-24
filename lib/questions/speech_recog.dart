import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transcribe_cpp/transcribe_cpp.dart';

enum SttModelStatus { idle, needsDownload, downloading, loading, ready, failed }

class SttModelState {
  final SttModelStatus status;
  final double? progress; // 0..1 while downloading
  final String? error;
  const SttModelState(this.status, {this.progress, this.error});
}

/// On-device speech recognition (Moonshine tiny via transcribe_cpp).
/// The ~50 MB model downloads once, and only after the user agrees: [prepare] loads it if it is already on the
/// device (else reports [SttModelStatus.needsDownload]); [prepare] with `download: true` fetches it first.
class SpeechRecognitionService {
  static const _modelId = ModelId('moonshine-streaming-tiny-Q8_0');

  final ValueNotifier<SttModelState> modelState =
      ValueNotifier(const SttModelState(SttModelStatus.idle));

  TranscribeSession? _session;
  Future<void>? _preparing;
  Future<void>? _stopping;
  void Function(String)? _onResult;
  String _settledSeen = '';
  bool _listening = false;

  /// Idempotent. Loads the model; downloads it (resumable, retried) only when [download] is true.
  /// Without consent and without the model on disk, sets [SttModelStatus.needsDownload] and returns.
  /// Throws on failure; safe to call again.
  Future<void> prepare({bool download = false}) {
    if (_session != null) return Future.value();
    final running = _preparing;
    if (running != null) {
      // A consent-less pass may be mid-flight; a download request must still run after it.
      return download ? running.then((_) => prepare(download: true)) : running;
    }
    return _preparing = _prepare(download).whenComplete(() => _preparing = null);
  }

  /// The user agreed to the download: show progress immediately, then fetch and load the model.
  Future<void> downloadModel() {
    modelState.value = const SttModelState(SttModelStatus.loading);
    return prepare(download: true);
  }

  Future<void> _prepare(bool download) async {
    Timer? poll;
    try {
      final models = await ModelManager.open();
      if (!download && models.installed.value[_modelId] != ModelStatus.installed) {
        modelState.value = const SttModelState(SttModelStatus.needsDownload);
        return;
      }
      modelState.value = const SttModelState(SttModelStatus.loading);
      poll = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final p = models.progressOf(_modelId)?.value;
        if (p != null) {
          modelState.value = SttModelState(SttModelStatus.downloading, progress: p.fraction);
        }
      });
      late InstalledModel model;
      for (var attempt = 1;; attempt++) {
        try {
          model = await models.ensure(_modelId); // a dropped connection keeps the bytes, so retries resume
          break;
        } on ModelDownloadException {
          if (attempt == 3) rethrow;
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
      poll.cancel();
      modelState.value = const SttModelState(SttModelStatus.loading);
      final session = await TranscribeSession.open(model);
      session.text.addListener(_onText);
      _session = session;
      modelState.value = const SttModelState(SttModelStatus.ready);
    } catch (e) {
      poll?.cancel();
      modelState.value = SttModelState(SttModelStatus.failed, error: _shorten('$e'));
      rethrow;
    }
  }

  static String _shorten(String s) {
    final t = s.replaceAll(RegExp(r'uri = \S+'), '').trim();
    return t.length > 160 ? '${t.substring(0, 160)}…' : t;
  }

  Future<void> initializeSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception('Microphone permission denied');
    }
    await prepare();
  }

  /// Emits the text of the utterance in progress (replaced as it is refined), then of each finished one.
  Future<void> startContinuousListening({required void Function(String) onResult}) async {
    await prepare();
    final session = _session;
    if (session == null) throw StateError('Speech model is not downloaded yet');
    await _stopping;
    _onResult = onResult;
    _settledSeen = '';
    await session.start();
    _listening = true;
  }

  void _onText() {
    final cb = _onResult;
    if (!_listening || cb == null) return;
    final t = _session!.text.value;
    if (t.settled.length > _settledSeen.length && t.settled.startsWith(_settledSeen)) {
      final finished = t.settled.substring(_settledSeen.length).trim();
      _settledSeen = t.settled;
      if (finished.isNotEmpty) cb(finished);
    } else if (t.interim.isNotEmpty) {
      cb(t.interim);
    }
  }

  void stopListening() {
    _listening = false;
    _onResult = null;
    final s = _session;
    if (s != null) _stopping = s.stop();
  }

  bool get isListening => _listening;
}

final speechRecognitionServiceProvider =
    Provider<SpeechRecognitionService>((ref) {
  return SpeechRecognitionService();
});
