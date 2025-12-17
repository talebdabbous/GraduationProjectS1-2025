import 'package:flutter/material.dart';
import 'letter_practice_screen.dart';
import '../services/letter_progress_service.dart';
import '../services/current_journey_service.dart';

enum LetterForm {
  isolated,
  beginning,
  middle,
  end,
}

class LetterWritingScreen extends StatefulWidget {
  const LetterWritingScreen({super.key});

  @override
  State<LetterWritingScreen> createState() => _LetterWritingScreenState();
}

class _LetterWritingScreenState extends State<LetterWritingScreen> {
  // جميع الأحرف العربية الأساسية
  static const List<String> _letters = [
    'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر',
    'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف',
    'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'
  ];

  // ألوان من level exam و vocabulary
  static const backgroundColor = Color(0xFFF5F1E8); // بيج فاتح
  static const primaryColor = Color(0xFF14B8A6); // Teal
  static const darkTealColor = Color(0xFF0D9488); // Teal غامق

  // Store progress percentage for each letter
  final Map<String, double> _letterProgress = {};

  // Journey data for progress widget
  int _userStreak = 0;
  int _userPoints = 0;
  String _userMainLevel = 'Beginner';
  String _userSubLevel = 'Low';
  bool _isLoadingJourneyData = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadJourneyData();
  }

  Future<void> _loadJourneyData() async {
    setState(() => _isLoadingJourneyData = true);
    try {
      final journeyData = await CurrentJourneyService.fetchCurrent();
      if (mounted) {
        setState(() {
          _userStreak = journeyData.data.streak;
          _userPoints = journeyData.data.points;
          _userMainLevel = journeyData.data.mainLevel;
          _userSubLevel = journeyData.data.subLevel;
          _isLoadingJourneyData = false;
        });
      }
    } catch (e) {
      print('⚠️ Failed to load journey data: $e');
      if (mounted) {
        setState(() => _isLoadingJourneyData = false);
      }
    }
  }

  Future<void> _loadProgress() async {
    final Map<String, double> progressMap = {};
    
    for (final letter in _letters) {
      final forms = _getLetterForms(letter);
      final hasMiddle = forms['hasMiddle'] == true;
      final percentage = await LetterProgressService.getCompletionPercentage(letter, hasMiddle);
      progressMap[letter] = percentage;
    }
    
    if (mounted) {
      setState(() {
        _letterProgress.clear();
        _letterProgress.addAll(progressMap);
      });
    }
  }

  Future<int> _getCompletedCount() async {
    int count = 0;
    for (final letter in _letters) {
      final forms = _getLetterForms(letter);
      final hasMiddle = forms['hasMiddle'] == true;
      final percentage = await LetterProgressService.getCompletionPercentage(letter, hasMiddle);
      if (percentage >= 100.0) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button and Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Text(
                      'Letter Writing',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button width
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Progress Widget
            if (!_isLoadingJourneyData)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: FutureBuilder<int>(
                  future: _getCompletedCount(),
                  builder: (context, snapshot) {
                    final completedCount = snapshot.data ?? 0;
                    final progressText = '$completedCount/${_letters.length}';
                    return _LetterWritingProgressWidget(
                      streak: _userStreak,
                      points: _userPoints,
                      mainLevel: _userMainLevel,
                      subLevel: _userSubLevel,
                      progressText: progressText,
                      accent: darkTealColor,
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Top Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn how to write Arabic letters step by step',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Letters Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _letters.length,
                  itemBuilder: (context, index) {
                    final letter = _letters[index];
                    final progress = _letterProgress[letter] ?? 0.0;
                    final isCompleted = progress >= 100.0;
                    
                    return GestureDetector(
                      onTap: () {
                        _showLetterPositionBottomSheet(context, letter);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCompleted ? primaryColor : Colors.grey.shade300,
                            width: isCompleted ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 46,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted ? primaryColor : Colors.black87,
                                    ),
                                  ),
                                  if (progress > 0) ...[
                                    const SizedBox(height: 6),
                                    // Progress bar and percentage
                                    Column(
                                      children: [
                                        // Progress bar
                                        Container(
                                          width: 50,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: progress / 100.0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: darkTealColor,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Percentage text
                                        Text(
                                          '${progress.toInt()}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: darkTealColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isCompleted)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacementNamed(context, '/home_screen');
          } else if (i == 3) {
            Navigator.pushNamed(context, '/profile_main_screen');
          }
          // Community and Chatbot can be added later
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

  // Helper function to get letter forms map
  Map<String, dynamic> _getLetterForms(String letter) {
    // Map of letters to their forms (beginning, middle, end, hasMiddle)
    final forms = {
      'ا': {'beginning': 'ا', 'middle': 'ـا', 'end': 'ـا', 'hasMiddle': false},
      'ب': {'beginning': 'بـ', 'middle': 'ـبـ', 'end': 'ـب', 'hasMiddle': true},
      'ت': {'beginning': 'تـ', 'middle': 'ـتـ', 'end': 'ـت', 'hasMiddle': true},
      'ث': {'beginning': 'ثـ', 'middle': 'ـثـ', 'end': 'ـث', 'hasMiddle': true},
      'ج': {'beginning': 'جـ', 'middle': 'ـجـ', 'end': 'ـج', 'hasMiddle': true},
      'ح': {'beginning': 'حـ', 'middle': 'ـحـ', 'end': 'ـح', 'hasMiddle': true},
      'خ': {'beginning': 'خـ', 'middle': 'ـخـ', 'end': 'ـخ', 'hasMiddle': true},
      'د': {'beginning': 'د', 'middle': 'ـد', 'end': 'ـد', 'hasMiddle': false},
      'ذ': {'beginning': 'ذ', 'middle': 'ـذ', 'end': 'ـذ', 'hasMiddle': false},
      'ر': {'beginning': 'ر', 'middle': 'ـر', 'end': 'ـر', 'hasMiddle': false},
      'ز': {'beginning': 'ز', 'middle': 'ـز', 'end': 'ـز', 'hasMiddle': false},
      'س': {'beginning': 'سـ', 'middle': 'ـسـ', 'end': 'ـس', 'hasMiddle': true},
      'ش': {'beginning': 'شـ', 'middle': 'ـشـ', 'end': 'ـش', 'hasMiddle': true},
      'ص': {'beginning': 'صـ', 'middle': 'ـصـ', 'end': 'ـص', 'hasMiddle': true},
      'ض': {'beginning': 'ضـ', 'middle': 'ـضـ', 'end': 'ـض', 'hasMiddle': true},
      'ط': {'beginning': 'طـ', 'middle': 'ـطـ', 'end': 'ـط', 'hasMiddle': true},
      'ظ': {'beginning': 'ظـ', 'middle': 'ـظـ', 'end': 'ـظ', 'hasMiddle': true},
      'ع': {'beginning': 'عـ', 'middle': 'ـعـ', 'end': 'ـع', 'hasMiddle': true},
      'غ': {'beginning': 'غـ', 'middle': 'ـغـ', 'end': 'ـغ', 'hasMiddle': true},
      'ف': {'beginning': 'فـ', 'middle': 'ـفـ', 'end': 'ـف', 'hasMiddle': true},
      'ق': {'beginning': 'قـ', 'middle': 'ـقـ', 'end': 'ـق', 'hasMiddle': true},
      'ك': {'beginning': 'كـ', 'middle': 'ـكـ', 'end': 'ـك', 'hasMiddle': true},
      'ل': {'beginning': 'لـ', 'middle': 'ـلـ', 'end': 'ـل', 'hasMiddle': true},
      'م': {'beginning': 'مـ', 'middle': 'ـمـ', 'end': 'ـم', 'hasMiddle': true},
      'ن': {'beginning': 'نـ', 'middle': 'ـنـ', 'end': 'ـن', 'hasMiddle': true},
      'ه': {'beginning': 'هـ', 'middle': 'ـهـ', 'end': 'ـه', 'hasMiddle': true},
      'و': {'beginning': 'و', 'middle': 'ـو', 'end': 'ـو', 'hasMiddle': false},
      'ي': {'beginning': 'يـ', 'middle': 'ـيـ', 'end': 'ـي', 'hasMiddle': true},
    };
    return forms[letter] ?? {'beginning': letter, 'middle': 'ـ$letter', 'end': 'ـ$letter', 'hasMiddle': true};
  }

  // Helper function to get letter form glyph
  String _getLetterFormGlyph(String letter, LetterForm form) {
    final formsMap = {
      'ا': {'isolated': 'ا', 'beginning': 'ا', 'middle': 'ـا', 'end': 'ـا'},
      'ب': {'isolated': 'ب', 'beginning': 'بـ', 'middle': 'ـبـ', 'end': 'ـب'},
      'ت': {'isolated': 'ت', 'beginning': 'تـ', 'middle': 'ـتـ', 'end': 'ـت'},
      'ث': {'isolated': 'ث', 'beginning': 'ثـ', 'middle': 'ـثـ', 'end': 'ـث'},
      'ج': {'isolated': 'ج', 'beginning': 'جـ', 'middle': 'ـجـ', 'end': 'ـج'},
      'ح': {'isolated': 'ح', 'beginning': 'حـ', 'middle': 'ـحـ', 'end': 'ـح'},
      'خ': {'isolated': 'خ', 'beginning': 'خـ', 'middle': 'ـخـ', 'end': 'ـخ'},
      'د': {'isolated': 'د', 'beginning': 'د', 'middle': 'ـد', 'end': 'ـد'},
      'ذ': {'isolated': 'ذ', 'beginning': 'ذ', 'middle': 'ـذ', 'end': 'ـذ'},
      'ر': {'isolated': 'ر', 'beginning': 'ر', 'middle': 'ـر', 'end': 'ـر'},
      'ز': {'isolated': 'ز', 'beginning': 'ز', 'middle': 'ـز', 'end': 'ـز'},
      'س': {'isolated': 'س', 'beginning': 'سـ', 'middle': 'ـسـ', 'end': 'ـس'},
      'ش': {'isolated': 'ش', 'beginning': 'شـ', 'middle': 'ـشـ', 'end': 'ـش'},
      'ص': {'isolated': 'ص', 'beginning': 'صـ', 'middle': 'ـصـ', 'end': 'ـص'},
      'ض': {'isolated': 'ض', 'beginning': 'ضـ', 'middle': 'ـضـ', 'end': 'ـض'},
      'ط': {'isolated': 'ط', 'beginning': 'طـ', 'middle': 'ـطـ', 'end': 'ـط'},
      'ظ': {'isolated': 'ظ', 'beginning': 'ظـ', 'middle': 'ـظـ', 'end': 'ـظ'},
      'ع': {'isolated': 'ع', 'beginning': 'عـ', 'middle': 'ـعـ', 'end': 'ـع'},
      'غ': {'isolated': 'غ', 'beginning': 'غـ', 'middle': 'ـغـ', 'end': 'ـغ'},
      'ف': {'isolated': 'ف', 'beginning': 'فـ', 'middle': 'ـفـ', 'end': 'ـف'},
      'ق': {'isolated': 'ق', 'beginning': 'قـ', 'middle': 'ـقـ', 'end': 'ـق'},
      'ك': {'isolated': 'ك', 'beginning': 'كـ', 'middle': 'ـكـ', 'end': 'ـك'},
      'ل': {'isolated': 'ل', 'beginning': 'لـ', 'middle': 'ـلـ', 'end': 'ـل'},
      'م': {'isolated': 'م', 'beginning': 'مـ', 'middle': 'ـمـ', 'end': 'ـم'},
      'ن': {'isolated': 'ن', 'beginning': 'نـ', 'middle': 'ـنـ', 'end': 'ـن'},
      'ه': {'isolated': 'ه', 'beginning': 'هـ', 'middle': 'ـهـ', 'end': 'ـه'},
      'و': {'isolated': 'و', 'beginning': 'و', 'middle': 'ـو', 'end': 'ـو'},
      'ي': {'isolated': 'ي', 'beginning': 'يـ', 'middle': 'ـيـ', 'end': 'ـي'},
    };
    
    final letterForms = formsMap[letter] ?? {
      'isolated': letter,
      'beginning': letter,
      'middle': 'ـ$letter',
      'end': 'ـ$letter',
    };
    
    switch (form) {
      case LetterForm.isolated:
        return letterForms['isolated'] as String;
      case LetterForm.beginning:
        return letterForms['beginning'] as String;
      case LetterForm.middle:
        return letterForms['middle'] as String;
      case LetterForm.end:
        return letterForms['end'] as String;
    }
  }

  void _showLetterPositionBottomSheet(BuildContext context, String letter) async {
    final forms = _getLetterForms(letter);
    final hasMiddle = forms['hasMiddle'] == true;
    
    // Load progress for this letter
    final progress = await LetterProgressService.getLetterProgress(letter);

    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Letter: $letter',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the position form to practice',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Forms Preview Row
            Text(
              'Forms preview • معاينة الأشكال',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPreviewChip('Isolated', letter, true, progress[LetterForm.isolated] ?? false),
                _buildPreviewChip('Beginning', forms['beginning'] ?? letter, true, progress[LetterForm.beginning] ?? false),
                _buildPreviewChip('Middle', forms['middle'] ?? 'ـ$letter', hasMiddle, progress[LetterForm.middle] ?? false),
                _buildPreviewChip('End', forms['end'] ?? 'ـ$letter', true, progress[LetterForm.end] ?? false),
              ],
            ),
            const SizedBox(height: 24),
            
            // Selectable Options
            _buildPositionOption(
              context,
              letter,
              LetterForm.isolated,
              'Isolated (Full letter)',
              'الحرف الكامل',
              letter,
              true,
              progress[LetterForm.isolated] ?? false,
            ),
            const SizedBox(height: 12),
            _buildPositionOption(
              context,
              letter,
              LetterForm.beginning,
              'Beginning',
              'أول الكلمة',
              forms['beginning'] ?? letter,
              true,
              progress[LetterForm.beginning] ?? false,
            ),
            const SizedBox(height: 12),
            _buildPositionOption(
              context,
              letter,
              LetterForm.middle,
              'Middle',
              'وسط الكلمة',
              forms['middle'] ?? 'ـ$letter',
              hasMiddle,
              progress[LetterForm.middle] ?? false,
            ),
            const SizedBox(height: 12),
            _buildPositionOption(
              context,
              letter,
              LetterForm.end,
              'End',
              'آخر الكلمة',
              forms['end'] ?? 'ـ$letter',
              true,
              progress[LetterForm.end] ?? false,
            ),
            const SizedBox(height: 24),
            
            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewChip(String label, String glyph, bool enabled, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled 
              ? (isCompleted ? primaryColor : Colors.grey.shade300)
              : Colors.grey.shade200,
          width: enabled && isCompleted ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            enabled ? glyph : '—',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: enabled 
                  ? (isCompleted ? primaryColor : Colors.black87)
                  : Colors.grey.shade400,
            ),
          ),
          if (enabled && isCompleted) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check_circle,
              size: 14,
              color: primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionOption(
    BuildContext context,
    String letter,
    LetterForm form,
    String label,
    String labelAr,
    String glyph,
    bool enabled,
    bool isCompleted,
  ) {
    return InkWell(
      onTap: enabled
          ? () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LetterPracticeScreen(
                    letter: letter,
                    form: form,
                    onComplete: () async {
                      // Reload progress after completion
                      await _loadProgress();
                      // Reload journey data to update points
                      await _loadJourneyData();
                    },
                  ),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(16),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled 
                ? (isCompleted ? primaryColor : Colors.grey.shade300)
                : Colors.grey.shade200,
            width: enabled && isCompleted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: enabled ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  enabled ? glyph : '—',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: enabled ? primaryColor : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$label ($labelAr)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: enabled ? Colors.black87 : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      if (enabled && isCompleted)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled 
                        ? (isCompleted ? 'Completed • مكتمل' : 'Practice this form')
                        : 'Not applicable for this letter',
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled 
                          ? (isCompleted ? primaryColor : Colors.grey.shade600)
                          : Colors.grey.shade400,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: enabled ? Colors.grey.shade400 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress Widget for Letter Writing Screen (without stage progress)
class _LetterWritingProgressWidget extends StatelessWidget {
  final int streak;
  final int points;
  final String mainLevel;
  final String subLevel;
  final String progressText;
  final Color accent;

  const _LetterWritingProgressWidget({
    required this.streak,
    required this.points,
    required this.mainLevel,
    required this.subLevel,
    required this.progressText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Level Row (without stage progress on the right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        mainLevel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        subLevel,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CompletedProgressIndicator(progressText: progressText),
            ],
          ),

          const SizedBox(height: 12),

          // Streak and Points Row
          Row(
            children: [
              Expanded(
                child: _LetterWritingMiniStat(
                  icon: Icons.local_fire_department,
                  color: accent,
                  title: "Streak",
                  value: "$streak",
                  suffix: "days",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LetterWritingMiniStat(
                  icon: Icons.star,
                  color: const Color(0xFFE9C46A),
                  title: "Points",
                  value: "$points",
                  suffix: "XP",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedProgressIndicator extends StatefulWidget {
  final String progressText;
  
  const _CompletedProgressIndicator({
    required this.progressText,
  });

  @override
  State<_CompletedProgressIndicator> createState() => _CompletedProgressIndicatorState();
}

class _CompletedProgressIndicatorState extends State<_CompletedProgressIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  int _previousValue = 0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _parseAndAnimate(widget.progressText);
  }
  
  @override
  void didUpdateWidget(_CompletedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressText != widget.progressText) {
      _parseAndAnimate(widget.progressText);
    }
  }
  
  void _parseAndAnimate(String progressText) {
    final parts = progressText.split('/');
    final current = int.tryParse(parts[0]) ?? 0;
    if (current != _previousValue) {
      _previousValue = current;
      _animationController.reset();
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Color _getProgressColor(double percentage) {
    if (percentage < 0.33) {
      // Low progress - soft neutral/light green
      return const Color(0xFF86EFAC).withOpacity(0.7);
    } else if (percentage < 0.66) {
      // Medium - slightly stronger green
      return const Color(0xFF34D399).withOpacity(0.8);
    } else {
      // High/complete - success green
      return const Color(0xFF10B981);
    }
  }
  
  Color _getBackgroundColor(double percentage) {
    final progressColor = _getProgressColor(percentage);
    return progressColor.withOpacity(0.08);
  }
  
  @override
  Widget build(BuildContext context) {
    // Parse progress: "0/28" -> current: 0, total: 28
    final parts = widget.progressText.split('/');
    final current = int.tryParse(parts[0]) ?? 0;
    final total = int.tryParse(parts[1]) ?? 28;
    final percentage = total > 0 ? (current / total) : 0.0;
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final animatedPercentage = percentage * _progressAnimation.value;
        final progressColor = _getProgressColor(percentage);
        final backgroundColor = _getBackgroundColor(percentage);
        
        return Container(
          height: 44, // Match graduation cap icon container height
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12), // Match icon container border radius
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Check icon in subtle colored circle
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: progressColor,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              // Progress text with animation
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: current),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                builder: (context, animatedValue, child) {
                  return Text(
                    '$animatedValue/$total',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Thin progress bar
              SizedBox(
                width: 35,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: animatedPercentage),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 3,
                        backgroundColor: progressColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LetterWritingMiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String suffix;

  const _LetterWritingMiniStat({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suffix,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

