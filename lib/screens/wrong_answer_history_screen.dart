import 'package:flutter/material.dart';
import 'package:word_app/quiz_history/wrong_answer_service.dart';

class WrongAnswersScreen extends StatefulWidget {
  const WrongAnswersScreen({super.key});

  @override
  State<WrongAnswersScreen> createState() => _WrongAnswersScreenState();
}

class _WrongAnswersScreenState extends State<WrongAnswersScreen> {
  final WrongAnswerService _service = WrongAnswerService();
  List<WrongAnswer> _mistakes = [];

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  void _loadMistakes() async {
    final data = await _service.getWrongAnswers();
    setState(() => _mistakes = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mistakes to Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _service.clearAll().then((_) => _loadMistakes()),
          )
        ],
      ),
      body: _mistakes.isEmpty
          ? const Center(child: Text('No mistakes yet! Keep practicing.'))
          : ListView.builder(
              itemCount: _mistakes.length,
              itemBuilder: (context, index) {
                final item = _mistakes[index];
                return Dismissible(
                  key: Key(item.timestamp.toString()),
                  onDismissed: (_) => _service.deleteMistake(index),
                  background: Container(color: Colors.red, child: const Icon(Icons.delete)),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(item.question, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Your guess: ${item.userAnswer}\nMastery: ${item.correctCount}/3'),
                      trailing: Text(item.category),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            ),
    );
  }
}