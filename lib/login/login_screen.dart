import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isLoading = false;
  bool obscure = true;

  Future<void> _login() async {
    setState(() => isLoading = true);

    final result = await AuthService.loginUser(
      email: email.text.trim(),
      password: password.text.trim(),
    );

    setState(() => isLoading = false);
   

    if (result['success']) {
      //======================================= مؤقت ==========================
        Navigator.pushReplacementNamed(context, '/ask_level');
    //======================================= مؤقت ==========================
  //     final token = result['data']['token'];
  //     // 🧠 حفظ التوكن
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.setString('token', token);

  //     print("✅ oken saved locally: $token");

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text(
  //           "✅ Logged in successfully!",
  //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  //         ),
  //         backgroundColor: const Color(0xFF219EBC),
  //         behavior: SnackBarBehavior.floating,
  //         margin: const EdgeInsets.all(16),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  //         duration: const Duration(seconds: 2),
  //       ),
  //     );

  //     // بعد تسجيل الدخول بنجاح، انتقل للصفحة التالية (مثلاً /)
  //     Navigator.pushReplacementNamed(context, '/ask_level');
    } else {
      // لو في خطأ (إيميل أو كلمة سر غلط)
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("⚠️ Login Failed"),
          content: Text(result['message'] ?? "Invalid email or password"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/welcome_bg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.25)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    color: Colors.white.withOpacity(0.92),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            "Login",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                          const SizedBox(height: 24),

                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: password,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => obscure = !obscure),
                                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/forgot'),
                              child: const Text("Forgot password?"),
                            ),
                          ),

                          ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Sign in", style: TextStyle(fontSize: 18)),
                          ),

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don’t have an account? "),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                child: const Text("Register"),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                            child: const Text("Back"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
