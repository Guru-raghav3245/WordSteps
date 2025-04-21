import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/screens/practice_screen/practice_screen.dart';
import 'package:word_app/questions/word_generator.dart';
import 'drawer.dart';

final gameModeProvider = StateProvider<String>((ref) => 'read');
final wordLengthProvider = StateProvider<int>((ref) => 3);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Guessing Game'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to the Word Guessing Game!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            _buildDropdownCard(
              context,
              title: 'Game Mode',
              value: ref.watch(gameModeProvider),
              items: const [
                DropdownMenuItem(value: 'read', child: Text('Listen Mode')),
                DropdownMenuItem(value: 'listen', child: Text('Read Mode')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(gameModeProvider.notifier).state = value;
                }
              },
            ),
            const SizedBox(height: 20),
            _buildDropdownCard<String>(
              context,
              title: 'Content Type',
              value: ref.watch(contentTypeProvider),
              items: [
                const DropdownMenuItem(value: '7a', child: Text('7A Sentences')),
                const DropdownMenuItem(value: '6a', child: Text('6A Sentences')),
                const DropdownMenuItem(value: '5a', child: Text('5A Sentences')),
                const DropdownMenuItem(value: '4a', child: Text('4A Sentences')),
                const DropdownMenuItem(value: '3a', child: Text('3A Sentences')),
                const DropdownMenuItem(value: '2a', child: Text('2A Sentences')),
                ...['3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14']
                    .map((length) => DropdownMenuItem<String>(
                          value: length,
                          child: Text('$length Letter Words'),
                        ))
                    .toList(),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(contentTypeProvider.notifier).state = value;
                }
              },
            ),
            const SizedBox(height: 40),
            _buildActionButton(
              context,
              label: 'Start Game',
              onPressed: () {
                ref.read(wordGameStateProvider.notifier).initializeGame();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PracticeScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownCard<T>(
    BuildContext context, {
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            DropdownButton<T>(
              value: value,
              underline: const SizedBox(),
              items: items,
              onChanged: onChanged,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: ElevatedButton(
        onPressed: onPressed,
        style: theme.elevatedButtonTheme.style,
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}