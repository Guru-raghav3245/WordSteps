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
        backgroundColor: Colors.red,
        title: const Text(
          'Word Guessing Game',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Word Guessing Game!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            _buildDropdownCard(
              context,
              title: 'Game Mode',
              value: ref.watch(gameModeProvider),
              items: const [
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
            _buildDropdownCard(
              context,
              title: 'Word Length',
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
            const SizedBox(height: 40),
            _buildActionButton(
              context,
              label: 'Start Game',
              onPressed: () {
                ref.read(wordGameStateProvider.notifier).initializeGame();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PracticeScreen()),
                );
              },
              gradientColors: [Colors.red, Colors.deepOrange],
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              context,
              label: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
              gradientColors: [Colors.orange, Colors.yellow],
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
