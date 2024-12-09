import 'package:flutter/material.dart';

class QuitDialog extends StatelessWidget {
  final VoidCallback onQuit;

  const QuitDialog({super.key, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Do you want to quit the quiz?',
        style: TextStyle(color: Color(0xFF009DDC)), // Kumon blue
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog
            onQuit(); // Trigger the quit function to switch to start screen
          },
          child: const Text(
            'Quit',
            style: TextStyle(color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog without quitting
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }
}