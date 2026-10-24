import 'dart:async';
import 'package:flutter/material.dart';
import 'package:word_app/questions/speech_recog.dart';

/// Read Mode needs the on-device speech model. If it is not on the phone yet, ask before downloading it.
Future<void> offerSpeechModelDownload(
    BuildContext context, SpeechRecognitionService stt) async {
  try {
    await stt.prepare(); // loads the model if present; never downloads without consent
  } catch (_) {}
  if (!context.mounted || stt.modelState.value.status != SttModelStatus.needsDownload) {
    return;
  }
  final agreed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.download),
      title: const Text('Download speech model?'),
      content: const Text(
        'Read Mode listens to you read aloud using a speech model that runs on this phone. '
        'It is a one-time 50 MB download and uses mobile data if you are not on Wi-Fi.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Download')),
      ],
    ),
  );
  if (agreed != true || !context.mounted) return;
  stt.downloadModel().catchError((_) {});
  trackSpeechModelDownload(context, stt);
}

/// Follows a download that has just been started: optionally shows a progress dialog (with a Hide button),
/// and shows a confirmation (or failure) message when it ends, wherever the user has navigated to.
Future<void> trackSpeechModelDownload(
  BuildContext context,
  SpeechRecognitionService stt, {
  bool withDialog = true,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context, rootNavigator: true);
  var dialogOpen = false;
  if (withDialog) {
    dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DownloadProgressDialog(stt),
    ).then((_) => dialogOpen = false);
  }

  final ended = Completer<SttModelState>();
  void check() {
    final s = stt.modelState.value;
    if ((s.status == SttModelStatus.ready || s.status == SttModelStatus.failed) && !ended.isCompleted) {
      ended.complete(s);
    }
  }

  stt.modelState.addListener(check);
  check();
  final result = await ended.future;
  stt.modelState.removeListener(check);

  if (dialogOpen) nav.pop();
  final ok = result.status == SttModelStatus.ready;
  messenger.showSnackBar(SnackBar(
    backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
    duration: const Duration(seconds: 5),
    content: Text(ok
        ? '✅ Speech model downloaded. Read Mode is ready.'
        : 'Download failed: ${result.error ?? 'unknown error'}. Open Read Mode to retry.'),
  ));
}

class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog(this.stt);
  final SpeechRecognitionService stt;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SttModelState>(
      valueListenable: stt.modelState,
      builder: (context, s, _) {
        final downloading = s.status == SttModelStatus.downloading && s.progress != null;
        final label = downloading
            ? '${(s.progress! * 100).toStringAsFixed(0)}%  ·  ${(s.progress! * 50).toStringAsFixed(0)} of 50 MB'
            : 'Preparing…';
        return AlertDialog(
          title: const Text('Downloading speech model'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: downloading ? s.progress : null),
              const SizedBox(height: 12),
              Text(label),
              const SizedBox(height: 8),
              const Text('Keep the screen on until it finishes.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hide'),
            ),
          ],
        );
      },
    );
  }
}
