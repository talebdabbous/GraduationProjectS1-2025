import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String email;
  final int dailyStreak;
  final int points;
  final String currentLevel;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.email,
    required this.dailyStreak,
    required this.points,
    required this.currentLevel,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _dailyGoalController;
  late String _selectedLevel;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _usernameController = TextEditingController(text: widget.userName.toLowerCase());
    _emailController = TextEditingController(text: widget.email);
    _dailyGoalController = TextEditingController(text: "15"); // minutes per day (sample)
    _selectedLevel = widget.currentLevel; // e.g. "Beginner A1"
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _dailyGoalController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      // لو كان بيسيف، هون بتحط كول للباك إند بنفس المكان (TODO)
      _isEditing = !_isEditing;
    });
  }

  void _logout() {
    // TODO: هنا بتحط منطق تسجيل الخروج الحقيقي
    // مثال:
    // 1. مسح التوكن من الذاكرة
    // 2. Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out ( demo only )")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ----------- HEADER CARD -----------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        primary,
                        primary.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        color: primary.withOpacity(0.35),
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name + email + stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _profileStatChip(
                                  icon: Icons.local_fire_department_outlined,
                                  label: "Streak",
                                  value: "${widget.dailyStreak} days",
                                ),
                                const SizedBox(width: 8),
                                _profileStatChip(
                                  icon: Icons.star_border,
                                  label: "Points",
                                  value: widget.points.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ----------- PERSONAL INFO CARD -----------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Edit button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Personal info",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _toggleEdit,
                            icon: Icon(
                              _isEditing ? Icons.check : Icons.edit_outlined,
                              size: 18,
                            ),
                            label: Text(_isEditing ? "Save" : "Edit"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _buildTextField(
                        label: "Full name",
                        controller: _nameController,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: "Username",
                        controller: _usernameController,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: "Email",
                        controller: _emailController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: "Daily goal (minutes / day)",
                        controller: _dailyGoalController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        "Current level",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      IgnorePointer(
                        ignoring: !_isEditing,
                        child: DropdownButtonFormField<String>(
                          value: _selectedLevel,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _isEditing
                                ? Colors.grey.shade100
                                : Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "Beginner A1",
                              child: Text("Beginner A1"),
                            ),
                            DropdownMenuItem(
                              value: "Elementary A2",
                              child: Text("Elementary A2"),
                            ),
                            DropdownMenuItem(
                              value: "Intermediate B1",
                              child: Text("Intermediate B1"),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              _selectedLevel = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ----------- SETTINGS CARD -----------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "App & learning settings",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Enable notifications"),
                        subtitle: const Text("Remind me to practice daily"),
                        value: _notificationsEnabled,
                        onChanged: (val) {
                          setState(() {
                            _notificationsEnabled = val;
                          });
                        },
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Enable sound"),
                        subtitle:
                            const Text("Play sounds for letters and feedback"),
                        value: _soundEnabled,
                        onChanged: (val) {
                          setState(() {
                            _soundEnabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ----------- LOGOUT BUTTON -----------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      "Log out",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------- SMALL REUSABLE WIDGETS ---------

  Widget _profileStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}
