import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _index = 3;

  // ===== User Data =====
  String _name = '';
  String _email = '';
  String _level = '';
  String? _dateOfBirth;
  String? _gender;
  String? _learningGoal;

  // ===== Profile Image =====
  File? _profileImageFile;
  String? _profileImageUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadProfilePictureFromPrefs();
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return;

    final res = await AuthService.getMe(token: token);
    if (res['success'] != true) return;

    final user = res['data'];
    if (!mounted) return;

    setState(() {
      _name = user['name'] ?? '';
      _email = user['email'] ?? '';
      _level = user['currentMainLevel'] ?? '';
      _dateOfBirth = user['dateOfBirth'];
      _gender = user['gender'];
      _learningGoal = user['learningGoal'];
      _profileImageUrl = user['profilePicture'];
    });
  }

  Future<void> _loadProfilePictureFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('user_profilePicture');
    if (!mounted) return;
    if (url != null && url.isNotEmpty) {
      setState(() => _profileImageUrl = url);
    }
  }

  // ================= PICK & UPLOAD IMAGE =================
  Future<void> _pickAndUpload(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _profileImageFile = file;
      _uploadingPhoto = true;
    });

    try {
      final url = await CloudinaryService.uploadImage(file);
      if (url == null) throw Exception('Upload failed');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final res = await AuthService.updateMe(
        token: token,
        profilePicture: url,
      );

      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Update failed');
      }

      await prefs.setString('user_profilePicture', url);

      if (!mounted) return;
      setState(() {
        _profileImageUrl = url;
        _profileImageFile = null;
        _uploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile picture updated')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _changeProfilePhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/welcome',
      (_) => false,
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
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3F5F7),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ===== Avatar =====
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
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: primary,
                      child: _uploadingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Text(_name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_level, style: TextStyle(color: Colors.grey.shade600)),

            const SizedBox(height: 30),

            // ===== Actions =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _tile(Icons.person_outline, 'Edit Profile', primary, () async {
                    await Navigator.pushNamed(context, '/edit_profile');
                    _loadProfile();
                  }),
                  const SizedBox(height: 14),
                  _tile(Icons.notifications_outlined, 'Notifications', primary, () {}),
                  const SizedBox(height: 14),
                  _tile(Icons.lock_outline, 'Change Password', primary, () {}),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ===== Bottom Nav =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: primary,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          if (i == 0) Navigator.pop(context);
          setState(() => _index = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'Chatbot'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
