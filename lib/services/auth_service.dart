import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:4000/api/auth'; // لو محاكي

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      final body = jsonDecode(response.body);
      return {'success': false, 'message': body['message'] ?? 'Registration failed'};
    }
  }


//   static Future<Map<String, dynamic>> loginUser({
//   required String email,
//   required String password,
// }) async {
//   final url = Uri.parse('$baseUrl/login');
//   final response = await http.post(
//     url,
//     headers: {'Content-Type': 'application/json'},
//     body: jsonEncode({
//       'email': email,
//       'password': password,
//     }),
//   );

//   if (response.statusCode == 200) {
//     return {'success': true, 'data': jsonDecode(response.body)};
//   } else {
//     final body = jsonDecode(response.body);
//     return {'success': false, 'message': body['message'] ?? 'Login failed'};
//   }
  //========================================================================================
  static Future<Map<String, dynamic>> loginUser({
  required String email,
  required String password,
}) async {
  await Future.delayed(const Duration(seconds: 1));
  if (email == 'test@test.com' && password == '123456') {
    return {'success': true, 'message': 'تم تسجيل الدخول بنجاح'};
  } else {
    return {'success': false, 'message': 'بيانات الدخول غير صحيحة'};
  }
}

}

 
