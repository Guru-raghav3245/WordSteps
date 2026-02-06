import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../questions/speech_recog.dart';
import '/questions/word_generator.dart';
import 'package:word_app/models/word_game_state.dart';
import 'confetti_helper.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:word_app/providers/voice_providers.dart';
import 'practice_screen.dart'; 

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
    with SingleTickerProviderStateMixin {
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

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _speechRecognitionService = ref.read(speechRecognitionServiceProvider);
    confettiManager = ConfettiManager();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _initializeSpeech();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _volume = ref.read(volumeProvider);
    });
  }

  @override
  void dispose() {
    _speechRecognitionService.stopListening();
    confettiManager.dispose();
    _duplicatePreventionTimer?.cancel();
    _debounceTimer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _sendReportEmail() async {
    widget.props.onUserInteraction(); // Accessing via props
    final wordGameState = ref.read(wordGameStateProvider);
    final correctWord = wordGameState.correctWord;

    const String email = 'master.guru.raghav@gmail.com';
    const String subject = 'WordSteps Read Mode Report';
    final String body = 'Reported Word: $correctWord';

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
          _recognizedWord = 'Mic Error: ${e.toString()}';
        });
      }
    }
  }

  void _startContinuousSpeechRecognition() async {
    widget.props.onUserInteraction(); // Accessing via props
    try {
      if (!_speechRecognitionService.isListening) {
        setState(() {
          isListening = true;
          _recognizedWord = 'Listening...';
          _isProcessing = false;
          _lastProcessedWord = '';
        });

        await _speechRecognitionService.startContinuousListening(
          localeId: _selectedLocaleId,
          onResult: (recognizedWord) {
            if (!mounted || _isProcessing) return;

            widget.props.onUserInteraction(); // Reset timer on speech

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
        _recognizedWord = 'Error: ${e.toString()}';
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
    widget.props.onUserInteraction(); // Accessing via props

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

    String normalizedRecognized =
        recognizedWord.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    String normalizedCorrect =
        correctWord.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

    double similarity = normalizedRecognized.similarityTo(normalizedCorrect);
    bool isCorrect =
        normalizedRecognized.contains(normalizedCorrect) || similarity > 0.6;

    if (isCorrect) {
      final previousWord = correctWord;

      if (_speechRecognitionService.isListening) {
        _speechRecognitionService.stopListening();
      }

      ref.read(wordGameStateProvider.notifier).handleAnswer(recognizedWord);
      confettiManager.correctConfettiController.play();

      final newState = ref.read(wordGameStateProvider);

      setState(() {
        _recognizedWord = 'Correct! Next word: ${newState.correctWord}';
      });

      Future.delayed(Duration(milliseconds: 2000), () async {
        if (mounted) {
          if (newState.correctWord != previousWord && isListening) {
            await Future.delayed(Duration(milliseconds: 500));
            if (mounted && isListening) {
              try {
                if (!_speechRecognitionService.isListening) {
                  await _speechRecognitionService.startContinuousListening(
                    localeId: _selectedLocaleId,
                    onResult: (newRecognizedWord) {
                      if (!mounted || _isProcessing) return;
                      widget.props.onUserInteraction();
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
          }
          setState(() {
            _recognizedWord = 'Listening...';
            _isProcessing = false;
          });
        }
      });
    } else {
      ref.read(wordGameStateProvider.notifier).handleAnswer(recognizedWord);
      final newAttempts = ref.read(wordGameStateProvider).incorrectAttempts;

      if (newAttempts >= 2) {
        confettiManager.wrongConfettiController.play();
      }

      setState(() {
        _recognizedWord = 'Try again: $recognizedWord';
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

  void _stopSpeechRecognition() {
    widget.props.onUserInteraction();
    _speechRecognitionService.stopListening();
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
            _recognizedWord = 'Listening for: ${wordGameState.correctWord}';
          });
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Read Mode'),
        centerTitle: false,
        titleSpacing: 16.0,
        backgroundColor: theme.colorScheme.primary,
        actions: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.props.onUserInteraction();
                widget.props.showQuitDialog(); // Accessing via props
              },
              icon: const Icon(Icons.close, size: 20),
              label: const Text('Quit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ScaleTransition(
            scale: _scaleAnimation,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.props.onUserInteraction();
                widget.props.endQuiz(); // Accessing via props
              },
              icon: const Icon(Icons.check, size: 20),
              label: const Text('End'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: 'read_pause_btn',
                            onPressed: () {
                              ref
                                  .read(wordGameStateProvider.notifier)
                                  .togglePause();
                              if (wordGameState.isPaused) {
                                widget.props.resumeTimer();
                              } else {
                                widget.props.pauseTimer();
                              }
                            },
                            backgroundColor: theme.colorScheme.primary,
                            tooltip: 'Pause Game',
                            child: Icon(
                              Icons.pause,
                              size: 36,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              child: Text(
                                _formatTime(widget
                                    .props.elapsedTime), // Accessing via props
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
                            heroTag: 'read_report_btn',
                            onPressed: _sendReportEmail,
                            backgroundColor: theme.colorScheme.primary,
                            tooltip: 'Report Word',
                            child: Icon(
                              Icons.report,
                              size: 36,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_locales.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLocaleId,
                            icon: Icon(Icons.language,
                                size: 20, color: theme.colorScheme.primary),
                            onChanged: (String? newValue) {
                              widget.props.onUserInteraction();
                              setState(() {
                                _selectedLocaleId = newValue;
                              });
                              if (isListening) {
                                _stopSpeechRecognition();
                                Future.delayed(Duration(milliseconds: 500), () {
                                  _startContinuousSpeechRecognition();
                                });
                              }
                            },
                            items: _locales.map<DropdownMenuItem<String>>(
                                (stt.LocaleName locale) {
                              return DropdownMenuItem<String>(
                                value: locale.localeId,
                                child: Text(
                                  locale.name,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    if (!wordGameState.isPaused)
                      Expanded(
                        child: _buildSpeechContent(theme, wordGameState),
                      )
                    else
                      Expanded(
                        child: _buildPausedContent(theme),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.volume_mute,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (value) {
                          setState(() {
                            _volume = value;
                          });
                          ref.read(volumeProvider.notifier).state = value;
                          widget.props.onUserInteraction();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.volume_up,
                        color: theme.colorScheme.primary, size: 20),
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

  Widget _buildSpeechContent(ThemeData theme, WordGameState wordGameState) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSpeakerButton(theme),
            const SizedBox(height: 20),
            Text(
              'Attempts: ${wordGameState.incorrectAttempts}/3',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            if (!isListening)
              ElevatedButton.icon(
                onPressed: _startContinuousSpeechRecognition,
                icon: const Icon(Icons.mic),
                label: const Text('Start Listening'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _stopSpeechRecognition,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Listening'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'You said: $_recognizedWord',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (isListening) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Speak the word above...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerButton(ThemeData theme) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        widget.props.onUserInteraction();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                ref.read(wordGameStateProvider).correctWord,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
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
}
