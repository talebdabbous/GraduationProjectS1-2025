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
    required String gender,      // "Male" / "Female" / "None"
    required String nativeLanguage, // "ar" / "en" / "tr" / "fr" / "es" / "ur" / "other"
    String? learningGoal,        // optional enum
    String? profilePicture,      // optional URL
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'nativeLanguage': nativeLanguage,
    };

    // نضيف الحقول الاختيارية فقط إذا مش null
    if (learningGoal != null) body['learningGoal'] = learningGoal;
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
      // كذلك نرجّع التوكن من الـ data إذا كان موجود
      if (data['token'] != null) {
        // في حال التحقق معطّل، التوكن موجود في الـ response
        return {
          'success': true,
          'data': data,
          'pendingVerification': false,
        };
      }
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
  /// Response: { user: { id, name, email, dateOfBirth, gender, profilePicture, 
  ///            nativeLanguage, learningGoal, currentMainLevel, learningProgress, 
  ///            role, emailVerified, completedLevelExam } }
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
    
    if (ok) {
      // نستخرج user من الـ response
      final user = (data['user'] is Map<String, dynamic>) 
          ? data['user'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      
      return {
        'success': true,
        'data': user, // نرجّع user object مباشرة
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Could not load profile',
      };
    }
  }

  /// 🔹 تحديث البروفايل /api/auth/me
  /// يرسل فقط الحقول المُختارة من: name, email, dateOfBirth, gender, nativeLanguage, 
  /// learningGoal, profilePicture, completedLevelExam
  static Future<Map<String, dynamic>> updateMe({
    required String token,
    String? name,
    String? email,
    String? dateOfBirth,        // شكلها "YYYY-MM-DD"
    String? gender,             // "Male" / "Female" / "None"
    String? nativeLanguage,     // "ar" / "en" / "tr" / "fr" / "es" / "ur" / "other"
    String? learningGoal,       // optional enum
    String? profilePicture,
    bool? completedLevelExam,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
    if (gender != null) body['gender'] = gender;
    if (nativeLanguage != null) body['nativeLanguage'] = nativeLanguage;
    if (learningGoal != null) body['learningGoal'] = learningGoal;
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
    
    if (ok) {
      // نستخرج user من الـ response
      final user = (data['user'] is Map<String, dynamic>) 
          ? data['user'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      
      return {
        'success': true,
        'data': user, // نرجّع user object مباشرة
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Update failed',
      };
    }
  }
}
