import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum JourneyLevel { beginner, intermediate, advanced }

extension JourneyLevelX on JourneyLevel {
  String get apiValue {
    switch (this) {
      case JourneyLevel.beginner:
        return 'beginner';
      case JourneyLevel.intermediate:
        return 'intermediate';
      case JourneyLevel.advanced:
        return 'advanced';
    }
  }
}

JourneyLevel parseJourneyLevel(String s) {
  final v = s.toLowerCase().trim();
  if (v == 'intermediate') return JourneyLevel.intermediate;
  if (v == 'advanced') return JourneyLevel.advanced;
  return JourneyLevel.beginner;
}

class JourneyData {
  final int streak;
  final int points;
  final String mainLevel;
  final String subLevel;
  final List<String> categories;
  final String? mapImageUrl;

  // ✅ من الباك
  final int unlockedStage; // 1..15
  final int xp;
  final List<int> completedStages;

  const JourneyData({
    required this.streak,
    required this.points,
    required this.mainLevel,
    required this.subLevel,
    required this.categories,
    this.mapImageUrl,
    this.unlockedStage = 1,
    this.xp = 0,
    this.completedStages = const [],
  });

  factory JourneyData.fromJson(Map<String, dynamic> j) {
    return JourneyData(
      streak: (j['streak'] ?? 0) as int,
      points: (j['points'] ?? 0) as int,
      mainLevel: (j['mainLevel'] ?? '') as String,
      subLevel: (j['subLevel'] ?? '') as String,
      categories: (j['categories'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      mapImageUrl: j['mapImageUrl']?.toString(),

      // ✅ تطابق الباك
      unlockedStage: (j['unlockedStage'] ?? 1) as int,
      xp: (j['xp'] ?? 0) as int,
      completedStages: (j['completedStages'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}

/// ✅ بيرجع "المستوى الحالي" + بياناته (حسب /current)
class CurrentJourneyResponse {
  final JourneyLevel currentLevel;
  final JourneyData data;

  CurrentJourneyResponse({
    required this.currentLevel,
    required this.data,
  });

  factory CurrentJourneyResponse.fromJson(Map<String, dynamic> j) {
    final lvl = parseJourneyLevel((j['currentLevel'] ?? 'beginner').toString());
    return CurrentJourneyResponse(
      currentLevel: lvl,
      data: JourneyData.fromJson(j),
    );
  }
}

class CurrentJourneyService {
  static const String baseUrl = "http://10.0.2.2:4000";

  // ✅ backend routes
  static const String endpointCurrent = "/api/journey/current";
  static const String endpointByLevel = "/api/journey/by-level";

  // ✅ NEW: complete stage
  static const String endpointCompleteStage = "/api/journey/complete-stage";
  
  // ✅ NEW: add points (for vocabulary learning)
  static const String endpointAddPoints = "/api/journey/add-points";

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

  /// ✅ أول ما تفتح الصفحة: يرجع currentLevel + بيانات المستوى الحالي
  static Future<CurrentJourneyResponse> fetchCurrent() async {
    final token = await _token();
    final uri = Uri.parse("$baseUrl$endpointCurrent");

    final res = await http.get(uri, headers: _headers(token));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return CurrentJourneyResponse.fromJson(json);
  }

  /// ✅ لما تكبس على BEGINNER/INTERMEDIATE/ADVANCED: يرجع بيانات هذا المستوى من الباك
  static Future<JourneyData> fetchByLevel(JourneyLevel level) async {
    final token = await _token();
    final uri = Uri.parse("$baseUrl$endpointByLevel?level=${level.apiValue}");

    final res = await http.get(uri, headers: _headers(token));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return JourneyData.fromJson(json);
  }

  /// ✅ NEW: لما المستخدم يخلص Stage (خصوصًا 15 -> بيرجع level جديد)
  /// body: { "stage": 1..15, "points": عدد النقاط المكتسبة }
  static Future<CurrentJourneyResponse> completeStage({
    required int stage,
    required int points,
  }) async {
    final token = await _token();
    final uri = Uri.parse("$baseUrl$endpointCompleteStage");

    final res = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        "stage": stage,
        "points": points,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;

    // ✅ الباك بيرجع currentLevel + باقي الحقول (مع النقاط المحدثة)
    return CurrentJourneyResponse.fromJson(json);
  }

  /// ✅ NEW: إضافة نقاط عند تعلم كلمة جديدة
  /// body: { "points": عدد النقاط (5 لكل كلمة) }
  static Future<CurrentJourneyResponse> addPoints({
    required int points,
  }) async {
    final token = await _token();
    final uri = Uri.parse("$baseUrl$endpointAddPoints");

    final res = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        "points": points,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;

    // ✅ الباك بيرجع currentLevel + باقي الحقول (مع النقاط المحدثة)
    return CurrentJourneyResponse.fromJson(json);
  }
}
