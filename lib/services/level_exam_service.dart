import 'dart:convert';
import 'package:http/http.dart' as http;
import '../level_exam/level_question.dart';

class LevelExamService {
  // لأنك على الإيموليتر → لازم 10.0.2.2 بدل localhost
  static const String baseUrl = 'http://10.0.2.2:4000';

  static Future<List<LevelQuestion>> fetchQuestions() async {
    final url = Uri.parse('$baseUrl/api/placement/questions');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final List list = jsonBody['data'];
      return list.map((e) => LevelQuestion.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load questions: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> submitAnswers(
      List<LevelQuestion> questions) async {
    final url = Uri.parse('$baseUrl/api/placement/submit');

    final answers = questions.map((q) {
      final selected = q.selectedIndex;
      final selectedKey =
          selected != null ? q.options[selected].key : null;

      return {
        'questionId': q.id,
        'selectedKey': selectedKey,
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'answers': answers}),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return jsonBody['data'];
    } else {
      throw Exception('Failed to submit answers: ${response.statusCode}');
    }
  }
}
