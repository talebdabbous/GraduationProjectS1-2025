// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login/welcome_screen.dart';
import 'login/login_screen.dart';
import 'login/register_screen.dart';
import 'login/forgot_password_screen.dart';
import 'login/reset_password_screen.dart';
import 'login/check_auth.dart';

import 'level_exam/ask.dart';
import 'level_exam/level_exam.dart';

import 'Home_Screen/home_screen.dart';
import 'profile/profile_main_screen.dart';
import 'profile/edit_profile.dart';

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

      // 👈 أول شاشة هي CheckAuth عشان تقرر لو يروح Login أو Home / AskLevel
      initialRoute: '/',

      routes: {
        // ================== AUTH / WELCOME ==================
        '/': (_) => const CheckAuth(),
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),

        // ================== LEVEL EXAM FLOW ==================
        '/ask_level': (_) => const StartLevelPage(),
        '/level_exam': (_) => const LevelExamPage(),

        // ================== HOME SCREEN (من الباك عن طريق SharedPrefs) ==================
        '/home_screen': (_) => FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final prefs = snap.data!;

                // 👇 هدول كلهم جاية من الباك (تخزنت وقت اللوج إن / التفعيل)
                final userName = prefs.getString('user_name') ?? '';
                // تقدر بعدين تخزنهم من الباك برضه
                final dailyStreak = prefs.getInt('daily_streak') ?? 0; // افتراضي
                final points = prefs.getInt('user_points') ?? 0;       // افتراضي

                return HomeScreen(
                  userName: userName,
                  dailyStreak: dailyStreak,
                  points: points,
                );
              },
            ),

        // ================== PROFILE MAIN SCREEN ==================
        '/profile_main_screen': (_) => FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final prefs = snap.data!;

                // 👇 كل هدول القيم أساسهم من الباك
                final name = prefs.getString('user_name') ?? '';
                final email = prefs.getString('user_email') ?? '';
                final level = prefs.getString('user_level') ?? '';

                final dob = prefs.getString('user_dob'); // "YYYY-MM-DD" أو null
                final sex = prefs.getString('user_sex'); // "Male"/"Female" أو null
                final dailyGoal = prefs.getInt('user_dailyGoal'); // لو null في الباك، بتكون null

                return ProfileScreen(
                  name: name,
                  email: email,
                  level: level,
                  dateOfBirth: dob,
                  sex: sex,
                  dailyGoal: dailyGoal,
                );
              },
            ),

        // ================== EDIT PROFILE SCREEN ==================
        '/edit_profile': (ctx) => const EditProfileScreen(),

        // ================== RESET PASSWORD SCREEN ==================
        '/reset_password': (ctx) {
          final args =
              ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          final resetToken = args['resetToken'] as String;
          return ResetPasswordScreen(resetToken: resetToken);
        },
      },
    );
  }
}
