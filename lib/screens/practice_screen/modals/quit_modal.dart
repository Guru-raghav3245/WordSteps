import 'package:flutter/material.dart';

class QuitDialog extends StatelessWidget {
  final VoidCallback onQuit;

  const QuitDialog({super.key, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white, 
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.warning_amber_rounded, 
            color: Color(0xFF009DDC),
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Quit Quiz?',
            style: TextStyle(
              color: Color(0xFF009DDC),
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
      actionsAlignment: MainAxisAlignment.spaceEvenly, 
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); 
            onQuit(); 
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, 
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
            Navigator.pop(context); 
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, 
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
