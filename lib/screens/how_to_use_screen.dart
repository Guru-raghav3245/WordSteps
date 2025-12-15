// File: lib1/screens/how_to_use_screen.dart
import 'package:flutter/material.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 800 : 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildIntro(context),
              const SizedBox(height: 24),
              _buildStep(
                context,
                "1. Select Game Mode",
                "Choose 'Listen Mode' to practice your listening skills or 'Read Mode' to practice speaking and pronunciation.",
                Icons.headphones,
              ),
              _buildStep(
                context,
                "2. Choose Content Type",
                "Select what you want to practice, such as '3 Letter Words', '4 Letter Words', or complete sentences like '7A Sentences'.",
                Icons.menu_book,
              ),
              _buildStep(
                context,
                "3. Set Time Limit (Optional)",
                "Tap the timer card to set a duration for your session, or select 'No time limit' to practice as long as you like.",
                Icons.timer,
              ),
              _buildStep(
                context,
                "4. Start Practicing",
                "Tap 'Start Game'. In Listen Mode, hear the word and tap the matching option. In Read Mode, speak the word displayed on screen.",
                Icons.play_circle_fill,
              ),
              _buildStep(
                context,
                "5. Review Progress",
                "After the quiz, check your score. You can also visit 'Wrong Words' in the menu to review mistakes.",
                Icons.history_edu,
              ),
              const SizedBox(height: 24),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.school, color: theme.colorScheme.primary, size: 36),
        const SizedBox(width: 12),
        Text(
          "Get Started!",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "WordSteps helps you master reading and vocabulary through fun, interactive audio exercises. Follow these steps to begin!",
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
      BuildContext context, String title, String description, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Practice daily to build your vocabulary!",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
