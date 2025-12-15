// File: lib1/screens/practice_screen/read_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../questions/speech_recog.dart';
import '/questions/word_generator.dart';
import 'package:word_app/models/word_game_state.dart';
import 'confetti_helper.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ReadModeScreen extends ConsumerStatefulWidget {
  final int elapsedTime;
  final VoidCallback pauseTimer;
  final VoidCallback resumeTimer;
  final VoidCallback showQuitDialog;
  final VoidCallback endQuiz;
  final int? sessionTimeLimit;

  const ReadModeScreen({
    super.key,
    required this.elapsedTime,
    required this.pauseTimer,
    required this.resumeTimer,
    required this.showQuitDialog,
    required this.endQuiz,
    this.sessionTimeLimit,
  });

  @override
  _ReadModeScreenState createState() => _ReadModeScreenState();
}

class _ReadModeScreenState extends ConsumerState<ReadModeScreen> {
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

  @override
  void initState() {
    super.initState();
    _speechRecognitionService = ref.read(speechRecognitionServiceProvider);
    confettiManager = ConfettiManager();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speechRecognitionService.stopListening();
    confettiManager.dispose();
    _duplicatePreventionTimer?.cancel();
    _debounceTimer?.cancel();
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
      print("Speech recognition initialization failed: $e");
      if (mounted) {
        setState(() {
          _recognizedWord = e.toString().contains('permission')
              ? 'Microphone permission required'
              : 'Speech recognition unavailable';
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Speech Recognition Error'),
            content: Text(
              e.toString().contains('permission')
                  ? 'Please grant microphone permission to use speech recognition.'
                  : 'Speech recognition is not available on this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _startContinuousSpeechRecognition() async {
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

            print('Continuous Recognized: $recognizedWord');

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

      print('Speech recognition exception: $e');

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
    if (_isProcessing ||
        (recognizedWord == _lastProcessedWord &&
            _duplicatePreventionTimer != null)) {
      print('Skipping duplicate processing: $recognizedWord');
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

    print('Normalized Recognized: $normalizedRecognized');
    print('Normalized Correct: $normalizedCorrect');

    double similarity = normalizedRecognized.similarityTo(normalizedCorrect);
    print('Similarity score: $similarity');

    bool isCorrect =
        normalizedRecognized.contains(normalizedCorrect) || similarity > 0.6;

    if (isCorrect) {
      print('Correct answer detected! Moving to next question...');

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
            print('Word changed from $previousWord to ${newState.correctWord}');

            await Future.delayed(Duration(milliseconds: 500));

            if (mounted && isListening) {
              try {
                if (!_speechRecognitionService.isListening) {
                  await _speechRecognitionService.startContinuousListening(
                    localeId: _selectedLocaleId,
                    onResult: (newRecognizedWord) {
                      if (!mounted || _isProcessing) return;

                      print('New Recognized: $newRecognizedWord');

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
      print('Incorrect attempt. Current attempts: $newAttempts');

      if (newAttempts >= 2) {
        confettiManager.wrongConfettiController.play();
      }

      if (newAttempts >= 3) {
        _handleMaxAttemptsReached();
      } else {
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
  }

  void _handleMaxAttemptsReached() {
    print('Maximum attempts reached, moving to next word...');

    if (_speechRecognitionService.isListening) {
      _speechRecognitionService.stopListening();
    }

    setState(() {
      _recognizedWord = 'Maximum attempts reached. Moving to next word...';
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        ref.read(wordGameStateProvider.notifier).handleAnswer('');

        Future.delayed(Duration(milliseconds: 1000), () async {
          if (mounted && isListening) {
            try {
              if (!_speechRecognitionService.isListening) {
                await _speechRecognitionService.startContinuousListening(
                  localeId: _selectedLocaleId,
                  onResult: (recognizedWord) {
                    if (!mounted || _isProcessing) return;

                    print('Continuous Recognized: $recognizedWord');

                    setState(() {
                      _recognizedWord = recognizedWord.isEmpty
                          ? 'Listening...'
                          : recognizedWord;
                    });

                    if (recognizedWord.isNotEmpty &&
                        recognizedWord != 'Listening...' &&
                        !_isProcessing) {
                      _processSpeechResult(recognizedWord);
                    }
                  },
                );
              }
            } catch (e) {
              print('Error restarting speech after max attempts: $e');
            }

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
    _speechRecognitionService.stopListening();
    setState(() {
      isListening = false;
      _recognizedWord = '';
      _isProcessing = false;
    });
  }

  String _formatTime(int seconds) {
    int timeToDisplay = seconds;
    if (widget.sessionTimeLimit != null) {
      timeToDisplay = widget.sessionTimeLimit! - seconds;
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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(theme, wordGameState),
                Expanded(
                  child: Center(
                    child: !wordGameState.isPaused
                        ? _buildSpeechContent(theme, wordGameState)
                        : _buildPausedContent(theme),
                  ),
                ),
                _buildPauseButton(theme, wordGameState),
              ],
            ),
          ),
          _buildConfetti(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      ThemeData theme, WordGameState wordGameState) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Read Mode'),
      centerTitle: true,
      actions: [
        if (_locales.isNotEmpty)
          DropdownButton<String>(
            value: _selectedLocaleId,
            icon: const Icon(Icons.language, color: Colors.white),
            dropdownColor: theme.primaryColor,
            underline: Container(),
            onChanged: (String? newValue) {
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
            items:
                _locales.map<DropdownMenuItem<String>>((stt.LocaleName locale) {
              return DropdownMenuItem<String>(
                value: locale.localeId,
                child: Text(
                  locale.name,
                  style: TextStyle(
                      color: _selectedLocaleId == locale.localeId
                          ? theme.colorScheme.primary
                          : Colors.black),
                ),
              );
            }).toList(),
          ),
        _buildTimerWidget(theme),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildTimerWidget(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatTime(widget.elapsedTime),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: widget.showQuitDialog,
        ),
        IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: widget.endQuiz,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSpeechContent(ThemeData theme, WordGameState wordGameState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeakerButton(theme),
            const SizedBox(height: 20),
            Text(
              'Attempts: ${wordGameState.incorrectAttempts}/3',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            if (!isListening)
              ElevatedButton(
                onPressed: _startContinuousSpeechRecognition,
                child: const Text('Start Continuous Listening'),
              )
            else
              ElevatedButton(
                onPressed: _stopSpeechRecognition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Stop Listening'),
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
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          ref.read(wordGameStateProvider).correctWord,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPausedContent(ThemeData theme) {
    return Center(
      child: Text(
        'Game Paused',
        style: theme.textTheme.headlineMedium,
      ),
    );
  }

  Widget _buildPauseButton(ThemeData theme, WordGameState wordGameState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: FloatingActionButton(
        onPressed: () {
          if (wordGameState.isPaused) {
            widget.resumeTimer();
            ref.read(wordGameStateProvider.notifier).togglePause();
          } else {
            widget.pauseTimer();
            ref.read(wordGameStateProvider.notifier).togglePause();
          }
        },
        backgroundColor:
            wordGameState.isPaused ? Colors.grey : theme.colorScheme.primary,
        child: Icon(
          wordGameState.isPaused ? Icons.play_arrow : Icons.pause,
          size: 48,
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
}
