import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/screens/practice_screen/practice_screen.dart';
import 'settings_screen.dart';
import 'package:word_app/questions/word_generator.dart';

final gameModeProvider = StateProvider<String>((ref) => 'choose');
final wordLengthProvider = StateProvider<int>((ref) => 3);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Guessing Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: ref.watch(gameModeProvider),
              items: [
                DropdownMenuItem(
                  value: 'choose',
                  child: const Text('Choose Mode'),
                ),
                DropdownMenuItem(
                  value: 'speech',
                  child: const Text('Speech Mode'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(gameModeProvider.notifier).state = value;
                }
              },
            ),
            const SizedBox(height: 20),
            DropdownButton<int>(
              value: ref.watch(wordLengthProvider),
              items: [3, 4, 5, 6, 7, 8, 9].map((length) {
                return DropdownMenuItem(
                  value: length,
                  child: Text('$length Letter Words'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(wordLengthProvider.notifier).state = value;
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Reset and initialize game state
                ref.read(wordGameStateProvider.notifier).initializeGame();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PracticeScreen()),
                );
              },
              child: const Text('Start'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
