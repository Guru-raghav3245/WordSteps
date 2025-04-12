import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/screens/support_screen.dart';
import 'package:word_app/screens/settings_screen.dart';
import 'package:word_app/screens/home_screen/home_screen.dart';
import 'package:word_app/quiz_history/quiz_history_screen.dart';
import 'package:word_app/theme_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        color: theme.colorScheme.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calculate,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Word Guessing Game',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.home,
              title: 'Home',
              onTap: () => _navigateTo(context, const HomeScreen()),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.history,
              title: 'Quiz History',
              onTap: () => _navigateTo(
                  context,
                  QuizHistoryScreen(
                    () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                      (route) => false,
                    ),
                  )),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.support_agent,
              title: 'Get Support',
              onTap: () => _navigateTo(context, const SupportScreen()),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => _navigateTo(context, const SettingsScreen()),
            ),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: themeMode == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).state =
                    value ? ThemeMode.dark : ThemeMode.light;
              },
              activeColor: Colors.white,
              activeTrackColor: Colors.redAccent,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[700],
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: Colors.white,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: theme.cardTheme.color?.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    if (screen is HomeScreen) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Card(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: theme.cardTheme.color?.withOpacity(0.2) ?? Colors.white10,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: theme.colorScheme.primary.withOpacity(0.4),
            hoverColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
