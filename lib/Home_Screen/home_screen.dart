import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final int dailyStreak;
  final int points;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.dailyStreak,
    required this.points,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

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
                    // Left side
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
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _stat("🔥 Streak", "${widget.dailyStreak} days"),
                              const SizedBox(width: 8),
                              _stat("⭐ Points", "${widget.points}"),
                            ],
                          )
                        ],
                      ),
                    ),

                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: primary, size: 28),
                    )
                  ],
                ),
              ),
            ),

            // ---------------- GRID FULL HEIGHT ----------------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // ----------- ROW 1 -----------
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _gradientCard(
                              title: "Current Journey",
                              subtitle: "Continue where you left off",
                              icon: Icons.flag_outlined,
                              colors: [primary, primary.withOpacity(0.6)],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _gradientCard(
                              title: "Letter Writing",
                              subtitle: "Practice Arabic letters",
                              icon: Icons.edit_note_outlined,
                              colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ----------- ROW 2 -----------
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _gradientCard(
                              title: "Vocabulary",
                              subtitle: "Grow your word bank",
                              icon: Icons.menu_book_outlined,
                              colors: [Colors.orange, Colors.deepOrangeAccent],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _gradientCard(
                              title: "Letter Sounds",
                              subtitle: "Listen & recognize sounds",
                              icon: Icons.volume_up_outlined,
                              colors: [Colors.green, Colors.lightGreen],
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
  onTap: (i) {
    setState(() => _index = i);

    if (i == 3) {
      Navigator.pushNamed(context, '/profile_main_screen');
    }
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

  // ================= HELPER WIDGETS =================

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
