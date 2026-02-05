// File: lib1/screens/practice_screen/read_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:string_similarity/string_similarity.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_fonts/google_fonts.dart'; // Ensure GoogleFonts is imported
import 'package:word_app/models/word_game_state.dart';
import 'package:word_app/providers/voice_providers.dart';
import 'package:word_app/questions/speech_recog.dart';
import 'package:word_app/screens/practice_screen/practice_screen.dart';
import 'confetti_helper.dart';
import 'package:word_app/questions/word_generator.dart';

class ReadModeScreen extends ConsumerStatefulWidget {
  final GameScreenProps props;

  const ReadModeScreen({
    super.key,
    required this.props,
  });

  @override
  _ReadModeScreenState createState() => _ReadModeScreenState();
}

class _ReadModeScreenState extends ConsumerState<ReadModeScreen>
    with TickerProviderStateMixin {
  bool isListening = false;
  String _recognizedWord = '';
  late final ConfettiManager confettiManager;
  bool _isProcessing = false;
  String _previousWord = '';
  String _lastProcessedWord = '';
  Timer? _duplicatePreventionTimer;

  List<stt.LocaleName> _locales = [];
  String? _selectedLocaleId;

  late SpeechRecognitionService _speechRecognitionService;
  Timer? _debounceTimer;

  // Animation controller for the pulsing microphone
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _speechRecognitionService = ref.read(speechRecognitionServiceProvider);
    confettiManager = ConfettiManager();
    _initializeSpeech();

    // Pulse animation setup
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _speechRecognitionService.stopListening();
    confettiManager.dispose();
    _duplicatePreventionTimer?.cancel();
    _debounceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechRecognitionService.initializeSpeech();
      var locales = await _speechRecognitionService.getLocales();
      if (mounted) {
        setState(() {
          _locales = locales;
          try {
            _selectedLocaleId =
                locales.firstWhere((l) => l.localeId == 'en_US').localeId;
          } catch (e) {
            if (locales.isNotEmpty) {
              _selectedLocaleId = locales.first.localeId;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recognizedWord = 'Mic Error';
        });
      }
    }
  }

  void _startContinuousSpeechRecognition() async {
    widget.props.onUserInteraction();
    try {
      if (!_speechRecognitionService.isListening) {
        setState(() {
          isListening = true;
          _recognizedWord = 'Listening...';
          _isProcessing = false;
          _lastProcessedWord = '';
        });
        _pulseController.repeat(reverse: true); // Start pulsing

        await _speechRecognitionService.startContinuousListening(
          localeId: _selectedLocaleId,
          onResult: (recognizedWord) {
            if (!mounted || _isProcessing) return;
            setState(() {
              _recognizedWord =
                  recognizedWord.isEmpty ? 'Listening...' : recognizedWord;
            });

            if (recognizedWord.isNotEmpty &&
                recognizedWord != 'Listening...' &&
                !_isProcessing) {
              _debounceProcessSpeechResult(recognizedWord);
            }
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isListening = false;
        _pulseController.stop();
        _pulseController.reset();
        _recognizedWord = 'Error';
      });
    }
  }

  void _debounceProcessSpeechResult(String recognizedWord) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _processSpeechResult(recognizedWord);
    });
  }

  void _processSpeechResult(String recognizedWord) {
    widget.props.onUserInteraction();

    if (_isProcessing ||
        (recognizedWord == _lastProcessedWord &&
            _duplicatePreventionTimer != null)) {
      return;
    }

    _isProcessing = true;
    _lastProcessedWord = recognizedWord;

    _duplicatePreventionTimer?.cancel();
    _duplicatePreventionTimer = Timer(Duration(seconds: 2), () {
      _lastProcessedWord = '';
    });

    final currentState = ref.read(wordGameStateProvider);
    final correctWord = currentState.correctWord;

    String normalizedRecognized = recognizedWord
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    String normalizedCorrect = correctWord
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    double similarity = normalizedRecognized.similarityTo(normalizedCorrect);
    bool isCorrect =
        normalizedRecognized.contains(normalizedCorrect) || similarity > 0.6;

    if (isCorrect) {
      _handleCorrectAnswer(correctWord, normalizedRecognized);
    } else {
      _handleIncorrectAnswer(recognizedWord);
    }
  }

  void _handleCorrectAnswer(String previousWord, String recognizedWord) {
    if (_speechRecognitionService.isListening) {
      _speechRecognitionService.stopListening();
    }
    _pulseController.stop();
    _pulseController.reset();

    ref.read(wordGameStateProvider.notifier).handleAnswer(recognizedWord);
    confettiManager.correctConfettiController.play();

    final newState = ref.read(wordGameStateProvider);

    setState(() {
      _recognizedWord = 'Correct!';
    });

    Future.delayed(Duration(milliseconds: 2000), () async {
      if (mounted) {
        if (newState.correctWord != previousWord && isListening) {
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted && isListening) {
            _restartListening();
          }
        }
        setState(() {
          _recognizedWord = 'Listening...';
          _isProcessing = false;
        });
      }
    });
  }

  void _handleIncorrectAnswer(String recognizedWord) {
    ref.read(wordGameStateProvider.notifier).handleAnswer(recognizedWord);

    final newAttempts = ref.read(wordGameStateProvider).incorrectAttempts;

    if (newAttempts >= 2) {
      confettiManager.wrongConfettiController.play();
    }

    if (newAttempts >= 3) {
      _handleMaxAttemptsReached();
    } else {
      setState(() {
        _recognizedWord = 'Try again';
      });

      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          _isProcessing = false;
          setState(() {
            _recognizedWord = 'Listening...';
          });
        }
      });
    }
  }

  Future<void> _restartListening() async {
    try {
      if (!_speechRecognitionService.isListening) {
        _pulseController.repeat(reverse: true);
        await _speechRecognitionService.startContinuousListening(
          localeId: _selectedLocaleId,
          onResult: (newRecognizedWord) {
            if (!mounted || _isProcessing) return;
            setState(() {
              _recognizedWord = newRecognizedWord.isEmpty
                  ? 'Listening...'
                  : newRecognizedWord;
            });
            if (newRecognizedWord.isNotEmpty &&
                newRecognizedWord != 'Listening...' &&
                !_isProcessing) {
              _processSpeechResult(newRecognizedWord);
            }
          },
        );
      }
    } catch (e) {
      print('Error restarting speech: $e');
    }
  }

  void _handleMaxAttemptsReached() {
    if (_speechRecognitionService.isListening) {
      _speechRecognitionService.stopListening();
    }
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _recognizedWord = 'Next word...';
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        ref.read(wordGameStateProvider.notifier).handleAnswer('');

        Future.delayed(Duration(milliseconds: 1000), () async {
          if (mounted && isListening) {
            await _restartListening();
            setState(() {
              _recognizedWord = 'Listening...';
              _isProcessing = false;
            });
          }
        });
      }
    });
  }

  void _stopSpeechRecognition() {
    widget.props.onUserInteraction();
    _speechRecognitionService.stopListening();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      isListening = false;
      _recognizedWord = '';
      _isProcessing = false;
    });
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

    if (wordGameState.correctWord != _previousWord) {
      _previousWord = wordGameState.correctWord;
      _isProcessing = false;
      if (isListening && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _recognizedWord = 'Listening...';
          });
        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM TOP BAR (Replaces AppBar to prevent Overflow) ---
                _buildTopBar(context, theme, wordGameState),

                const Spacer(flex: 1),

                // --- MAIN CONTENT ---
                if (!wordGameState.isPaused)
                  _buildActiveGameContent(theme, wordGameState)
                else
                  _buildPausedContent(theme),

                const Spacer(flex: 2),

                // --- VOLUME CONTROL ---
                _buildVolumeControl(context, ref, theme),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // --- CONFETTI OVERLAY ---
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
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, ThemeData theme, WordGameState wordGameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- Left Side: Timer ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _formatTime(widget.props.elapsedTime),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // --- Right Side: Actions ---
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Language Dropdown (Compact)
                if (_locales.isNotEmpty)
                  Flexible(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLocaleId,
                          icon: Icon(Icons.language,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant),
                          isExpanded: false,
                          onChanged: (String? newValue) {
                            widget.props.onUserInteraction();
                            setState(() {
                              _selectedLocaleId = newValue;
                            });
                            if (isListening) {
                              _stopSpeechRecognition();
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                _startContinuousSpeechRecognition();
                              });
                            }
                          },
                          items: _locales.map<DropdownMenuItem<String>>(
                              (stt.LocaleName locale) {
                            final shortName = locale.localeId.split('_').last;
                            return DropdownMenuItem<String>(
                              value: locale.localeId,
                              child: Text(
                                shortName.isEmpty ? "EN" : shortName,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                // 2. FINISH BUTTON (Added Back)
                // This is the button that takes you to the Result Screen
                IconButton(
                  onPressed: () {
                    widget.props.onUserInteraction();
                    widget.props.endQuiz(); // <--- Navigate to Results
                  },
                  icon: Icon(Icons.check_circle,
                      color: theme.colorScheme.primary),
                  tooltip: 'Finish Quiz',
                ),

                // 3. Pause Button
                IconButton(
                  onPressed: () {
                    widget.props.onUserInteraction();
                    if (wordGameState.isPaused) {
                      widget.props.resumeTimer();
                      ref.read(wordGameStateProvider.notifier).togglePause();
                    } else {
                      widget.props.pauseTimer();
                      ref.read(wordGameStateProvider.notifier).togglePause();
                    }
                  },
                  icon: Icon(
                    wordGameState.isPaused ? Icons.play_arrow : Icons.pause,
                    color: theme.colorScheme.primary,
                  ),
                ),

                // 4. Quit Button (Exits Game)
                IconButton(
                  onPressed: () {
                    widget.props.onUserInteraction();
                    widget.props.showQuitDialog();
                  },
                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGameContent(ThemeData theme, WordGameState wordGameState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Target Word Display
        Text(
          wordGameState.correctWord,
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),
        Text(
          "Read this word aloud",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 40),

        // Large Microphone Button (Replaces Card)
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: isListening
                ? _stopSpeechRecognition
                : _startContinuousSpeechRecognition,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color:
                    isListening ? Colors.redAccent : theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isListening
                            ? Colors.redAccent
                            : theme.colorScheme.primary)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Feedback / Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                isListening ? "Listening..." : "Tap mic to start",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isListening
                      ? Colors.redAccent
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              if (_recognizedWord.isNotEmpty &&
                  _recognizedWord != "Listening...")
                Text(
                  "You said: \"$_recognizedWord\"",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Text(
          'Attempts: ${wordGameState.incorrectAttempts}/3',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildPausedContent(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle_filled,
              size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Game Paused', style: theme.textTheme.headlineMedium),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    final volume = ref.watch(volumeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            volume == 0
                ? Icons.volume_off
                : volume < 0.5
                    ? Icons.volume_down
                    : Icons.volume_up,
            color: theme.colorScheme.primary,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.2),
                thumbColor: theme.colorScheme.primary,
                overlayColor: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  widget.props.onUserInteraction();
                  ref.read(volumeProvider.notifier).state = value;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
