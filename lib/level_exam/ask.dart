import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';


class StartLevelPage extends StatelessWidget {
  const StartLevelPage({super.key});

  static const Color kBlue = Color(0xFF1E88E5); // درجة الأزرق للأزرار

    Future<void> _startFromZero(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // نخزن محليًا
    await prefs.setBool('completed_level_exam', true);
    await prefs.setString('user_level', 'Beginner A1');

    // نجيب التوكن
    final token = prefs.getString('token');

    // لو في توكن → نحدّث البروفايل في الباك
    if (token != null && token.isNotEmpty) {
      try {
        await AuthService.updateMe(
          token: token,
          level: 'Beginner A1',
          completedLevelExam: true, // 👈 هاي اللي سألت عنها
        );
      } catch (_) {
        // لو صار خطأ ما نكسّر التطبيق
      }
    }

    // وبعدين نروح عالهوم
    Navigator.pushReplacementNamed(context, '/home_screen');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/welcome_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // طبقة شفافية خفيفة لتحسين القراءة
          Container(color: Colors.black26),

          // المحتوى
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    "Welcome to Your Arabic Journey!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEDF2F4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Would you like to take a quick placement test\nor start learning from the beginning?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),

                  const Spacer(),

                  // الزر الأول: الامتحان
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: kBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/level_exam',
                      ),
                      child: const Text(
                        "Take Placement Test",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // الزر الثاني: بدء من الصفر + تعليم completed_level_exam
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _startFromZero(context),
                      child: const Text(
                        "Start from Zero",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
