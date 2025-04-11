import 'package:flutter/material.dart';

class QuitDialog extends StatelessWidget {
  final VoidCallback onQuit;

  const QuitDialog({super.key, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Rounded corners for a modern look
      ),
      backgroundColor: Colors.white, // Clean and minimal background color
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.warning_amber_rounded, // Warning icon for emphasis
            color: Color(0xFF009DDC), // Kumon blue
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Quit Quiz?',
            style: TextStyle(
              color: Color(0xFF009DDC), // Kumon blue
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to quit? Your progress will be lost.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black87),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly, // Align buttons horizontally
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog
            onQuit(); // Trigger the quit function
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Red for the quit action
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Quit',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog without quitting
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Green for the cancel action
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
