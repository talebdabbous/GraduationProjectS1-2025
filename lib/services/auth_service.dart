// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  /// على المحاكي: 10.0.2.2
  /// على جهاز حقيقي: غيّرها إلى IP اللابتوب (مثلاً 192.168.1.10)
  static const String _base = 'http://10.0.2.2:4000/api/auth';
  // static const String _base = 'https://graduationprojects1-2025-backend.onrender.com/api/auth';
//const String baseUrl = 'http://10.0.2.2:4000';

  // ===== Helpers =====
  static dynamic _json(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return {};
    }
  }

  // ===== Register =====
  // في حال التحقق مُفعّل:
  //   backend: { message, pendingVerification: true, user: { id, email } }
  // في حال التحقق مُعطّل:
  //  backend: { message, token, user: {...} }
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String dateOfBirth, // YYYY-MM-DD
    String? sex,                // "Male" / "Female"
    int? dailyGoal,             // دقائق
    String? level,              // مثلاً "Beginner A1"
    String? role,               // "student" / "teacher" / "admin"
    String? profilePicture,     // URL لو حاب
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'dateOfBirth': dateOfBirth,
    };

    // نضيف الحقول الاختيارية فقط إذا مش null
    if (sex != null) body['sex'] = sex;
    if (dailyGoal != null) body['dailyGoal'] = dailyGoal;
    if (level != null) body['level'] = level;
    if (role != null) body['role'] = role;
    if (profilePicture != null) body['profilePicture'] = profilePicture;

    final res = await http.post(
      Uri.parse('$_base/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = _json(res.body);
    final ok = res.statusCode == 200 || res.statusCode == 201;

    if (ok) {
      // نرجّع data كما هي + فلاغ pendingVerification لو موجود
      return {
        'success': true,
        'data': data,
        'pendingVerification': data['pendingVerification'] == true,
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed',
      };
    }
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
        ? {'success': true, 'data': data} // data['token'], data['user']
        : {
            'success': false,
            'message': data['message'] ?? 'Verification failed',
          };
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
        : {
            'success': false,
            'message': data['message'] ?? 'Resend failed',
          };
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
      // backend: { token, user: {...} }
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
        : {
            'success': false,
            'message': data['message'] ?? 'Request failed',
          };
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
        : {
            'success': false,
            'message': data['message'] ?? 'Verification failed',
          };
  }

  // 3) تثبيت كلمة المرور الجديدة باستخدام resetToken فقط
  static Future<Map<String, dynamic>> finalizeReset({
    required String resetToken,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/finalize-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'resetToken': resetToken,
        'newPassword': newPassword,
      }),
    );
    final data = _json(res.body);
    final ok = res.statusCode == 200;
    return ok
        ? {'success': true, 'data': data}
        : {
            'success': false,
            'message': data['message'] ?? 'Reset failed',
          };
  }

  // ===========================
  // Profile: GET /me , PUT /me
  // ===========================

  /// 🔹 جلب بيانات المستخدم الحالية من /api/auth/me
  static Future<Map<String, dynamic>> getMe({
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$_base/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _json(res.body);
    final ok = res.statusCode == 200;
    return ok
        ? {'success': true, 'data': data}
        : {
            'success': false,
            'message': data['message'] ?? 'Could not load profile',
          };
  }

  /// 🔹 تحديث البروفايل /api/auth/me
  static Future<Map<String, dynamic>> updateMe({
    required String token,
    String? name,
    String? email,
    String? dateOfBirth,      // شكلها "YYYY-MM-DD"
    String? sex,              // "Male"/"Female"
    int? dailyGoal,
    String? level,
    String? profilePicture,
    bool? completedLevelExam, // 👈 مهم هون
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth; // الباك يستقبل dateOfBirth أو dob
    if (sex != null) body['sex'] = sex;
    if (dailyGoal != null) body['dailyGoal'] = dailyGoal;
    if (level != null) body['level'] = level;
    if (profilePicture != null) body['profilePicture'] = profilePicture;
    if (completedLevelExam != null) {
      body['completedLevelExam'] = completedLevelExam;
    }

    final res = await http.put(
      Uri.parse('$_base/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = _json(res.body);
    final ok = res.statusCode == 200;
    return ok
        ? {'success': true, 'data': data}
        : {'success': false, 'message': data['message'] ?? 'Update failed'};
  }
}
