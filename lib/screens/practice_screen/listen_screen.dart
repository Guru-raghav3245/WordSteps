// File: lib/screens/practice_screen/listen_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/questions/word_generator.dart';
import '/questions/tts_translator.dart';
import 'confetti_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:word_app/screens/practice_screen/practice_screen.dart';

class ListenModeScreen extends ConsumerStatefulWidget {
  final GameScreenProps props;

  const ListenModeScreen({super.key, required this.props});

  @override
  ConsumerState<ListenModeScreen> createState() => _ListenModeScreenState();
}

class _ListenModeScreenState extends ConsumerState<ListenModeScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiManager confettiManager;
  bool _isSpeaking = false;
  bool _canTap = true;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  double _volume = 1.0;

  DateTime? _lastVolumeChange;
  static const _volumeDebounceMs = 400;

  @override
  void initState() {
    super.initState();
    confettiManager = ConfettiManager();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakInitialWord();
      _volume = ref.read(ttsServiceProvider).volume;
    });
  }

  void _speakInitialWord() {
    final word = ref.read(wordGameStateProvider).correctWord;
    if (word.isNotEmpty) {
      ref.read(ttsServiceProvider).speak(word, ref);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    confettiManager.dispose();
    super.dispose();
  }

  Future<void> _sendReportEmail() async {
    widget.props.onUserInteraction();
    final wordGameState = ref.read(wordGameStateProvider);
    final options = wordGameState.options;
    final correctWord = wordGameState.correctWord;

    const String email = 'master.guru.raghav@gmail.com';
    const String subject = 'WordSteps Listen Mode Report';
    final String body =
        'Reported Word: $correctWord\nOptions:\n${options.map((option) => '- $option').join('\n')}';

    final String gmailUrl =
        'googlegmail:///mail/?to=$email&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    final String fallbackUrl =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    try {
      if (await canLaunchUrl(Uri.parse(gmailUrl))) {
        await launchUrl(Uri.parse(gmailUrl));
      } else {
        await launchUrl(Uri.parse(fallbackUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Unable to open email client. Please try again or use master.guru.raghav@gmail.com manually.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleSpeakTap(ThemeData theme) async {
    widget.props.onUserInteraction();
    if (!_canTap) return;
    setState(() {
      _canTap = false;
      _isSpeaking = true;
    });

    final word = ref.read(wordGameStateProvider).correctWord;
    try {
      await ref.read(ttsServiceProvider).speak(word, ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error speaking word: $e')),
        );
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _canTap = true;
      });
    }
  }

  void _handleWordSelection(String selectedWord) {
    widget.props.onUserInteraction();
    final correctWord = ref.read(wordGameStateProvider).correctWord;

    if (selectedWord == correctWord) {
      confettiManager.correctConfettiController.play();
    } else {
      confettiManager.wrongConfettiController.play();
    }
    ref.read(wordGameStateProvider.notifier).handleAnswer(selectedWord);
    _speakNextWord();
  }

  void _speakNextWord() {
    final word = ref.read(wordGameStateProvider).correctWord;
    if (word.isNotEmpty) {
      ref.read(ttsServiceProvider).speak(word, ref);
    }
  }

  String _formatTime(int seconds) {
    int timeToDisplay = seconds;
    if (widget.props.sessionTimeLimit != null) {
      timeToDisplay = widget.props.sessionTimeLimit! - seconds;
      if (timeToDisplay < 0) timeToDisplay = 0;
    }
    int minutes = timeToDisplay ~/ 60;
    int remainingSeconds = timeToDisplay % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Listen Mode'),
        centerTitle: false,
        titleSpacing: 16.0,
        backgroundColor: theme.colorScheme.primary,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              widget.props.onUserInteraction();
              widget.props.showQuitDialog();
            },
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Quit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              widget.props.onUserInteraction();
              widget.props.endQuiz();
            },
            icon: const Icon(Icons.check, size: 20),
            label: const Text('End'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: 'listen_pause_btn',
                            onPressed: () {
                              widget.props.onUserInteraction();
                              ref.read(wordGameStateProvider.notifier).togglePause();
                              if (wordGameState.isPaused) {
                                widget.props.resumeTimer();
                              } else {
                                widget.props.pauseTimer();
                              }
                            },
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(Icons.pause, size: 36, color: theme.colorScheme.onPrimary),
                          ),
                          const SizedBox(width: 16),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Text(
                                _formatTime(widget.props.elapsedTime),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FloatingActionButton(
                            heroTag: 'listen_report_btn',
                            onPressed: _sendReportEmail,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(Icons.report, size: 36, color: theme.colorScheme.onPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _canTap ? () => _handleSpeakTap(theme) : null,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    child: _isSpeaking
                                        ? const SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: CircularProgressIndicator(strokeWidth: 4),
                                          )
                                        : Icon(Icons.volume_up, size: 60, color: theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: wordGameState.options.map((word) {
                                return SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  child: ElevatedButton(
                                    onPressed: () => _handleWordSelection(word),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                      minimumSize: const Size(0, 60),
                                    ),
                                    child: Text(
                                      word,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // ==================== WAQ BADGE (from Math app) ====================
          if (wordGameState.isWAQ)
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Previous Wrong Answer',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          // =================================================================

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.volume_mute, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (value) {
                          final now = DateTime.now();
                          if (_lastVolumeChange != null &&
                              now.difference(_lastVolumeChange!).inMilliseconds < _volumeDebounceMs) {
                            return;
                          }
                          _lastVolumeChange = now;
                          setState(() => _volume = value);
                          ref.read(ttsServiceProvider).setVolume(value);
                          widget.props.onUserInteraction();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.volume_up, color: theme.colorScheme.primary, size: 20),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(child: confettiManager.buildCorrectConfetti()),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(child: confettiManager.buildWrongConfetti()),
          ),
        ],
      ),
    );
  }
}