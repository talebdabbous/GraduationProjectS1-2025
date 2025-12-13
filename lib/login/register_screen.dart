import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final dobText = TextEditingController();
  DateTime? _dob;

  // FocusNodes عشان نقدر نحط الفوكس على الحقل اللي فيه خطأ
  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final dobFocus = FocusNode();

  bool isLoading = false;
  bool obscure = true;

  // New schema fields
  String _gender = "None"; // Male / Female / None
  String _nativeLanguage = "en"; // ar / en / tr / fr / es / ur / other
  String? _learningGoal; // optional

  // أخطاء الحقول (تنعرض تحت كل حقل)
  String? nameError;
  String? emailError;
  String? passwordError;
  String? dobError;
  String? genderError;
  String? nativeLanguageError;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    dobText.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    dobFocus.dispose();
    super.dispose();
  }

  /// ✅ نفس فكرة _handleAuthSuccess في LoginScreen
  /// نخزن التوكن + بيانات المستخدم في SharedPreferences
  /// وبعدين نقرر نروح على home أو ask_level حسب completed_level_exam (local)
  Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>? ?? {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    await prefs.setString('user_name', (user['name'] ?? '') as String);
    await prefs.setString('user_email', (user['email'] ?? '') as String);
    await prefs.setString('user_role', (user['role'] ?? 'student') as String);
    
    // New schema fields
    await prefs.setString('user_gender', (user['gender'] ?? 'None') as String);
    await prefs.setString('user_nativeLanguage', (user['nativeLanguage'] ?? 'en') as String);
    
    if (user['learningGoal'] != null) {
      await prefs.setString('user_learningGoal', (user['learningGoal']) as String);
    }
    
    if (user['currentMainLevel'] != null) {
      await prefs.setString('user_currentMainLevel', (user['currentMainLevel']) as String);
    }

    await prefs.setString(
      'user_dob',
      (user['dateOfBirth'] ?? '') as String,
    );
    await prefs.setString(
      'user_profilePicture',
      (user['profilePicture'] ?? '') as String,
    );

    if (!mounted) return;

    final completedExam = prefs.getBool('completedLevelExam') ?? false;
    if (completedExam) {
      Navigator.pushReplacementNamed(context, '/home_screen');
    } else {
      Navigator.pushReplacementNamed(context, '/ask_level');
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
                            "Create Account",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Full Name
                          TextField(
                            controller: name,
                            focusNode: nameFocus,
                            decoration: InputDecoration(
                              labelText: "Full Name",
                              prefixIcon: const Icon(Icons.person),
                              errorText: nameError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setState(() => nameError = null),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          // Email
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

                          // Date of Birth
                          GestureDetector(
                            onTap: _pickDob,
                            child: AbsorbPointer(
                              child: TextField(
                                controller: dobText,
                                focusNode: dobFocus,
                                decoration: InputDecoration(
                                  labelText: "Date of Birth",
                                  hintText: "YYYY-MM-DD",
                                  prefixIcon: const Icon(Icons.cake),
                                  suffixIcon: const Icon(Icons.calendar_month),
                                  errorText: dobError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextField(
                            controller: password,
                            focusNode: passwordFocus,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                              errorText: passwordError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) =>
                                setState(() => passwordError = null),
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 14),

                          // Gender dropdown
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: InputDecoration(
                              labelText: "Gender",
                              errorText: genderError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: "None", child: Text("None")),
                              DropdownMenuItem(value: "Male", child: Text("Male")),
                              DropdownMenuItem(value: "Female", child: Text("Female")),
                            ],
                            onChanged: (val) => setState(() {
                              _gender = val ?? "None";
                              genderError = null;
                            }),
                          ),
                          const SizedBox(height: 14),

                          // Native Language dropdown (required)
                          DropdownButtonFormField<String>(
                            value: _nativeLanguage,
                            decoration: InputDecoration(
                              labelText: "Native Language *",
                              errorText: nativeLanguageError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: "ar", child: Text("Arabic")),
                              DropdownMenuItem(value: "en", child: Text("English")),
                              DropdownMenuItem(value: "tr", child: Text("Turkish")),
                              DropdownMenuItem(value: "fr", child: Text("French")),
                              DropdownMenuItem(value: "es", child: Text("Spanish")),
                              DropdownMenuItem(value: "ur", child: Text("Urdu")),
                              DropdownMenuItem(value: "other", child: Text("Other")),
                            ],
                            onChanged: (val) => setState(() {
                              _nativeLanguage = val ?? "en";
                              nativeLanguageError = null;
                            }),
                          ),
                          const SizedBox(height: 14),

                          // Learning Goal dropdown (optional)
                          DropdownButtonFormField<String?>(
                            value: _learningGoal,
                            decoration: InputDecoration(
                              labelText: "Learning Goal (optional)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text("None")),
                              DropdownMenuItem(value: "travel", child: Text("Travel")),
                              DropdownMenuItem(value: "study", child: Text("Study")),
                              DropdownMenuItem(value: "work", child: Text("Work")),
                              DropdownMenuItem(value: "conversation", child: Text("Conversation")),
                              DropdownMenuItem(value: "religion", child: Text("Religion")),
                              DropdownMenuItem(value: "culture", child: Text("Culture")),
                              DropdownMenuItem(value: "exam", child: Text("Exam")),
                              DropdownMenuItem(value: "other", child: Text("Other")),
                            ],
                            onChanged: (val) => setState(() => _learningGoal = val),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
                                : const Text("Register",
                                    style: TextStyle(fontSize: 18)),
                          ),

                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/welcome');
                            },
                            child: const Text("Back "),
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

  // =============== Dialog OTP: ادخله "داخل" الكلاس (_RegisterScreenState) ===============
  Future<void> _showOtpDialog(String emailVal) async {
    final codeCtrl = TextEditingController();
    String? codeError;
    bool loading = false;
    int remaining = 0; // عدّاد لإعادة الإرسال
    Timer? t;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> doVerify() async {
              final c = codeCtrl.text.trim();
              if (c.length != 6) {
                setLocal(() => codeError = 'Enter the 6-digit code');
                return;
              }
              setLocal(() {
                loading = true;
                codeError = null;
              });
              final res =
                  await AuthService.verifyEmail(email: emailVal, code: c);
              setLocal(() => loading = false);
              if (res['success'] == true) {
                final data = res['data'] as Map<String, dynamic>;
                t?.cancel();
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                if (!mounted) return;
                // ✅ بعد التحقق الناجح: خزن التوكن + بيانات المستخدم وكمّل نفس مسار اللوجين
                await _handleAuthSuccess(data);
              } else {
                setLocal(
                    () => codeError = res['message'] ?? 'Verification failed');
              }
            }

            Future<void> doResend() async {
              if (remaining > 0) return;
              setLocal(() {
                loading = true;
                codeError = null;
              });
              final res =
                  await AuthService.resendVerification(email: emailVal);
              setLocal(() => loading = false);
              if (res['success'] == true) {
                setLocal(() {
                  codeError = 'A new code has been sent to your email.';
                  remaining = 60;
                });
                t?.cancel();
                t = Timer.periodic(const Duration(seconds: 1), (timer) {
                  if (!mounted) {
                    timer.cancel();
                    return;
                  }
                  setLocal(() {
                    remaining--;
                    if (remaining <= 0) timer.cancel();
                  });
                });
              } else {
                setLocal(() =>
                    codeError = res['message'] ?? 'Could not resend code');
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Verify your email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('We sent a 6-digit code to\n$emailVal',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Verification code',
                      counterText: '',
                      errorText: codeError,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setLocal(() => codeError = null),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          t?.cancel();
                          Navigator.pop(ctx);
                        },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: loading || remaining > 0 ? null : doResend,
                  child: Text(
                      remaining > 0 ? 'Resend (${remaining}s)' : 'Resend'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : doVerify,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final first = DateTime(now.year - 100, now.month, now.day);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      _dob = picked;
      dobText.text = _formatDate(picked);
      setState(() => dobError = null);
    }
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  int _ageYears(DateTime birthDate, DateTime now) {
    int age = now.year - birthDate.year;
    final hasHadBirthdayThisYear =
        (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hasHadBirthdayThisYear) age -= 1;
    return age;
  }

  Future<void> _register() async {
    // صفّر الأخطاء
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      dobError = null;
      genderError = null;
      nativeLanguageError = null;
    });

    bool valid = true;

    if (name.text.trim().isEmpty) {
      nameError = 'Please enter your full name';
      valid = false;
      nameFocus.requestFocus();
    }

    final emailVal = email.text.trim();
    final emailLooksOk = emailVal.isNotEmpty && emailVal.contains('@');
    if (!emailLooksOk) {
      emailError = 'Please enter a valid email';
      if (valid) emailFocus.requestFocus();
      valid = false;
    }

    final pwd = password.text;
    // لازم يكون أطول من 8 → إذا < 8 خطأ
    if (pwd.length < 8) {
      passwordError = 'Password must be longer than 8 characters';
      if (valid) passwordFocus.requestFocus();
      valid = false;
    }

    if (_dob == null) {
      dobError = 'Please select your date of birth';
      if (valid) dobFocus.requestFocus();
      valid = false;
    } else {
      final now = DateTime.now();
      if (_dob!.isAfter(now)) {
        dobError = 'Date of birth cannot be in the future';
        if (valid) dobFocus.requestFocus();
        valid = false;
      } else if (_ageYears(_dob!, now) <= 4) {
        dobError = 'You must be older than 4 years old';
        if (valid) dobFocus.requestFocus();
        valid = false;
      }
    }

    if (!valid) {
      setState(() {}); // حدّث UI بالأخطاء
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.registerUser(
      name: name.text.trim(),
      email: emailVal,
      password: pwd,
      dateOfBirth: dobText.text.trim(),
      gender: _gender,
      nativeLanguage: _nativeLanguage,
      learningGoal: _learningGoal,
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final pending = result['pendingVerification'] == true;

      if (!mounted) return;

      if (pending) {
        // ✅ مود OTP شغّال → افتح Dialog الكود
        await _showOtpDialog(emailVal);
      } else {
        // ✅ التحقق مطفي → رجع token + user → كمّل مسار اللوجين
        await _handleAuthSuccess(data);
      }
      return;
    } else {
      // بدل ما نعمل Dialog، منمسك حالة "الإيميل مستخدم" ونظهرها تحت الحقل
      final msg = (result['message'] ?? '').toString().toLowerCase();
      if (msg.contains('email already registered') || msg.contains('already')) {
        setState(() {
          emailError = 'Email is already registered';
        });
        emailFocus.requestFocus();
        return;
      }

      // أي أخطاء عامة ثانية (سيرفر/شبكة) اعرضها تحت الإيميل
      setState(() {
        emailError = result['message']?.toString() ?? 'Registration failed';
      });
      emailFocus.requestFocus();
    }
  }
}
