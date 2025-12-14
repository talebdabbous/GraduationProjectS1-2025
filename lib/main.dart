import 'package:flutter/material.dart';

// AUTH
import 'login/welcome_screen.dart';
import 'login/login_screen.dart';
import 'login/register_screen.dart';
import 'login/forgot_password_screen.dart';
import 'login/reset_password_screen.dart';
import 'login/check_auth.dart';

// LEVEL EXAM
import 'level_exam/ask.dart';
import 'level_exam/level_exam.dart';

// HOME & PROFILE
import 'Home_Screen/home_screen.dart';
import 'current_journey/current_journey_screen.dart';
import 'profile/profile_main_screen.dart';
import 'profile/edit_profile.dart';
import 'vocabulary/vocabulary_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/': (_) => const CheckAuth(),
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),

        '/ask_level': (_) => StartLevelPage(),
        '/level_exam': (_) => LevelExamScreen(),

        '/home_screen': (_) => const HomeScreen(),

        // ✅ بدون arguments
        '/current_journey_screen': (_) => const CurrentJourneyPage(),
        '/profile_main_screen': (_) => const ProfileScreen(),
        '/edit_profile': (_) => const EditProfileScreen(),
        '/vocabulary_screen': (_) => const VocabularyScreen(),

        '/reset_password': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          final resetToken = args['resetToken'] as String;
          return ResetPasswordScreen(resetToken: resetToken);
        },
      },
    );
  }
}