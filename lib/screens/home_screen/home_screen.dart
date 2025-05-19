import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/screens/practice_screen/practice_screen.dart';
import 'package:word_app/questions/word_generator.dart';
import 'package:word_app/questions/content_type.dart';
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
        title: const Text(
          'WordSteps',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 2,
        shadowColor: theme.shadowColor,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/Icon_HomePage.png', width: 250),
              const SizedBox(height: 20),
              _buildDropdownCard(
                context,
                title: 'Game Mode',
                value: ref.watch(gameModeProvider),
                items: const [
                  DropdownMenuItem(value: 'read', child: Text('Listen Mode')),
                  DropdownMenuItem(
                    value: 'listen',
                    child: Text('Read Mode (Work in Progress)',),
                  ),
                ],
                onChanged: (value) {
                  if (value != null && value != 'listen') {
                    ref.read(gameModeProvider.notifier).state = value;
                  } else if (value == 'listen') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Read Mode is under development and not available yet.',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              _buildDropdownCard<ContentType>(
                context,
                title: 'Content Type',
                value: ref.watch(contentTypeProvider),
                items: [
                  const DropdownMenuItem(
                      value: ContentType.kumon7a,
                      child: Text('7A Sentences')),
                  const DropdownMenuItem(
                      value: ContentType.kumon6a,
                      child: Text('6A Sentences')),
                  const DropdownMenuItem(
                      value: ContentType.kumon5a,
                      child: Text('5A Sentences')),
                  const DropdownMenuItem(
                      value: ContentType.kumon4a,
                      child: Text('4A Sentences')),
                  const DropdownMenuItem(
                      value: ContentType.kumon3a,
                      child: Text('3A Sentences')),
                  const DropdownMenuItem(
                      value: ContentType.kumon2a,
                      child: Text('2A Sentences')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength3,
                      child: Text('3 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength4,
                      child: Text('4 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength5,
                      child: Text('5 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength6,
                      child: Text('6 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength7,
                      child: Text('7 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength8,
                      child: Text('8 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength9,
                      child: Text('9 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength10,
                      child: Text('10 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength11,
                      child: Text('11 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength12,
                      child: Text('12 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength13,
                      child: Text('13 Letter Words')),
                  const DropdownMenuItem(
                      value: ContentType.wordLength14,
                      child: Text('14 Letter Words')),
                ],
                onChanged: (value) {ref.read(contentTypeProvider.notifier).state = value!;}),
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
              ),
              const SizedBox(height: 20),
            ],
          ),
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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: theme.dividerColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<T>(
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: items.map((item) {
                    // Extract the text content from the Text widget
                    final textContent = (item.child as Text).data ?? '';
                    return DropdownMenuItem<T>(
                      value: item.value,
                      child: Text(
                        textContent,
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  style: theme.textTheme.bodyLarge,
                  dropdownColor:
                      theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ));
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
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
