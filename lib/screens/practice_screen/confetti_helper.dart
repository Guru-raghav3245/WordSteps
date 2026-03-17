// lib/screens/practice_screen/confetti_helper.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class ConfettiManager {
  late final ConfettiController correctConfettiController;
  late final ConfettiController wrongConfettiController;

  // Buzzer-style Red X (big, bold, 1-second dramatic shake)
  late final AnimationController wrongXController;
  late final Animation<double> scaleAnimation;
  late final Animation<double> rotationAnimation;
  late final Animation<double> fadeAnimation;

  ConfettiManager(TickerProvider vsync) {
    correctConfettiController = ConfettiController(duration: const Duration(seconds: 1));
    wrongConfettiController = ConfettiController(duration: const Duration(seconds: 1));

    wrongXController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000), // exactly 1 second
    );

    // Bonus version: simple tween + elasticOut (safe, no assertion crash)
    scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: wrongXController,
        curve: Curves.elasticOut, // big bouncy pop
      ),
    );

    // Buzzer shake (quick left-right wobble like a talk-show buzzer)
    rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.26), weight: 8),   // hard left
      TweenSequenceItem(tween: Tween(begin: -0.26, end: 0.26), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.26, end: -0.16), weight: 12),
      TweenSequenceItem(tween: Tween(begin: -0.16, end: 0.16), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 0.16, end: 0.0), weight: 53),   // settle
    ]).animate(wrongXController);

    // Quick fade-in → hold → fade-out (prominent for full 1 second)
    fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(wrongXController);
  }

  void dispose() {
    correctConfettiController.dispose();
    wrongConfettiController.dispose();
    wrongXController.dispose();
  }

  void playWrongAnimation() {
    wrongXController.reset();
    wrongXController.forward();
    wrongConfettiController.play(); // ← red confetti now triggers too
  }

  // === BIG BOLD BUZZER RED X ===
  Widget buildWrongX() {
    return AnimatedBuilder(
      animation: wrongXController,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Transform.rotate(
              angle: rotationAnimation.value,
              child: const Icon(
                Icons.cancel_rounded,          // bolder look than close_rounded
                size: 240,                     // huge & attention-grabbing
                color: Color(0xFFE53935),
                shadows: [
                  Shadow(
                    blurRadius: 50,
                    color: Colors.black54,
                    offset: Offset(0, 15),
                  ),
                  Shadow(
                    blurRadius: 80,
                    color: Color(0xFFFF5252),
                    offset: Offset(0, 0),
                  ),
                  Shadow(
                    blurRadius: 120,
                    color: Colors.redAccent,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
}