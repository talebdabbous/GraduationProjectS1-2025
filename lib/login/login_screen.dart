import 'dart:async';
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

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  String? emailError;
  String? passwordError;

  bool isLoading = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // صفّر الأخطاء
    setState(() {
      emailError = null;
      passwordError = null;
    });

    // تحقق بسيط قبل الطلب
    final e = email.text.trim();
    final p = password.text;

    bool valid = true;
    if (e.isEmpty || !e.contains('@')) {
      emailError = 'Please enter a valid email';
      emailFocus.requestFocus();
      valid = false;
    }
    if (p.isEmpty) {
      passwordError = 'Please enter your password';
      if (valid) passwordFocus.requestFocus();
      valid = false;
    }
    if (!valid) {
      setState(() {});
      return;
    }

    setState(() => isLoading = true);
    final result = await AuthService.loginUser(email: e, password: p);
    setState(() => isLoading = false);

    if (result['success'] == true) {
      // نجاح: خزّن التوكن وكمل
      final token = result['data']['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "✅ Logged in successfully!",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF219EBC),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacementNamed(context, '/ask_level');
      return;
    }

    // فشل: إمّا بيانات غلط أو الحساب غير مفعّل
    final msg = (result['message'] ?? '').toString();
    final pending = result['pendingVerification'] == true;

    if (pending) {
      // افتح Dialog للتحقق من الإيميل مباشرة
      await _showEmailVerifyDialog(e);
      return;
    }

    // وزّع الرسالة على الحقول مثل الريجستر
    final low = msg.toLowerCase();
    setState(() {
      if (low.contains('password')) {
        passwordError = msg;
        passwordFocus.requestFocus();
      } else if (low.contains('email')) {
        emailError = msg;
        emailFocus.requestFocus();
      } else {
        // لو رسالة عامة غير محددة، خليها تحت الإيميل
        emailError = msg.isNotEmpty ? msg : 'Login failed';
        emailFocus.requestFocus();
      }
    });
  }

  Future<void> _showEmailVerifyDialog(String emailVal) async {
    final codeCtrl = TextEditingController();
    String? codeError;
    bool loading = false;
    int remaining = 0;
    Timer? timer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> verify() async {
            final code = codeCtrl.text.trim();
            if (code.length != 6) {
              setLocal(() => codeError = 'Enter the 6-digit code');
              return;
            }
            setLocal(() {
              loading = true;
              codeError = null;
            });
            final res = await AuthService.verifyEmail(email: emailVal, code: code);
            setLocal(() => loading = false);

            if (res['success'] == true) {
              // السيرفر برجع token + user (حسب كودك)
              final data = res['data'];
              final token = data['token'];
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('token', token);

              timer?.cancel();
              if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Email verified. Logged in.')),
              );
              Navigator.pushReplacementNamed(context, '/ask_level');
            } else {
              setLocal(() => codeError = res['message'] ?? 'Verification failed');
            }
          }

          Future<void> resend() async {
            if (remaining > 0) return;
            setLocal(() {
              loading = true;
              codeError = null;
            });
            final r = await AuthService.resendVerification(email: emailVal);
            setLocal(() => loading = false);
            if (r['success'] == true) {
              setLocal(() {
                codeError = 'A new code has been sent.';
                remaining = 60;
              });
              timer?.cancel();
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (!mounted) {
                  t.cancel();
                  return;
                }
                setLocal(() {
                  remaining--;
                  if (remaining <= 0) t.cancel();
                });
              });
            } else {
              setLocal(() => codeError = r['message'] ?? 'Could not resend code');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Verify your email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('We sent a 6-digit code to\n$emailVal', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Verification code',
                    counterText: '',
                    errorText: codeError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => setLocal(() => codeError = null),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () {
                  timer?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: loading || remaining > 0 ? null : resend,
                child: Text(remaining > 0 ? 'Resend (${remaining}s)' : 'Resend'),
              ),
              ElevatedButton(
                onPressed: loading ? null : verify,
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify'),
              ),
            ],
          );
        },
      ),
    );
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
                            focusNode: emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email),
                              errorText: emailError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setState(() => emailError = null),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: password,
                            focusNode: passwordFocus,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => obscure = !obscure),
                                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                              ),
                              errorText: passwordError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setState(() => passwordError = null),
                            textInputAction: TextInputAction.done,
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
                            onPressed: () => Navigator.pushReplacementNamed(context, '/home_screen'),
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
