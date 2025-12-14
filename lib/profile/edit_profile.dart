import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;

  String _gender = "None"; // Male / Female / None
  String _nativeLanguage = "en"; // ar / en / tr / fr / es / ur / other
  String? _learningGoal; // nullable
  DateTime? _dateOfBirth;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _init();
  }

  Future<void> _init() async {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;

    String name = "";
    String email = "";
    String gender = "None";
    String nativeLanguage = "en";
    String? learningGoal;
    DateTime? dob;

    if (routeArgs is Map) {
      if (routeArgs['name'] != null) name = routeArgs['name'].toString();
      if (routeArgs['email'] != null) email = routeArgs['email'].toString();

      // gender
      if (routeArgs['gender'] != null) {
        final g = routeArgs['gender'].toString();
        if (["Male", "Female", "None"].contains(g)) gender = g;
      } else if (routeArgs['sex'] != null) {
        final s = routeArgs['sex'].toString();
        if (["Male", "Female"].contains(s)) gender = s;
      }

      // nativeLanguage
      if (routeArgs['nativeLanguage'] != null) {
        final nl = routeArgs['nativeLanguage'].toString();
        if (["ar", "en", "tr", "fr", "es", "ur", "other"].contains(nl)) {
          nativeLanguage = nl;
        }
      }

      // learningGoal
      if (routeArgs['learningGoal'] != null) {
        final lg = routeArgs['learningGoal'].toString();
        learningGoal = lg.isEmpty ? null : lg;
      }

      // dob
      final dobRaw = routeArgs['dob'] ?? routeArgs['dateOfBirth'];
      if (dobRaw is String) dob = DateTime.tryParse(dobRaw);
      if (dobRaw is DateTime) dob = dobRaw;
    } else {
      final data = await _loadFromPreferences();

      if (data['name'] != null) name = data['name'] as String;
      if (data['email'] != null) email = data['email'] as String;

      if (data['gender'] != null) {
        final g = data['gender'] as String;
        if (["Male", "Female", "None"].contains(g)) gender = g;
      }

      if (data['nativeLanguage'] != null) {
        final nl = data['nativeLanguage'] as String;
        if (["ar", "en", "tr", "fr", "es", "ur", "other"].contains(nl)) {
          nativeLanguage = nl;
        }
      }

      if (data['learningGoal'] != null) {
        final lg = data['learningGoal'] as String;
        learningGoal = lg.isEmpty ? null : lg;
      }

      if (data['dob'] != null) {
        dob = DateTime.tryParse(data['dob'] as String);
      }
    }

    // ✅ Controllers لازم ينعملوا قبل أي setState أو استخدام text
    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
    _dobController = TextEditingController(text: dob == null ? "" : _formatDate(dob));

    if (!mounted) return;
    setState(() {
      _gender = gender;
      _nativeLanguage = nativeLanguage;
      _learningGoal = learningGoal;
      _dateOfBirth = dob;
    });
  }

  Future<Map<String, dynamic>> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? "",
      'email': prefs.getString('user_email') ?? "",
      'gender': prefs.getString('user_gender') ?? "None",
      'nativeLanguage': prefs.getString('user_nativeLanguage') ?? "en",
      'learningGoal': prefs.getString('user_learningGoal'),
      'dob': prefs.getString('user_dob'),
    };
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are not logged in.")),
        );
        setState(() => _isSaving = false);
        return;
      }

      final res = await AuthService.updateMe(
        token: token,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        dateOfBirth: _dateOfBirth!.toIso8601String().substring(0, 10),
        gender: _gender,
        nativeLanguage: _nativeLanguage,
        learningGoal: _learningGoal,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final data = (res['data'] as Map<String, dynamic>?) ?? {};

        await prefs.setString('user_name', (data['name'] ?? '') as String);
        await prefs.setString('user_email', (data['email'] ?? '') as String);
        await prefs.setString('user_dob', (data['dateOfBirth'] ?? '') as String);
        await prefs.setString('user_gender', (data['gender'] ?? 'None') as String);
        await prefs.setString('user_nativeLanguage', (data['nativeLanguage'] ?? 'en') as String);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );

        Navigator.pop(context, {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dob': _dateOfBirth!.toIso8601String().substring(0, 10),
          'gender': _gender,
          'nativeLanguage': _nativeLanguage,
          'learningGoal': _learningGoal,
        });
      } else {
        final msg = res['message']?.toString() ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // لحد ما _init يخلص، اعرض لودر بدل ما تستخدم controllers قبل تهيئتهم
    if (!_initialized || !(_controllersReady())) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                              ),
                              const SizedBox(height: 14),

                              _input(
                                label: "Email",
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return "Required";
                                  if (!v.contains("@")) return "Invalid email";
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
                                    validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: InputDecoration(
                                  labelText: "Gender",
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: "None", child: Text("None")),
                                  DropdownMenuItem(value: "Male", child: Text("Male")),
                                  DropdownMenuItem(value: "Female", child: Text("Female")),
                                ],
                                onChanged: (val) => setState(() => _gender = val ?? "None"),
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<String>(
                                value: _nativeLanguage,
                                decoration: InputDecoration(
                                  labelText: "Native Language",
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: "ar", child: Text("Arabic")),
                                  DropdownMenuItem(value: "en", child: Text("English")),
                                  DropdownMenuItem(value: "tr", child: Text("Turkish")),
                                  DropdownMenuItem(value: "fr", child: Text("French")),
                                  DropdownMenuItem(value: "es", child: Text("Spanish")),
                                  DropdownMenuItem(value: "ur", child: Text("Urdu")),
                                  DropdownMenuItem(value: "other", child: Text("Other")),
                                ],
                                onChanged: (val) => setState(() => _nativeLanguage = val ?? "en"),
                              ),
                              const SizedBox(height: 14),

                              DropdownButtonFormField<String?>(
                                value: _learningGoal,
                                decoration: InputDecoration(
                                  labelText: "Learning Goal",
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text("None")),
                                  DropdownMenuItem(value: "travel", child: Text("Travel")),
                                  DropdownMenuItem(value: "study", child: Text("Study")),
                                  DropdownMenuItem(value: "work", child: Text("Work")),
                                  DropdownMenuItem(value: "conversation", child: Text("Conversation")),
                                  DropdownMenuItem(value: "religion", child: Text("Religion")),
                                  DropdownMenuItem(value: "culture", child: Text("Culture")),
                                  DropdownMenuItem(value: "exam", child: Text("Exam")),
                                  DropdownMenuItem(value: "other", child: Text("Other")),
                                ],
                                onChanged: (val) => setState(() => _learningGoal = val),
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          "Save Changes",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  bool _controllersReady() {
    // لو صار build قبل init للcontrollers (احتياط)
    try {
      // ignore: unnecessary_statements
      _nameController.text;
      // ignore: unnecessary_statements
      _emailController.text;
      // ignore: unnecessary_statements
      _dobController.text;
      return true;
    } catch (_) {
      return false;
    }
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

