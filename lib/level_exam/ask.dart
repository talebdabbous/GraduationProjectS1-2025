import 'package:flutter/material.dart';


class StartLevelPage extends StatelessWidget {
  const StartLevelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Welcome to Your Arabic Journey!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1D3557)),
              ),
              const SizedBox(height: 16),
              const Text(
                "Would you like to take a quick placement test\nor start learning from the beginning?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text("Take Placement Test"),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text("Start from Zero"),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text("Skip for now")),
            ],
          ),
        ),
      ),
    );
  }
}
