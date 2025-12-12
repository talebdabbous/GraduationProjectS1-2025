import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import 'level_question.dart';
import '../services/level_exam_service.dart';
import '../services/auth_service.dart';

class LevelExamScreen extends StatefulWidget {
  const LevelExamScreen({super.key});

  @override
  State<LevelExamScreen> createState() => _LevelExamScreenState();
}

class _LevelExamScreenState extends State<LevelExamScreen> {
  late Future<List<LevelQuestion>> _futureQuestions;
  bool _submitting = false;
  int _currentIndex = 0; // السؤال الحالي

  final AudioPlayer _audioPlayer = AudioPlayer(); // للصوت

  @override
  void initState() {
    super.initState();
    _futureQuestions = LevelExamService.fetchQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play audio')),
      );
    }
  }

  String _mapLevelCodeToLabel(String code) {
    switch (code) {
      case 'A2':
        return 'Elementary A2';
      case 'B1':
        return 'Intermediate B1';
      case 'A1':
      default:
        return 'Beginner A1';
    }
  }

  Future<void> _submit(List<LevelQuestion> questions) async {
    setState(() => _submitting = true);
    try {
      final result = await LevelExamService.submitAnswers(questions);

      final levelCode = result['level'] as String; // A1/A2/B1
      final percentage = (result['percentage'] as num).toDouble();
      final prettyLevel = _mapLevelCodeToLabel(levelCode);

      final prefs = await SharedPreferences.getInstance();

      // ✅ المفتاح الصحيح (بدل completed_level_exam)
      await prefs.setBool('completedLevelExam', true);
      await prefs.setString('user_level', prettyLevel);

      // (اختياري) امسح المفتاح القديم لو كان موجود
      await prefs.remove('completed_level_exam');

      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        try {
          await AuthService.updateMe(
            token: token,
            level: prettyLevel,
            completedLevelExam: true,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _submitting = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Your Level'),
          content: Text(
            'Level: $prettyLevel\n'
            'Score: ${percentage.toStringAsFixed(1)}%',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/home_screen');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting test: $e')),
      );
    }
  }

  void _goNext(List<LevelQuestion> questions) {
    final currentQuestion = questions[_currentIndex];

    if (currentQuestion.selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an answer first')),
      );
      return;
    }

    final isLast = _currentIndex == questions.length - 1;

    if (isLast) {
      _submit(questions);
    } else {
      setState(() {
        _currentIndex += 1;
      });
    }
  }

  void _goPrevious() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex -= 1;
    });
  }

  Color _backgroundColor() => const Color(0xFFE6F4FF);
  Color _primaryColor() => const Color(0xFF0EA5E9);

  Color _badgeColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFACC15);
      case 1:
        return const Color(0xFF38BDF8);
      case 2:
        return const Color(0xFFA855F7);
      case 3:
      default:
        return const Color(0xFF34D399);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor(),
      appBar: AppBar(
        backgroundColor: _backgroundColor(),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Placement Test',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<LevelQuestion>>(
          future: _futureQuestions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Failed to load questions'));
            }

            final questions = snapshot.data!;
            if (questions.isEmpty) {
              return const Center(child: Text('No questions available.'));
            }

            final total = questions.length;
            final q = questions[_currentIndex];
            final isLast = _currentIndex == total - 1;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of $total',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${((_currentIndex + 1) / total * 100).round()}%',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / total,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_primaryColor()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    height: 190,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (q.type == 'listening' &&
                            q.mediaUrl != null &&
                            q.mediaUrl!.isNotEmpty)
                          Column(
                            children: [
                              IconButton(
                                iconSize: 32,
                                onPressed: () => _playAudio(q.mediaUrl!),
                                icon: const Icon(Icons.volume_up_rounded),
                                color: _primaryColor(),
                              ),
                              const Text(
                                'Tap to listen',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        Text(
                          q.questionTextEN,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: q.options.length,
                      itemBuilder: (context, optIndex) {
                        final opt = q.options[optIndex];
                        final selected = q.selectedIndex == optIndex;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              setState(() {
                                q.selectedIndex = optIndex;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: selected
                                      ? _primaryColor()
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _badgeColor(optIndex),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      opt.key.toLowerCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      opt.text,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            foregroundColor: Colors.grey.shade800,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed:
                              _currentIndex == 0 ? null : () => _goPrevious(),
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor(),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: _submitting
                              ? null
                              : () => _goNext(questions),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isLast ? 'Submit Test' : 'Next'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
