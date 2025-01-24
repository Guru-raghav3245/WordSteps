import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/questions/word_generator.dart';
import '/questions/tts_translator.dart';
import 'confetti_helper.dart';

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

class _ListenModeScreenState extends ConsumerState<ListenModeScreen> {
  late final ConfettiManager confettiManager;

  @override
  void initState() {
    super.initState();
    confettiManager = ConfettiManager();
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
    confettiManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordGameState = ref.watch(wordGameStateProvider);
    return Scaffold(
      appBar: _buildAppBar(wordGameState),
      body: _buildBody(wordGameState),
    );
  }

  PreferredSizeWidget _buildAppBar(wordGameStateProviderwordGameState) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text(
        'Listen Mode',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.red.shade600,
      elevation: 0,
      actions: [
        _buildTimerWidget(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildTimerWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          _formatTime(widget.props.elapsedTime),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          iconSize: 28,
          onPressed: widget.props.showQuitDialog,
        ),
        IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          iconSize: 28,
          onPressed: widget.props.endQuiz,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(wordGameStateProviderwordGameState) {
    return Stack(
      children: [
        _buildBackground(),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  if (!wordGameStateProviderwordGameState.isPaused)
                    _buildGameContent(wordGameStateProviderwordGameState)
                  else
                    _buildPausedContent(),
                  const Spacer(),
                  _buildPauseButton(wordGameStateProviderwordGameState),
                ],
              ),
            ),
          ),
        ),
        _buildConfetti(),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade600,
            Colors.red.shade100,
            Colors.white,
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent(wordGameState) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(24),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          _buildSpeakerButton(),
          const SizedBox(height: 50),
          ...wordGameState.options.map((word) => _buildOptionButton(word)),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSpeakerButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: const Icon(Icons.volume_up),
        iconSize: 70,
        color: Colors.red.shade700,
        onPressed: () => _speakWord(ref.read(wordGameStateProvider).correctWord),
      ),
    );
  }

  Widget _buildOptionButton(String word) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: () => _handleWordSelection(word),
        style: _buildOptionButtonStyle(),
        child: Text(
          word,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
      ),
    );
  }

  ButtonStyle _buildOptionButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.red.shade200),
      ),
      minimumSize: const Size(double.infinity, 48),
    );
  }

  Widget _buildPausedContent() {
    return const Center(
      child: Text(
        'Game Paused',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPauseButton( wordGameState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: FloatingActionButton(
        onPressed: wordGameState.isPaused ? null : widget.props.pauseTimer,
        backgroundColor:
            wordGameState.isPaused ? Colors.grey : Colors.red.shade700,
        elevation: 4,
        child: Icon(
          wordGameState.isPaused ? Icons.play_arrow : Icons.pause,
          size: 48,
          color: Colors.white,
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
    } else {
      confettiManager.wrongConfettiController.play();
    }
    
    ref.read(wordGameStateProvider.notifier).handleAnswer(word);
    _speakNextWord();
  }

  void _speakNextWord() {
    Future.delayed(
      const Duration(milliseconds: 0),
      () {
        final word = ref.read(wordGameStateProvider).correctWord;
        if (word.isNotEmpty) {
          _speakWord(word);
        }
      },
    );
  }

  void _speakWord(String word) {
    ref.read(ttsServiceProvider).speak(word, ref);
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}