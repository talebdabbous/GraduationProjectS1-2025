// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  /// على المحاكي: 10.0.2.2
  /// على جهاز حقيقي: غيّرها إلى IP اللابتوب (مثلاً 192.168.1.10)
  static const String _base = 'http://10.0.2.2:4000/api/auth';

  // ===== Helpers =====
  static dynamic _json(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return {};
    }
  }

  // ===== Register (يرسل OTP تفعيل الإيميل) =====
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth, // YYYY-MM-DD
  }) async {
    final res = await http.post(
      Uri.parse('$_base/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'dateOfBirth': dateOfBirth,
      }),
    );
    final data = _json(res.body);
    final ok = res.statusCode == 200 || res.statusCode == 201;
    return ok
        ? {'success': true, 'data': data}
        : {'success': false, 'message': data['message'] ?? 'Registration failed'};
  }

  // ===== Verify Email (OTP) =====
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    final data = _json(res.body);
    final ok = res.statusCode == 200;
    return ok
        ? {'success': true, 'data': data}
        : {'success': false, 'message': data['message'] ?? 'Verification failed'};
  }

  // ===== Resend Verification (OTP) =====
  static Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = _json(res.body);
    final ok = res.statusCode == 200;
    return ok
        ? {'success': true, 'data': data}
        : {'success': false, 'message': data['message'] ?? 'Resend failed'};
  }

  // ===== Login =====
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _json(res.body);
    if (res.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
        'pendingVerification': data['pendingVerification'] == true,
      };
    }
  }

  // ===========================
  // Forgot / Reset (Flow من خطوتين)
  // 1) forgotPassword: يرسل كود للإيميل
  // 2) verifyReset: يتحقق من الكود ويرجع resetToken مؤقّت
  // 3) finalizeReset: يغيّر الباسورد باستخدام resetToken فقط
  // ===========================

  // 1) إرسال كود الريسِت إلى الإيميل
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = _json(res.body);
    final ok = res.statusCode == 200;
    return ok
        ? {'success': true, 'data': data}
        : {'success': false, 'message': data['message'] ?? 'Request failed'};
  }

  // 2) التحقق من الكود → استلام resetToken
  static Future<Map<String, dynamic>> verifyReset({
    required String email,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/verify-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    final data = _json(res.body);
    final ok = res.statusCode == 200;
    return ok
        ? {'success': true, 'data': data} // data['resetToken']
        : {'success': false, 'message': data['message'] ?? 'Verification failed'};
  }

  // 3) تثبيت كلمة المرور الجديدة باستخدام resetToken فقط
  static Future<Map<String, dynamic>> finalizeReset({
    required String resetToken,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/finalize-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'resetToken': resetToken, 'newPassword': newPassword}),
    );
    final data = _json(res.body);
    final ok = res.statusCode == 200;
    return ok
        ? {'success': true, 'data': data}
        : {'success': false, 'message': data['message'] ?? 'Reset failed'};
  }
}
