import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dailyGoalController;
  late TextEditingController _dobController;

  String? _sex;
  DateTime? _dateOfBirth;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final routeArgs = ModalRoute.of(context)?.settings.arguments;

    String name = "";
    String email = "";
    int dailyGoal = 15;
    String sex = "Male";
    DateTime? dob;

    if (routeArgs is Map) {
      if (routeArgs['name'] != null) name = routeArgs['name'].toString();
      if (routeArgs['email'] != null) email = routeArgs['email'].toString();

      final dg = routeArgs['dailyGoal'];
      if (dg is int) dailyGoal = dg;
      if (dg is String) dailyGoal = int.tryParse(dg) ?? 15;

      if (routeArgs['sex'] != null) {
        final s = routeArgs['sex'].toString();
        if (s == "Male" || s == "Female") sex = s;
      }

      final dobRaw = routeArgs['dob'];
      if (dobRaw is String) dob = DateTime.tryParse(dobRaw);
      if (dobRaw is DateTime) dob = dobRaw;
    }

    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
    _dailyGoalController = TextEditingController(text: dailyGoal.toString());
    _sex = sex;
    _dateOfBirth = dob;
    _dobController = TextEditingController(
      text: dob == null ? "" : _formatDate(dob),
    );

    _initialized = true;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  Future<void> _selectDate() async {
    final initialDate = _dateOfBirth ?? DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please choose your date of birth")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // TODO: عدّل الـ baseUrl حسب السيرفر تبعك
      const baseUrl = "https://your-backend-domain.com";
      final url = Uri.parse("$baseUrl/api/users/me");

      // TODO: استبدل هذا بالتوكن الحقيقي من التخزين
      const token = "YOUR_JWT_TOKEN_HERE";

      final body = jsonEncode({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "dob": _dateOfBirth!.toIso8601String(),
        "sex": _sex,
        "dailyGoal":
            int.tryParse(_dailyGoalController.text.trim()) ?? 15,
      });

      final res = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error ${res.statusCode}: ${res.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dailyGoalController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3F5F7),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),

                              _input(
                                label: "Full Name",
                                controller: _nameController,
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? "Required"
                                        : null,
                              ),
                              const SizedBox(height: 14),

                              _input(
                                label: "Email",
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return "Required";
                                  }
                                  if (!v.contains("@")) {
                                    return "Invalid email";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              GestureDetector(
                                onTap: _selectDate,
                                child: AbsorbPointer(
                                  child: _input(
                                    label: "Date of Birth",
                                    controller: _dobController,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? "Required"
                                            : null,
                                    suffixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<String>(
                                value: _sex,
                                decoration: InputDecoration(
                                  labelText: "Sex",
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: "Male",
                                    child: Text("Male"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Female",
                                    child: Text("Female"),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _sex = val),
                              ),
                              const SizedBox(height: 14),

                              _input(
                                label: "Daily Goal (minutes)",
                                controller: _dailyGoalController,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          "Save Changes",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
