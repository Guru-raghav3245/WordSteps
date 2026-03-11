// File: lib/screens/home_screen/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:word_app/screens/practice_screen/practice_screen.dart';
import 'package:word_app/questions/word_generator.dart';
import 'package:word_app/screens/home_screen/dropdown_widgets.dart';
import 'drawer.dart';
import 'timer_wheel_picker.dart';

final gameModeProvider = StateProvider<String>((ref) => 'read');
final wordLengthProvider = StateProvider<int>((ref) => 3);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedTimeLimit;
  int _selectedIndex = 0; // 0 = No Limit

  void _showTimeWheelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TimeWheelPicker(
          initialIndex: _selectedIndex,
          onConfirm: (index) {
            setState(() {
              _selectedIndex = index;
              if (_selectedIndex == 0) {
                _selectedTimeLimit = null;
              } else {
                _selectedTimeLimit = _selectedIndex * 60;
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 30),

              // Game Mode Dropdown
              GameModeDropdown(
                selectedMode: ref.watch(gameModeProvider),
                onChanged: (value) {
                  ref.read(gameModeProvider.notifier).state = value;
                },
              ),

              const SizedBox(height: 16),

              // Content Type Dropdown
              ContentTypeDropdown(
                selectedType: ref.watch(contentTypeProvider),
                onChanged: (value) {
                  ref.read(contentTypeProvider.notifier).state = value;
                },
              ),

              const SizedBox(height: 16),

              // Timer Card
              _buildTimerCard(context),

              const SizedBox(height: 40),

              // START GAME BUTTON (with wrong answer loading)
              _buildActionButton(
                context,
                label: 'Start Game',
                onPressed: () async {
                  // ←←← THIS IS THE ONLY CHANGE NEEDED
                  await ref.read(wordGameStateProvider.notifier).initializeGame();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PracticeScreen(
                        sessionTimeLimit: _selectedTimeLimit,
                      ),
                    ),
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

  Widget _buildTimerCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTimeWheelPicker(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Time Limit',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTimeLimit == null
                          ? 'No time limit'
                          : '${_selectedTimeLimit! ~/ 60} minute${_selectedTimeLimit! ~/ 60 == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          ),
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
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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