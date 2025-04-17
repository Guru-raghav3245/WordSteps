import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/questions/word_generator.dart';
import '/questions/tts_translator.dart';
import 'confetti_helper.dart';
import 'package:word_app/models/word_game_state.dart';

class GameScreenProps {
  final int elapsedTime;
  final VoidCallback pauseTimer;
  final VoidCallback resumeTimer;
  final VoidCallback showQuitDialog;
  final VoidCallback endQuiz;

  const GameScreenProps({
    required this.elapsedTime,
    required this.pauseTimer,
    required this.resumeTimer,
    required this.showQuitDialog,
    required this.endQuiz,
  });
}

class ListenModeScreen extends ConsumerStatefulWidget {
  final GameScreenProps props;

  const ListenModeScreen({
    super.key,
    required this.props,
  });

  @override
  ConsumerState<ListenModeScreen> createState() => _ListenModeScreenState();
}

class _ListenModeScreenState extends ConsumerState<ListenModeScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiManager confettiManager;
  bool _isPaused = false;
  bool _isSpeaking = false; // Track TTS speaking state
  bool _canTap = true; // Debounce control
  late AnimationController _scaleController; // For tap animation
  late Animation<double> _scaleAnimation;

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
    _speakInitialWord();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wordGameState = ref.watch(wordGameStateProvider);

    return Scaffold(
      appBar: _buildAppBar(theme, wordGameState),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const Spacer(),
                    if (!_isPaused)
                      _buildGameContent(theme, wordGameState)
                    else
                      _buildPausedContent(theme),
                    const Spacer(),
                    _buildPauseButton(theme),
                  ],
                ),
              ),
            ),
          ),
          _buildConfetti(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, WordGameState wordGameState) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Listen Mode'),
      centerTitle: true,
      actions: [
        _buildTimerWidget(theme),
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildTimerWidget(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatTime(widget.props.elapsedTime),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.exit_to_app, color: theme.colorScheme.onPrimary),
          onPressed: widget.props.showQuitDialog,
          tooltip: 'Quit Game',
        ),
        IconButton(
          icon: Icon(Icons.check_circle_outline, color: theme.colorScheme.onPrimary),
          onPressed: widget.props.endQuiz,
          tooltip: 'End Quiz',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGameContent(ThemeData theme, WordGameState wordGameState) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeakerButton(theme),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: wordGameState.options.map((word) => _buildOptionButton(theme, word)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerButton(ThemeData theme) {
    return Semantics(
      label: 'Speak word',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: _canTap ? () => _handleSpeakTap(theme) : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            elevation: 6, // Add shadow for depth
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)), // Subtle border
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: _isSpeaking
                  ? SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    )
                  : Icon(
                      Icons.volume_up,
                      size: 60,
                      color: theme.colorScheme.primary,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSpeakTap(ThemeData theme) async {
    if (!_canTap) return;
    setState(() {
      _canTap = false;
      _isSpeaking = true;
    });

    final word = ref.read(wordGameStateProvider).correctWord;
    await _speakWord(word);

    // Debounce: Prevent new taps for 1 second after speaking
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _canTap = true;
      });
    }
  }

  Future<void> _speakWord(String word) async {
    try {
      await ref.read(ttsServiceProvider).speak(word, ref);
    } catch (e) {
      // Handle TTS error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error speaking word: $e')),
        );
      }
    }
  }

  Widget _buildOptionButton(ThemeData theme, String word) {
    return SizedBox(
      width: 120,
      child: ElevatedButton(
        onPressed: () => _handleWordSelection(word),
        style: theme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: MaterialStateProperty.all(theme.colorScheme.primary),
          foregroundColor: MaterialStateProperty.all(theme.colorScheme.onPrimary),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        child: Text(
          word,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPausedContent(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Game Paused',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPauseButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isPaused = !_isPaused;
            if (_isPaused) {
              widget.props.pauseTimer();
            } else {
              widget.props.resumeTimer();
            }
          });
        },
        backgroundColor: _isPaused ? Colors.grey : theme.colorScheme.primary,
        child: Icon(
          _isPaused ? Icons.play_arrow : Icons.pause,
          size: 36,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Stack(
      children: [
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: confettiManager.buildCorrectConfetti(),
          ),
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: confettiManager.buildWrongConfetti(),
          ),
        ),
      ],
    );
  }

  void _handleWordSelection(String word) {
    if (word == ref.read(wordGameStateProvider).correctWord) {
      confettiManager.correctConfettiController.play();
    }
    ref.read(wordGameStateProvider.notifier).handleAnswer(word);
    _speakNextWord();
  }

  void _speakNextWord() {
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        final word = ref.read(wordGameStateProvider).correctWord;
        if (word.isNotEmpty) {
          _speakWord(word);
        }
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}