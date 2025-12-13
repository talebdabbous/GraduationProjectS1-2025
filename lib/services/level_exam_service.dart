import 'dart:convert';
import 'package:http/http.dart' as http;

import '../level_exam/level_question.dart';

class LevelExamService {
  static const String baseUrl = 'http://10.0.2.2:4000'; // emulator

  static Future<List<LevelQuestion>> fetchQuestions() async {
    final url = Uri.parse('$baseUrl/api/placement/questions');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] as List;
      return data.map((e) => LevelQuestion.fromJson(e)).toList();
    }
    throw Exception('Failed to load questions: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> submitAnswers(List<LevelQuestion> questions) async {
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
        'selectedKey': selectedKey,
        'writtenAnswer': q.writtenAnswer, // ✅ مهم للـ writing
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'answers': answers}),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Failed to submit answers: ${response.statusCode}');
  }
}
