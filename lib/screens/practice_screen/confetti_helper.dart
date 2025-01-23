import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class ConfettiManager {
  late final ConfettiController correctConfettiController;
  late final ConfettiController wrongConfettiController;

  ConfettiManager() {
    correctConfettiController = ConfettiController(duration: const Duration(seconds: 1));
    wrongConfettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  void dispose() {
    correctConfettiController.dispose();
    wrongConfettiController.dispose();
  }

  Widget buildCorrectConfetti() {
    return ConfettiWidget(
      confettiController: correctConfettiController,
      blastDirectionality: BlastDirectionality.explosive,
      blastDirection: -3.14159 / 2,
      numberOfParticles: 100,
      gravity: 1,
      shouldLoop: false,
      emissionFrequency: 0.1,
      particleDrag: 0.01,
      colors: const [Colors.green, Colors.blue, Colors.orange],
    );
  }

  Widget buildWrongConfetti() {
    return ConfettiWidget(
      confettiController: wrongConfettiController,
      blastDirectionality: BlastDirectionality.explosive,
      blastDirection: -3.14159 / 2,
      numberOfParticles: 100,
      gravity: 1,
      shouldLoop: false,
      emissionFrequency: 0.1,
      particleDrag: 0.01,
      colors: [Colors.red, Colors.redAccent[100]!, Colors.red[500]!],
    );
  }
}
