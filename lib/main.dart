import 'package:flutter/material.dart';
import 'login/welcome_screen.dart';
import 'login/login_screen.dart';
import 'login/register_screen.dart';
import 'login/forgot_password_screen.dart';
import 'level_exam/ask.dart';
import 'level_exam/level_exam.dart';
import 'login/check_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Arabic Learning App',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
    useMaterial3: true,
    fontFamily: 'Arial',
  ),
  initialRoute: '/', // ابدأ من شاشة التحقق
  routes: {
    '/': (_) => const CheckAuth(),            // Splash / فحص التوكن
    '/welcome': (_) => const WelcomeScreen(), // لو بدك صفحة ترحيب
    '/login': (_) => const LoginScreen(),
    '/register': (_) => const RegisterScreen(),
    '/forgot': (_) => const ForgotPasswordScreen(),
    '/ask_level': (_) => const StartLevelPage(),
    '/level_exam': (_) => LevelExamPage(),
  },
);
  }
}
