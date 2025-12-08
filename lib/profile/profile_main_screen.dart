import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String level;

  // جايين من الباك
  final String? dateOfBirth; // "YYYY-MM-DD"
  final String? sex;         // "Male" / "Female"
  final int? dailyGoal;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.level,
    this.dateOfBirth,
    this.sex,
    this.dailyGoal,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _index = 3;
  File? _profileImage;

  // بننسخ قيم الويجت ل متغيرات قابلة للتعديل داخل الstate
  late String _name;
  late String _email;
  late String _level;
  String? _dateOfBirth;
  String? _sex;
  int? _dailyGoal;

  @override
  void initState() {
    super.initState();
    _name        = widget.name;
    _email       = widget.email;
    _level       = widget.level;
    _dateOfBirth = widget.dateOfBirth;
    _sex         = widget.sex;
    _dailyGoal   = widget.dailyGoal;
  }

  // ========================= تغيير الصورة =========================
  Future<void> _changeProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 180,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("Choose from Gallery"),
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setState(() => _profileImage = File(picked.path));
                    }
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Take a Photo"),
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                    );
                    if (picked != null) {
                      setState(() => _profileImage = File(picked.path));
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF3F5F7),
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ================= الصورة + الاسم + الليفل =================
              Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.person,
                            size: 70, color: Colors.white)
                        : null,
                  ),

                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _changeProfilePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                _name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _level,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              // ====================== المربع الأبيض ======================
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileOptionTile(
                      icon: Icons.person_outline,
                      label: "Edit Profile",
                      color: primary,
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/edit_profile',
                          arguments: {
                            'name': _name,
                            'email': _email,
                            'dob': _dateOfBirth,     // من الباك
                            'sex': _sex,             // من الباك
                            'dailyGoal': _dailyGoal, // من الباك
                          },
                        );

                        // لو رجعنا true من شاشة الإيديت، لاحقاً بنقدر نعمل refresh من الباك
                        if (result == true) {
                          // TODO: استدعِ /auth/me وحدّث _name / _level / ... لو حاب
                          setState(() {});
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    _ProfileOptionTile(
                      icon: Icons.notifications_outlined,
                      label: "Notifications",
                      color: primary,
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),

                    _ProfileOptionTile(
                      icon: Icons.lock_outline,
                      label: "Change Password",
                      color: primary,
                      onTap: () {},
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO:
                          // 1) امسح التوكن من SharedPreferences
                          // 2) امسح بيانات المستخدم
                          // 3) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          "Sign Out",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(color: primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 0) {
            // رجوع للهوم
            Navigator.pop(context);
          }
          setState(() => _index = i);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined), label: "Chatbot"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ================= TILE DESIGN =================
class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
