import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool isLoading = false;
  String? emailError;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          const Text("Reset Password", textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
                          const SizedBox(height: 16),
                          const Text("Enter your email. We'll send you a reset code immediately.", textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email),
                              errorText: emailError,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => setState(() => emailError = null),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading ? null : _sendCodeThenPromptOtp,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text("Send code", style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text("Back to Login"),
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

  Future<void> _sendCodeThenPromptOtp() async {
    final emailVal = email.text.trim();
    if (emailVal.isEmpty || !emailVal.contains('@')) {
      setState(() => emailError = 'Please enter a valid email');
      return;
    }

    setState(() { isLoading = true; emailError = null; });
    final res = await AuthService.forgotPassword(email: emailVal);
    setState(() => isLoading = false);

    if (res['success'] == true) {
      // افتح Dialog لإدخال الكود والتحقق منه وإصدار resetToken
      await _showOtpDialog(emailVal);
    } else {
      setState(() => emailError = res['message']?.toString() ?? 'Request failed');
    }
  }

  Future<void> _showOtpDialog(String emailVal) async {
    final codeCtrl = TextEditingController();
    String? codeError;
    bool loading = false;
    int remaining = 0;
    Timer? t;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> verify() async {
            final c = codeCtrl.text.trim();
            if (c.length != 6) {
              setLocal(() => codeError = 'Enter the 6-digit code');
              return;
            }
            setLocal(() { loading = true; codeError = null; });
            final res = await AuthService.verifyReset(email: emailVal, code: c);
            setLocal(() => loading = false);

            if (res['success'] == true) {
              final resetToken = res['data']['resetToken'];
              t?.cancel();
              if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              if (!mounted) return;
              // روح لصفحة تعيين الباسورد ومعك resetToken فقط
              Navigator.pushReplacementNamed(
                context,
                '/reset_password',
                arguments: {'resetToken': resetToken},
              );
            } else {
              setLocal(() => codeError = res['message'] ?? 'Verification failed');
            }
          }

          Future<void> resend() async {
            if (remaining > 0) return;
            setLocal(() { loading = true; codeError = null; });
            final rr = await AuthService.forgotPassword(email: emailVal);
            setLocal(() => loading = false);
            if (rr['success'] == true) {
              setLocal(() { codeError = 'A new code has been sent.'; remaining = 60; });
              t?.cancel();
              t = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (!mounted) { timer.cancel(); return; }
                setLocal(() {
                  remaining--;
                  if (remaining <= 0) timer.cancel();
                });
              });
            } else {
              setLocal(() => codeError = rr['message'] ?? 'Could not resend code');
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Enter reset code'),
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
                    labelText: 'Reset code',
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
                onPressed: loading ? null : () { t?.cancel(); Navigator.pop(ctx); },
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
}
