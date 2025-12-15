// File: lib1/screens/faq_screen.dart
import 'package:flutter/material.dart';

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FAQItem> _filteredFAQs = [];

  final List<FAQItem> _allFAQs = [
    FAQItem(
      question: "What is WordSteps?",
      answer:
          "WordSteps is an educational app designed to help improve reading, pronunciation, and vocabulary skills through interactive listening and speaking exercises.",
    ),
    FAQItem(
      question: "How does 'Listen Mode' work?",
      answer:
          "In Listen Mode, the app speaks a word aloud. You must listen carefully and select the matching written word from the options provided on the screen.",
    ),
    FAQItem(
      question: "How does 'Read Mode' work?",
      answer:
          "In Read Mode, a word or sentence is displayed on the screen. Press the microphone button and read it aloud. The app uses speech recognition to check your pronunciation.",
    ),
    FAQItem(
      question: "Can I use the app offline?",
      answer:
          "Yes! The core features work offline. However, 'Read Mode' relies on your device's speech recognition, which might require an internet connection on some devices.",
    ),
    FAQItem(
      question: "How do I change the difficulty?",
      answer:
          "On the Home Screen, use the 'Content Type' dropdown to switch between different word lengths (e.g., 3-letter words) or sentence complexity (e.g., 7A Sentences).",
    ),
    FAQItem(
      question: "Does the app save my progress?",
      answer:
          "Yes, your quiz results are saved automatically. You can view your past performance in the 'Quiz History' section accessible from the drawer menu.",
    ),
    FAQItem(
      question: "What is the 'Session Time Limit'?",
      answer:
          "You can set a timer on the Home Screen (e.g., 5 or 10 minutes) to limit your practice session. If set to 'No Limit', the session continues until you choose to end it.",
    ),
    FAQItem(
      question: "How do I review words I got wrong?",
      answer:
          "Go to 'Wrong Words' in the drawer menu. This list saves words you missed so you can practice them again.",
    ),
    FAQItem(
      question: "Can I switch to Dark Mode?",
      answer:
          "Yes, open the drawer menu (top left icon) and toggle the 'Dark Mode' switch.",
    ),
    FAQItem(
      question: "How do I report a problem?",
      answer:
          "You can use the 'Support' option in the drawer menu to send us an email with details about the issue.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFAQs = _allFAQs;
    _searchController.addListener(_filterFAQs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterFAQs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFAQs = _allFAQs.where((faq) {
        return faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("WordSteps FAQ"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search FAQs...",
                prefixIcon:
                    Icon(Icons.search, color: theme.colorScheme.primary),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: theme.colorScheme.primary),
                  onPressed: () {
                    _searchController.clear();
                    _filterFAQs();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredFAQs.isEmpty
                ? Center(
                    child: Text(
                      "No results found.",
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredFAQs.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.question_answer,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            _filteredFAQs[index].question,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _filteredFAQs[index].answer,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToTop,
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }
}
