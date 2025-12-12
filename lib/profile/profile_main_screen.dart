import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String level;

  final String? dateOfBirth;
  final String? sex;
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

  File? _profileImageFile;       // صورة محلية (بعد ما يختارها)
  String? _profileImageUrl;      // رابط الصورة من الباك/المحلي

  late String _name;
  late String _email;
  late String _level;
  String? _dateOfBirth;
  String? _sex;
  int? _dailyGoal;

  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _level = widget.level;
    _dateOfBirth = widget.dateOfBirth;
    _sex = widget.sex;
    _dailyGoal = widget.dailyGoal;

    _loadProfilePictureFromPrefs();
  }

  Future<void> _loadProfilePictureFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('user_profilePicture');
    if (!mounted) return;
    setState(() => _profileImageUrl = (url != null && url.isNotEmpty) ? url : null);
  }

  // ========================= رفع الصورة + حفظها بالباك =========================
  Future<void> _pickAndUpload(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final file = File(picked.path);

    // اعرضها فورًا محليًا
    setState(() {
      _profileImageFile = file;
      _uploadingPhoto = true;
    });

    try {
      // 1) ارفع على Cloudinary
      final url = await CloudinaryService.uploadImage(file);
      if (url == null) {
        if (!mounted) return;
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Try again.')),
        );
        return;
      }

      // 2) خزّن في الباك (profilePicture)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        if (!mounted) return;
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
        return;
      }

      final res = await AuthService.updateMe(
        token: token,
        profilePicture: url,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        // 3) خزّن محليًا + حدّث UI
        await prefs.setString('user_profilePicture', url);

        setState(() {
          _profileImageUrl = url;
          _profileImageFile = null; // خلّي العرض من NetworkImage
          _uploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile picture updated')),
        );
      } else {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Update failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

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
                    Navigator.pop(context);
                    await _pickAndUpload(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Take a Photo"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAndUpload(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================= Logout =========================
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_level');
    await prefs.remove('user_dailyGoal');
    await prefs.remove('user_sex');
    await prefs.remove('user_dob');
    await prefs.remove('user_profilePicture');
    await prefs.remove('completed_level_exam');

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/welcome',
      (route) => false,
    );
  }

  ImageProvider? _avatarProvider() {
    if (_profileImageFile != null) return FileImage(_profileImageFile!);
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF3F5F7),
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _avatarProvider(),
                    child: _avatarProvider() == null
                        ? const Icon(Icons.person, size: 70, color: Colors.white)
                        : null,
                  ),

                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _uploadingPhoto ? null : _changeProfilePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _uploadingPhoto
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.edit, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(_level, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),

              const SizedBox(height: 30),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
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
                            'dob': _dateOfBirth,
                            'sex': _sex,
                            'dailyGoal': _dailyGoal,
                            'level': _level,
                          },
                        );

                        if (result is Map) {
                          setState(() {
                            _name = (result['name'] ?? _name) as String;
                            _email = (result['email'] ?? _email) as String;
                            _dateOfBirth = result['dob'] as String? ?? _dateOfBirth;
                            _sex = result['sex'] as String? ?? _sex;
                            _dailyGoal = result['dailyGoal'] as int? ?? _dailyGoal;
                            _level = (result['level'] ?? _level) as String;
                          });
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
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Sign Out", style: TextStyle(fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(color: primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
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
          if (i == 0) Navigator.pop(context);
          setState(() => _index = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: "Chatbot"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

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
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
