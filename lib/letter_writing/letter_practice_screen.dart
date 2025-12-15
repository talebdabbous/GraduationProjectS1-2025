import 'package:flutter/material.dart';
import '../widgets/handwriting_canvas.dart';
import 'letter_writing_screen.dart';
import '../services/letter_progress_service.dart';

class LetterPracticeScreen extends StatefulWidget {
  final String letter;
  final LetterForm form;
  final VoidCallback? onComplete;

  const LetterPracticeScreen({
    super.key,
    required this.letter,
    this.form = LetterForm.isolated,
    this.onComplete,
  });

  @override
  State<LetterPracticeScreen> createState() => _LetterPracticeScreenState();
}

class _LetterPracticeScreenState extends State<LetterPracticeScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final GlobalKey<HandwritingCanvasState> _traceCanvasKey = GlobalKey();
  final GlobalKey<HandwritingCanvasState> _writeCanvasKey = GlobalKey();
  late AnimationController _animationController;
  bool _showTraceFeedback = false;
  bool? _writeResult;
  int _writeScore = 0;

  // ألوان من level exam و vocabulary
  static const backgroundColor = Color(0xFFF5F1E8); // بيج فاتح
  static const primaryColor = Color(0xFF14B8A6); // Teal
  static const darkTealColor = Color(0xFF0D9488); // Teal غامق

  // Helper to get letter form glyph
  String _getFormGlyph() {
    final forms = {
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
    
    final letterForms = forms[widget.letter] ?? {
      'isolated': widget.letter,
      'beginning': widget.letter,
      'middle': 'ـ${widget.letter}',
      'end': 'ـ${widget.letter}',
    };
    
    switch (widget.form) {
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

  String _getFormLabel() {
    final glyph = _getFormGlyph();
    switch (widget.form) {
      case LetterForm.isolated:
        return 'Training: Isolated form ($glyph) • الحرف الكامل';
      case LetterForm.beginning:
        return 'Training: Beginning form ($glyph) • أول الكلمة';
      case LetterForm.middle:
        return 'Training: Middle form ($glyph) • وسط الكلمة';
      case LetterForm.end:
        return 'Training: End form ($glyph) • آخر الكلمة';
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _showTraceFeedback = false;
        _writeResult = null;
        _writeScore = 0;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _showTraceFeedback = false;
        _writeResult = null;
        _writeScore = 0;
      });
    }
  }

  void _onTraceChanged() {
    final canvas = _traceCanvasKey.currentState;
    if (canvas != null && canvas.getTotalPointCount() > 80) {
      setState(() {
        _showTraceFeedback = true;
      });
    }
  }

  void _checkWrite() {
    final canvas = _writeCanvasKey.currentState;
    if (canvas == null) return;

    final pointCount = canvas.getTotalPointCount();
    final boundingBox = canvas.getBoundingBox();
    final strokeCount = canvas.getStrokeCount();

    if (pointCount < 50) {
      setState(() {
        _writeResult = false;
        _writeScore = 0;
      });
      return;
    }

    if (boundingBox == null || strokeCount == 0) {
      setState(() {
        _writeResult = false;
        _writeScore = 0;
      });
      return;
    }

    // Simple heuristic evaluation
    final width = boundingBox.width;
    final height = boundingBox.height;
    final isValidSize = width > 50 && height > 50 && width < 500 && height < 500;

    if (isValidSize && strokeCount > 0) {
      // Calculate score (0-100)
      int score = 60; // Base score
      if (pointCount > 100) score += 20;
      if (width > 100 && height > 100) score += 10;
      if (strokeCount >= 2) score += 10;
      score = score.clamp(0, 100);

      setState(() {
        _writeResult = true;
        _writeScore = score;
      });

      // Save progress
      LetterProgressService.markFormCompleted(widget.letter, widget.form);

      widget.onComplete?.call();
    } else {
      setState(() {
        _writeResult = false;
        _writeScore = 40;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Letter: ${widget.letter}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            Text(
              _getFormLabel(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Watch'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > 0 ? primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  _buildStepIndicator(1, 'Trace'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > 1 ? primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  _buildStepIndicator(2, 'Write'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildStepContent(),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep == 1
                          ? (_showTraceFeedback ? _nextStep : null)
                          : _currentStep == 2
                              ? null
                              : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkTealColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(_currentStep == 2 ? 'Check' : 'Next'),
                    ),
                  ),
                ],
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

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? primaryColor : Colors.grey.shade300,
            border: Border.all(
              color: isActive ? darkTealColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? darkTealColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWatchStep();
      case 1:
        return _buildTraceStep();
      case 2:
        return _buildWriteStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildWatchStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(200, 200),
                    painter: _LetterAnimationPainter(
                      letter: _getFormGlyph(),
                      progress: _animationController.value,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Watch how to write "${_getFormGlyph()}"',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraceStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Trace the letter',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            flex: 4,
            child: Stack(
              children: [
                // Background guide (faint dotted letter)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _getFormGlyph(),
                      style: TextStyle(
                        fontSize: 200,
                        color: Colors.grey.shade200,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Drawing canvas
                HandwritingCanvas(
                  key: _traceCanvasKey,
                  strokeColor: darkTealColor,
                  strokeWidth: 4.0,
                  backgroundColor: Colors.transparent,
                  borderColor: Colors.transparent,
                  onDrawingChanged: _onTraceChanged,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: _showTraceFeedback
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Good! Now try writing it alone.',
                              style: TextStyle(
                                color: darkTealColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _traceCanvasKey.currentState?.clear(),
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWriteStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Write the letter on your own',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              children: [
                AbsorbPointer(
                  absorbing: _writeResult != null,
                  child: HandwritingCanvas(
                    key: _writeCanvasKey,
                    strokeColor: darkTealColor,
                    strokeWidth: 4.0,
                    hintText: _writeResult == null ? 'Write "${_getFormGlyph()}" here' : null,
                    enabled: true,
                    onDrawingChanged: () {
                      if (_writeResult == null) {
                        setState(() {
                          _writeResult = null;
                          _writeScore = 0;
                        });
                      }
                    },
                  ),
                ),
                // Overlay background (مغبشة)
                if (_writeResult != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                // Popup result card
                if (_writeResult != null)
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon with background circle
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: _writeResult!
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _writeResult! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 44,
                                color: _writeResult! 
                                    ? Colors.green.shade600 
                                    : Colors.red.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _writeResult! ? 'Great Job!' : 'Try Again',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _writeResult! 
                                    ? Colors.green.shade700 
                                    : Colors.red.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_writeResult!)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Score: $_writeScore/100',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (!_writeResult!)
                              Text(
                                'Write it more clearly',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (_writeResult!) {
                                    // الرجوع إلى قائمة الأحرف
                                    Navigator.pop(context);
                                  } else {
                                    // إعادة المحاولة - مسح الرسم وإعادة المحاولة
                                    _writeCanvasKey.currentState?.clear();
                                    setState(() {
                                      _writeResult = null;
                                      _writeScore = 0;
                                    });
                                  }
                                },
                                icon: Icon(
                                  _writeResult! ? Icons.arrow_back_rounded : Icons.refresh_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  _writeResult! ? 'Try Another Letter' : 'Try Again',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTealColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _writeCanvasKey.currentState?.clear();
                  setState(() {
                    _writeResult = null;
                    _writeScore = 0;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _writeResult == null ? _checkWrite : null,
                icon: const Icon(Icons.check),
                label: const Text('Check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTealColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Animation painter for letter stroke
class _LetterAnimationPainter extends CustomPainter {
  final String letter;
  final double progress;

  _LetterAnimationPainter({
    required this.letter,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Simple placeholder animation - showing letter with animated stroke overlay
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.height * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade300,
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // Animated stroke overlay (simple line animation)
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.height * 0.2;

    if (progress < 0.5) {
      // Drawing first half of stroke
      path.moveTo(centerX - radius, centerY);
      path.lineTo(
        centerX - radius + (radius * 2 * progress * 2),
        centerY,
      );
    } else {
      // Drawing second half
      path.moveTo(centerX - radius, centerY);
      path.lineTo(centerX + radius, centerY);
      path.moveTo(centerX, centerY - radius);
      path.lineTo(
        centerX,
        centerY - radius + (radius * 2 * (progress - 0.5) * 2),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LetterAnimationPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

