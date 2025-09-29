import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_app/questions/tts_translator.dart';

final volumeProvider = StateProvider<double>((ref) => 1.0);
final pitchProvider = StateProvider<double>((ref) => 1.0);
final speechRateProvider = StateProvider<double>((ref) => 0.5);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final volume = ref.watch(volumeProvider);
    final pitch = ref.watch(pitchProvider);
    final speechRate = ref.watch(speechRateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_voice,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Voice Configuration',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSlider(
                      context,
                      label: 'Volume',
                      value: volume,
                      icon: Icons.volume_up,
                      onChanged: (value) =>
                          ref.read(volumeProvider.notifier).state = value,
                    ),
                    const SizedBox(height: 28),
                    _buildSlider(
                      context,
                      label: 'Pitch',
                      value: pitch,
                      icon: Icons.tune,
                      onChanged: (value) =>
                          ref.read(pitchProvider.notifier).state = value,
                    ),
                    const SizedBox(height: 28),
                    _buildSlider(
                      context,
                      label: 'Speech Rate',
                      value: speechRate,
                      icon: Icons.speed,
                      onChanged: (value) =>
                          ref.read(speechRateProvider.notifier).state = value,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mic,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Test Voice Settings',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final ttsService = ref.read(ttsServiceProvider);
                          ttsService.speak(
                              'This is a sample of the voice settings', ref);
                        },
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('Test Voice'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              value.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: value,
          min: 0.0,
          max: 1.5,
          divisions: 20,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
          inactiveColor: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ],
    );
  }
}