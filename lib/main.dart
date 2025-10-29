import 'package:flutter/material.dart';
import 'login/welcome_screen.dart';
import 'login/login_screen.dart';
import 'login/register_screen.dart';
import 'login/forgot_password_screen.dart';
import 'level_exam/ask.dart';

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
      home: const WelcomeScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/ask_level': (_) => const StartLevelPage(),
      },
    );
  }
}
