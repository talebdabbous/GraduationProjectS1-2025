import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JourneyOption {
  final String key;
  final String text;

  // ✅ دعم صوت لكل خيار (اختياري)
  final String? audioUrl;

  JourneyOption({
    required this.key,
    required this.text,
    this.audioUrl,
  });

  factory JourneyOption.fromJson(Map<String, dynamic> json) {
    // ✅ محاولة قراءة text من عدة أسماء محتملة
    final key = json['key']?.toString() ?? '';
    String text = json['text']?.toString() ?? 
                   json['optionText']?.toString() ?? 
                   json['label']?.toString() ?? 
                   json['value']?.toString() ?? 
                   '';
    final audioUrl = json['audioUrl']?.toString();
    
    // ✅ Debug: طباعة البيانات للتحقق
    print('📋 JourneyOption: key="$key", text="$text", text.isEmpty=${text.isEmpty}');
    if (text.isEmpty) {
      print('⚠️ WARNING: Option text is empty! JSON keys: ${json.keys.toList()}');
      print('⚠️ Full JSON: $json');
    }
    
    return JourneyOption(
      key: key,
      text: text,
      audioUrl: audioUrl,
    );
  }
}

class JourneyQuestion {
  final String id;
  final String type;
  final String prompt;
  final List<JourneyOption> options;

  final String? audioUrl;
  final String? imageUrl;
  final String? mediaUrl;

  JourneyQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    this.audioUrl,
    this.imageUrl,
    this.mediaUrl,
  });

  factory JourneyQuestion.fromJson(Map<String, dynamic> json) {
    return JourneyQuestion(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'mcq',
      prompt: json['prompt']?.toString() ?? '',
      options: ((json['options'] ?? []) as List)
          .map((e) => JourneyOption.fromJson(e))
          .toList(),
      audioUrl: json['audioUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      mediaUrl: json['mediaUrl']?.toString(),
    );
  }
}

class CheckAnswerResult {
  final bool correct;
  final String? correctKey; // ✅ الجواب الصحيح (key)
  final String? correctAnswer; // ✅ الجواب الصحيح (نص)

  CheckAnswerResult({
    required this.correct,
    this.correctKey,
    this.correctAnswer,
  });

  factory CheckAnswerResult.fromJson(Map<String, dynamic> json) {
    return CheckAnswerResult(
      correct: json['correct'] == true,
      correctKey: json['correctKey']?.toString(),
      correctAnswer: json['correctAnswer']?.toString(),
    );
  }
}

class JourneyExamService {
  static const String baseUrl = "http://10.0.2.2:4000";
  static const String endpointQuestions = "/api/journey-exam/questions";
  static const String endpointCheck = "/api/journey-exam/check";

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _headers(String? token) {
    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  static Future<List<JourneyQuestion>> fetchStageQuestions({
    required String level,
    required int stage,
  }) async {
    final token = await _token();
    final uri = Uri.parse("$baseUrl$endpointQuestions?level=$level&stage=$stage");

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final List data = body['data'] as List;
    return data.map((e) => JourneyQuestion.fromJson(e)).toList();
  }

  static Future<CheckAnswerResult> checkAnswer({
    required String level,
    required int stage,
    required String questionId,
    String? selectedKey,
    String? writtenAnswer,
  }) async {
    final token = await _token();
    final uri = Uri.parse("$baseUrl$endpointCheck");

    final res = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        "level": level,
        "stage": stage,
        "questionId": questionId,
        "selectedKey": selectedKey,
        "writtenAnswer": writtenAnswer,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    
    // ✅ Debug: طباعة الـ response من الباك
    print('📥 Backend response: ${res.body}');
    print('📥 Body data: ${body['data']}');
    
    final result = CheckAnswerResult.fromJson(body['data'] as Map<String, dynamic>);
    print('📥 Parsed result: correct=${result.correct}, correctKey=${result.correctKey}');
    
    return result;
  }
}
