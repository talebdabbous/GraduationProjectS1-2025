import 'package:flutter/material.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Vocabulary'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Vocabulary Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

