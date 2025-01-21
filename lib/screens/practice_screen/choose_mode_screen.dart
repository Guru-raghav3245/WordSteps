import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../questions/tts_translator.dart';
import '/questions/word_generator.dart';

class ChooseModeScreen extends ConsumerWidget {
  final int elapsedTime;
  final VoidCallback pauseTimer;
  final VoidCallback resumeTimer;
  final VoidCallback showQuitDialog;
  final VoidCallback endQuiz;

  const ChooseModeScreen({
    super.key,
    required this.elapsedTime,
    required this.pauseTimer,
    required this.resumeTimer,
    required this.showQuitDialog,
    required this.endQuiz,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Mode'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '${elapsedTime ~/ 60}:${(elapsedTime % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: showQuitDialog,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: endQuiz,
          ),
        ],
      ),
      body: Stack(
        children: [
          wordGameState.isPaused
              ? const Center(
                  child: Text(
                    'Game Paused',
                    style: TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 64),
                        onPressed: () =>
                            ref.read(ttsServiceProvider).speak(wordGameState.correctWord, ref),
                      ),
                      const SizedBox(height: 50),
                      Column(
                        children: wordGameState.options.map((word) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              onPressed: () => ref.read(wordGameStateProvider.notifier).handleAnswer(word),
                              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                              child: Text(word),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: wordGameState.isPaused ? null : pauseTimer,
              backgroundColor: wordGameState.isPaused ? Colors.grey : null,
              child: const Icon(Icons.pause),
            ),
          ),
        ],
      ),
    );
  }
}
