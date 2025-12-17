import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/current_journey_service.dart';
import '../profile/profile_main_screen.dart';
import '../current_journey/current_journey_screen.dart';
import '../letter_sounds/letter_sounds_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  String _userName = '';
  int _dailyStreak = 0;
  int _points = 0;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return;

      // ✅ جلب بيانات المستخدم (للاسم وصورة البروفايل)
      final userRes = await AuthService.getMe(token: token);
      if (userRes['success'] != true) return;

      final user = userRes['data'] as Map<String, dynamic>;
      final userName = user['name'] ?? '';
      final profilePictureUrl = user['profilePicture']?.toString();

      // ✅ جلب البوينتس والستريك من Current Journey Service
      int streak = 0;
      int points = 0;
      
      try {
        final journeyData = await CurrentJourneyService.fetchCurrent();
        streak = journeyData.data.streak;
        points = journeyData.data.points;
      } catch (e) {
        // إذا فشل، استخدم البيانات من getMe كـ fallback
        streak = (user['currentStreak'] ?? 0) as int;
        final currentMainLevel = user['currentMainLevel'];
        final progress = user['learningProgress'];

        if (progress is List && currentMainLevel is String) {
          final item = progress.cast<dynamic>().firstWhere(
            (e) => e is Map && e['levelId'] == currentMainLevel,
            orElse: () => null,
          );

          if (item is Map && item['xp'] != null) {
            points = (item['xp'] as num).toInt();
          }
        }
      }

      if (!mounted) return;
      
      setState(() {
        _userName = userName;
        _dailyStreak = streak;
        _points = points;
        _profilePictureUrl = profilePictureUrl;
      });
    } catch (e) {
      print('❌ Error loading home screen data: $e');
      // تجاهل الأخطاء حالياً
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: Column(
          children: [
            // ---------------- HEADER ----------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome back 👋",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _stat("🔥 Streak", "${_dailyStreak} days"),
                              const SizedBox(width: 8),
                              _stat("⭐ Points", "$_points"),
                            ],
                          )
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: () async {
                        // ✅ الانتظار للعودة من البروفايل ثم تحديث البيانات
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                        // ✅ تحديث البيانات عند العودة
                        if (mounted) {
                          _loadFromBackend();
                        }
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                            ? NetworkImage(_profilePictureUrl!)
                            : null,
                        child: _profilePictureUrl == null || _profilePictureUrl!.isEmpty
                            ? Icon(Icons.person, color: primary, size: 28)
                            : null,
                      ),
                    )
                  ],
                ),
              ),
            ),

            // ---------------- GRID ----------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                // ✅ الانتظار للعودة من Current Journey ثم تحديث البيانات
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CurrentJourneyPage()),
                                );
                                // ✅ تحديث البيانات عند العودة
                                if (mounted) {
                                  _loadFromBackend();
                                }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: _gradientCard(
                                title: "Current Journey",
                                subtitle: "Continue where you left off",
                                icon: Icons.flag_outlined,
                                colors: [primary, primary.withOpacity(0.6)],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                // ✅ الانتظار للعودة من Letter Writing ثم تحديث البيانات
                                await Navigator.pushNamed(context, '/letter-writing');
                                // ✅ تحديث البيانات عند العودة
                                if (mounted) {
                                  _loadFromBackend();
                                }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: _gradientCard(
                                title: "Letter Writing",
                                subtitle: "Practice Arabic letters",
                                icon: Icons.edit_note_outlined,
                                colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, '/vocabulary_screen'),
                              borderRadius: BorderRadius.circular(18),
                              child: _gradientCard(
                                title: "Vocabulary",
                                subtitle: "Grow your word bank",
                                icon: Icons.menu_book_outlined,
                                colors: [Colors.orange, Colors.deepOrangeAccent],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LetterSoundsScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: _gradientCard(
                                title: "Letter Sounds",
                                subtitle: "Listen & recognize sounds",
                                icon: Icons.volume_up_outlined,
                                colors: [Colors.green, Colors.lightGreen],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ---------------- BOTTOM NAV ----------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) async {
          if (i == 3) {
            setState(() => _index = 0);
            // ✅ الانتظار للعودة من البروفايل ثم تحديث البيانات
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            // ✅ تحديث البيانات عند العودة
            if (mounted) {
              _loadFromBackend();
            }
            return;
          }
          setState(() => _index = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: "Chatbot"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _stat(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "$title: $value",
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _gradientCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: colors.first.withOpacity(0.3),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
