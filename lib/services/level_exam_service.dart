import 'dart:convert';
import 'package:http/http.dart' as http;

import '../level_exam/level_question.dart';

class LevelExamService {
  // Emulator base URL
  static const String baseUrl = 'http://10.0.2.2:4000';

  /// ===============================
  /// Fetch Placement Questions
  /// ===============================
  static Future<List<LevelQuestion>> fetchQuestions() async {
    final url = Uri.parse('$baseUrl/api/placement/questions');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load questions: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final List data = body['data'] as List;

    // 🔎 تشخيص أسئلة listening (اختياري)
    for (final item in data) {
      if (item['type'] == 'listening') {
        print(
          '🎧 Listening question detected | '
          'audioUrl=${item['audioUrl']} | mediaUrl=${item['mediaUrl']}',
        );
      }
    }

    // ✅ التحويل إلى Model (الترتيب من الباك كما هو)
    final List<LevelQuestion> questions =
        data.map((e) => LevelQuestion.fromJson(e)).toList();

    // 📋 طباعة ترتيب الأسئلة (آمن بدون substring errors)
    print('📋 Questions order from backend:');
    for (int i = 0; i < questions.length; i++) {
      final text = questions[i].questionTextEN ?? '';
      final preview = text.length > 30 ? text.substring(0, 30) : text;
      print(
        '  ${i + 1}) type=${questions[i].type} text="$preview..."',
      );
    }

    return questions;
  }

  /// ===============================
  /// Submit Answers
  /// ===============================
  static Future<Map<String, dynamic>> submitAnswers(
    List<LevelQuestion> questions,
  ) async {
    final url = Uri.parse('$baseUrl/api/placement/submit');

    final answers = questions.map((q) {
      String? selectedKey;

      if (q.selectedIndex != null &&
          q.selectedIndex! >= 0 &&
          q.selectedIndex! < q.options.length) {
        selectedKey = q.options[q.selectedIndex!].key;
      }

      return {
        'questionId': q.id,
        'type': q.type,
        'selectedKey': selectedKey,       // MCQ / listening / image_mcq
        'writtenAnswer': q.writtenAnswer, // writing
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'answers': answers}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit answers: ${response.statusCode}');
    }

    final body = json.decode(response.body);
    return body['data'] as Map<String, dynamic>;
  }
}
