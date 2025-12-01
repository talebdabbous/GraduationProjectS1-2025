import 'package:flutter/material.dart';
import 'login/welcome_screen.dart';
import 'login/login_screen.dart';
import 'login/register_screen.dart';
import 'login/forgot_password_screen.dart';
import 'level_exam/ask.dart';
import 'level_exam/level_exam.dart';
import 'login/check_auth.dart';
import 'login/reset_password_screen.dart'; 
import 'Home_Screen/home_screen.dart';
import 'profile/profile_main_screen.dart';


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
      initialRoute: '/home_screen',
      routes: {
        '/': (_) => const CheckAuth(),
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/ask_level': (_) => const StartLevelPage(),
        '/level_exam': (_) => LevelExamPage(),
        '/home_screen': (_) => HomeScreen(
              userName: 'Taleb', // Replace with actual user data
              dailyStreak: 5,   // Replace with actual user data
              points: 1200,     // Replace with actual user data
            ),
         '/profile_main_screen': (_) => const ProfileScreen(
  userName: 'Taleb',
  email: 'taleb@example.com',
  dailyStreak: 5,
  points: 1200,
  currentLevel: 'Beginner A1',
),

         '/reset_password': (ctx) {
    final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
    final resetToken = args['resetToken'] as String;
    return ResetPasswordScreen(resetToken: resetToken);
  },
        
      },
    );
  }
}
