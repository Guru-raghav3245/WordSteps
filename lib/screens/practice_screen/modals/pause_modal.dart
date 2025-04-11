import 'package:flutter/material.dart';

class PauseDialog extends StatelessWidget {
  final VoidCallback onResume; // Callback for resuming the timer

  const PauseDialog({super.key, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Rounded corners for the dialog
      ),
      backgroundColor: Colors.black.withOpacity(0.8), // Slight opacity for a softer background
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.pause_circle_filled, // Add a pause icon for visual context
            color: Colors.red,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Quiz is Paused',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: const Text(
        'You can resume your quiz anytime.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
              onResume(); // Call the resume callback
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Resume Quiz',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
