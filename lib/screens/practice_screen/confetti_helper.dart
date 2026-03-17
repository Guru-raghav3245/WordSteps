// lib/screens/practice_screen/confetti_helper.dart
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class ConfettiManager {
  late final ConfettiController correctConfettiController;
  late final ConfettiController wrongConfettiController;

  // Buzzer-style Red X (white circle + red X)
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

    // Safe elastic pop
    scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: wrongXController,
        curve: Curves.elasticOut,
      ),
    );

    // Buzzer shake (talk-show slam)
    rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.26), weight: 8),
      TweenSequenceItem(tween: Tween(begin: -0.26, end: 0.26), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.26, end: -0.16), weight: 12),
      TweenSequenceItem(tween: Tween(begin: -0.16, end: 0.16), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 0.16, end: 0.0), weight: 53),
    ]).animate(wrongXController);

    // Fade-in → hold → fade-out
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
    wrongConfettiController.play();
  }

  // === BIG BOLD BUZZER: WHITE CIRCLE + RED X ===
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
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 60,
                      color: Colors.black54,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      blurRadius: 90,
                      color: const Color(0xFFFF5252).withOpacity(0.6),
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 190,                    // thick red X inside white circle
                  color: Color(0xFFE53935),
                ),
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