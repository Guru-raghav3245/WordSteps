import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/screens/home_screen/home_screen.dart';
import 'package:word_app/providers/theme_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate initialization (e.g., loading prefs, checking version)
    // Later, you can add your BillingService init here.
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _initialized = true;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the current theme to ensure the splash screen matches the user's preference
    final themeMode = ref.watch(themeModeProvider);
    final theme = themeMode == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
    
    // Determine background color based on theme
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(primaryColor),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _initialized ? 'Ready!' : 'Loading WordSteps...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(Color primaryColor) {
    return Image.asset(
      'assets/Icon_HomePage.png', // Using the existing asset from your Home Screen
      height: 120,
      width: 120,
      errorBuilder: (context, error, stackTrace) {
        // Fallback icon if asset is missing
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.menu_book_rounded, // Book icon for English app
            size: 60,
            color: primaryColor,
          ),
        );
      },
    );
  }
}