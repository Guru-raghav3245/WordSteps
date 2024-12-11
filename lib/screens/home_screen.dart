import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'practice_screen/practice_screen.dart';

// New provider to manage game mode
final gameModeProvider = StateProvider<String>((ref) => 'choose');
final wordLengthProvider = StateProvider<int>((ref) => 3);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Guessing Game'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game Mode Dropdown
            DropdownButton<String>(
              value: ref.watch(gameModeProvider),
              hint: const Text('Select Game Mode'),
              items: [
                DropdownMenuItem(
                  value: 'choose',
                  child: Text('Choose Mode'),
                ),
                DropdownMenuItem(
                  value: 'speech',
                  child: Text('Speech Mode'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(gameModeProvider.notifier).state = value;
                }
              },
            ),
            const SizedBox(height: 20),
            // Word Length Dropdown
            DropdownButton<int>(
              value: ref.watch(wordLengthProvider),
              hint: const Text('Select Word Length'),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PracticeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}