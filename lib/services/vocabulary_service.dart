import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_id_service.dart';

class VocabularyService {
  // Base URL for Android emulator
  static const String baseUrl = 'http://10.0.2.2:4000/api/v1';

  /// Get headers with device ID
  static Future<Map<String, String>> _getHeaders() async {
    final deviceId = await DeviceIdService.getOrCreateDeviceId();
    print('🔑 Device ID: $deviceId');
    return {
      'Content-Type': 'application/json',
      'x-device-id': deviceId,
    };
  }

  /// Get vocabulary options (categories, etc.)
  static Future<Map<String, dynamic>> getOptions() async {
    final url = Uri.parse('$baseUrl/vocabulary/options');
    print('📡 GET Request URL: $url');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    print('📥 Response Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      final message = body['message'] ?? 'Failed to load options';
      throw Exception(message);
    }

    final body = json.decode(response.body);
    return body['data'] as Map<String, dynamic>;
  }

  /// Convert frontend category names to backend format (lowercase)
  static String _normalizeCategory(String category) {
    // Map frontend display names to backend expected format
    final categoryMap = {
      'Work': 'work',
      'Study': 'study',
      'Religion': 'religion',
      'Daily Life': 'daily_life',
      'Travel': 'travel',
      'Shopping': 'shopping',
      'Technology': 'technology',
    };
    
    return categoryMap[category] ?? category.toLowerCase().replaceAll(' ', '_');
  }

  /// Start a new vocabulary session
  /// Returns: {sessionId, words: [...]}
  static Future<Map<String, dynamic>> startSession({
    required List<String> categories,
    required int count,
    String? level,
    String mode = 'preset', // Default to 'preset', can be 'custom'
  }) async {
    final url = Uri.parse('$baseUrl/vocabulary/session/start');
    print('📡 POST Request URL: $url');
    
    // Normalize category names to backend format
    final normalizedCategories = categories.map(_normalizeCategory).toList();
    
    final requestBody = {
      'mode': mode,
      'categories': normalizedCategories,
      'count': count,
      if (level != null) 'level': level,
    };

    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(requestBody),
    );
    print('📥 Response Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      final message = body['message'] ?? 'Failed to start session';
      throw Exception(message);
    }

    final body = json.decode(response.body);
    
    // Backend might return data directly or wrapped in 'data' field
    // Try both structures
    if (body['data'] != null) {
      return body['data'] as Map<String, dynamic>;
    } else if (body['sessionId'] != null || body['words'] != null) {
      // Data is returned directly in the response
      return body as Map<String, dynamic>;
    } else {
      // Log the actual response for debugging
      print('Unexpected response structure: $body');
      throw Exception('Invalid response structure from backend');
    }
  }

  /// Update word status (learned/saved)
  static Future<void> updateWordStatus({
    required String sessionId,
    required String wordId,
    bool? learned,
    bool? saved,
  }) async {
    final url = Uri.parse(
      '$baseUrl/vocabulary/session/$sessionId/word/$wordId',
    );
    print('📡 PATCH Request URL: $url');

    final requestBody = <String, dynamic>{};
    if (learned != null) requestBody['learned'] = learned;
    if (saved != null) requestBody['saved'] = saved;

    final headers = await _getHeaders();
    final response = await http.patch(
      url,
      headers: headers,
      body: json.encode(requestBody),
    );
    print('📥 Response Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      final message = body['message'] ?? 'Failed to update word status';
      throw Exception(message);
    }
  }

  /// Finish vocabulary session
  /// Returns: {learnedCount, savedCount}
  static Future<Map<String, dynamic>> finishSession(String sessionId) async {
    final url = Uri.parse('$baseUrl/vocabulary/session/$sessionId/finish');
    print('📡 POST Request URL: $url');

    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
    );
    print('📥 Response Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      final message = body['message'] ?? 'Failed to finish session';
      throw Exception(message);
    }

    final body = json.decode(response.body);
    return body['data'] as Map<String, dynamic>;
  }
}

