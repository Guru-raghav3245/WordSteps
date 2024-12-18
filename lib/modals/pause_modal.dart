import 'package:flutter/material.dart';

class PauseDialog extends StatelessWidget {
  final VoidCallback onResume; // Callback for resuming the timer

  const PauseDialog({super.key, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Center(
        child: Text(
          'Quiz is Paused',
          style: TextStyle(color: Colors.red),
        ),
      ),
      actions: <Widget>[
        Center(
          child: TextButton(
            onPressed: () {
              //Navigator.pop(context); // Close the dialog
              onResume(); // Call the resume callback
            },
            child: const Text(
              'Resume Quiz',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ),
      ],
    );
  }
}