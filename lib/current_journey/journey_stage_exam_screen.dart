import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/journey_exam_service.dart';
import '../services/current_journey_service.dart';

class JourneyStageExamScreen extends StatefulWidget {
  final String level; // beginner/intermediate/advanced
  final int stage;

  const JourneyStageExamScreen({
    super.key,
    required this.level,
    required this.stage,
  });

  @override
  State<JourneyStageExamScreen> createState() => _JourneyStageExamScreenState();
}

// ✅ تتبع حالة كل سؤال
class QuestionState {
  final String questionId;
  bool isCorrect;
  bool answeredInReview; // true إذا تمت الإجابة في المراجعة
  bool gotPoints; // true إذا حصل على نقاط

  QuestionState({
    required this.questionId,
    this.isCorrect = false,
    this.answeredInReview = false,
    this.gotPoints = false,
  });
}

class _JourneyStageExamScreenState extends State<JourneyStageExamScreen> {
  bool loading = true;
  String? error;

  List<JourneyQuestion> questions = [];
  int index = 0;

  String? selectedKey;
  String writtenAnswer = ''; // للـ fill_blank و writing

  bool checked = false;
  bool? isCorrect;

  bool checking = false;

  // ✅ نظام تتبع الإجابات والنقاط
  Map<String, QuestionState> questionStates = {}; // questionId -> QuestionState
  int totalPoints = 0;
  bool isReviewMode = false; // true في وضع المراجعة
  List<int> wrongQuestionIndices = []; // فهارس الأسئلة الخاطئة للمراجعة
  int reviewIndex = 0; // الفهرس الحالي في المراجعة
  
  // ✅ التحقق من حالة المرحلة
  bool? _isStageCompleted; // null = لم يتم التحقق بعد، true = مكتملة، false = غير مكتملة
  int? _unlockedStage; // unlockedStage من الباك

  // ✅ Audio & TTS
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _isPlayingAudio = false;
  bool _isSpeaking = false;

  Color get bg => const Color(0xFFF7F3E9);
  Color get accent => const Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _initTts();
    _initAudioPlayer();
    _loadQuestions();
  }

  // ✅ إعداد AudioPlayer مثل Level Exam
  void _initAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _audioPlayer.setVolume(1.0);
    _audioPlayer.setBalance(0.0);
    
    // استمع لحالة التشغيل
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        print('✅ Audio is now playing!');
      } else if (state == PlayerState.completed) {
        print('✅ Audio playback completed');
        if (mounted) setState(() => _isPlayingAudio = false);
      } else if (state == PlayerState.stopped) {
        print('⏹️ Audio stopped');
        if (mounted) setState(() => _isPlayingAudio = false);
      }
    });
    
    // استمع للأخطاء
    _audioPlayer.onLog.listen((log) {
      print('🎵 AudioPlayer log: $log');
    });
    
    // استمع لأخطاء التشغيل
    _audioPlayer.onPlayerComplete.listen((_) {
      print('✅ Audio playback finished');
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // ✅ أولاً: تحميل بيانات المستوى الحالي للتحقق من unlockedStage و completedStages
      final currentData = await CurrentJourneyService.fetchCurrent();
      
      if (!mounted) return;
      
      _unlockedStage = currentData.data.unlockedStage;
      _isStageCompleted = currentData.data.completedStages.contains(widget.stage);
      
      // ✅ التحقق: يمكن الدخول على المراحل <= unlockedStage أو المراحل المكتملة مسبقاً
      // إذا كان unlockedStage = 2، يمكن الدخول على stage 1 (مكتملة) و stage 2 (الحالية)
      final canAccess = widget.stage <= _unlockedStage! || _isStageCompleted == true;
      if (!canAccess) {
        setState(() {
          error = "Stage ${widget.stage} is locked. Unlocked stage is $_unlockedStage. Please complete previous stages first.";
          loading = false;
        });
        return;
      }
      
      // ✅ تحميل الأسئلة
      final data = await JourneyExamService.fetchStageQuestions(
        level: widget.level,
        stage: widget.stage,
      );

      if (!mounted) return;
      setState(() {
        questions = data;
        loading = false;
        // تهيئة حالة الأسئلة
        questionStates.clear();
        for (var q in data) {
          questionStates[q.id] = QuestionState(questionId: q.id);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  JourneyQuestion get q => questions[index];
  bool get isLast {
    if (isReviewMode) {
      return reviewIndex == wrongQuestionIndices.length - 1;
    }
    return index == questions.length - 1;
  }

  // ✅ نوع السؤال
  bool get _isWritingType => q.type == 'fill_blank' || q.type == 'writing';
  bool get _hasAudio => q.audioUrl != null && q.audioUrl!.isNotEmpty;
  bool get _hasImage => q.imageUrl != null && q.imageUrl!.isNotEmpty;

  // ✅ تشغيل TTS للخيار (قراءة نص الخيار)
  Future<void> _playOptionAudio(JourneyOption opt) async {
    if (opt.text.isEmpty) {
      print('❌ Option text is empty!');
      return;
    }

    print('🗣️ Speaking option text: ${opt.text}');
    
    try {
      // إذا كان TTS شغال، أوقفه أولاً
      if (_isSpeaking) {
        await _tts.stop();
      }
      
      // قراءة نص الخيار
      await _tts.speak(opt.text);
      print('✅ Option TTS started');
      
    } catch (e) {
      print('❌ Error speaking option: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to speak option: $e")),
        );
      }
    }
  }

  // ✅ إيقاف الصوت
  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlayingAudio = false);
    } catch (e) {
      print('❌ Error stopping audio: $e');
    }
  }

  // ✅ تشغيل الصوت (audioUrl للسؤال) - مثل Level Exam
  Future<void> _playAudio() async {
    if (!_hasAudio) return;
    
    final url = q.audioUrl!;
    print('🎵 Attempting to play question audio from: $url');
    
    try {
      await _stopAudio();
      
      // تحقق من أن URL صحيح
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        print('❌ Invalid audio URL format: $url');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid audio URL: $url')),
        );
        return;
      }
      
      // تأكد من مستوى الصوت (1.0 = 100%)
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setBalance(0.0);
      
      print('🔊 Playing question audio...');
      setState(() => _isPlayingAudio = true);
      
      await _audioPlayer.play(UrlSource(url));
      print('✅ Question audio play command sent successfully');
      
    } catch (e) {
      print('❌ Error playing question audio: $e');
      if (mounted) {
        setState(() => _isPlayingAudio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to play audio: $e")),
        );
      }
    }
  }

  // ✅ TTS - قراءة السؤال
  Future<void> _speakPrompt() async {
    if (_isSpeaking) {
      await _tts.stop();
      return;
    }
    await _tts.speak(q.prompt);
  }

  void _select(String key) {
    if (checked) return;
    setState(() => selectedKey = key);
  }

  Future<void> _check() async {
    // تحقق من الإجابة حسب نوع السؤال
    if (_isWritingType) {
      if (writtenAnswer.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please type your answer first.")),
        );
        return;
      }
    } else {
      if (selectedKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an answer first.")),
        );
        return;
      }
    }

    if (checking) return;
    setState(() => checking = true);

    try {
      final res = await JourneyExamService.checkAnswer(
        level: widget.level,
        stage: widget.stage,
        questionId: q.id,
        selectedKey: _isWritingType ? null : selectedKey,
        writtenAnswer: _isWritingType ? writtenAnswer.trim() : null,
      );

      if (!mounted) return;

      // ✅ تحديث حالة السؤال
      final questionState = questionStates[q.id] ?? QuestionState(questionId: q.id);
      questionState.isCorrect = res.correct;
      
      // ✅ إذا كان في وضع المراجعة، لا نعطي نقاط
      if (isReviewMode) {
        questionState.answeredInReview = true;
      } else {
        // ✅ فقط في المرة الأولى: إذا صح، نعطي 10 نقاط
        // ✅ لكن فقط إذا كانت المرحلة غير مكتملة مسبقاً
        if (res.correct && !questionState.gotPoints && _isStageCompleted != true) {
          totalPoints += 10;
          questionState.gotPoints = true;
        }
      }

      questionStates[q.id] = questionState;

      setState(() {
        checked = true;
        isCorrect = res.correct;
        checking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => checking = false);

      // ✅ معالجة خطأ 409 (Stage not unlocked)
      // إذا كانت المرحلة مكتملة مسبقاً، الباك قد يرفض فحص الإجابة
      // في هذه الحالة، نعرض رسالة مختلفة ونسمح بالاستمرار (بدون نقاط)
      final errorStr = e.toString();
      if (errorStr.contains('409') || errorStr.contains('Stage not unlocked')) {
        // إذا كانت المرحلة مكتملة مسبقاً، نعرض رسالة مختلفة
        if (_isStageCompleted == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("This stage is already completed. You can review it, but won't earn points."),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          // نسمح بالاستمرار لكن بدون نقاط (تم التعامل معه في الكود)
          // لكن الباك رفض فحص الإجابة، لذلك لا يمكننا المتابعة
          // يجب تعديل الباك للسماح بفحص الإجابة على المراحل المكتملة
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("This stage is locked. Please complete previous stages first."),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          // العودة للخريطة
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Check failed: $e")),
        );
      }
    }
  }

  void _next() {
    if (!checked) return;

    // ✅ إذا كان في وضع المراجعة
    if (isReviewMode) {
      if (reviewIndex < wrongQuestionIndices.length - 1) {
        // الانتقال للسؤال التالي في المراجعة
        setState(() {
          reviewIndex++;
          index = wrongQuestionIndices[reviewIndex];
          selectedKey = null;
          writtenAnswer = '';
          checked = false;
          isCorrect = null;
          checking = false;
          _isPlayingAudio = false;
        });
        _audioPlayer.stop();
      } else {
        // انتهت المراجعة - تحقق من وجود أخطاء متبقية
        _checkRemainingErrors();
      }
      return;
    }

    // ✅ الوضع العادي: الانتقال للسؤال التالي
    if (isLast) {
      // انتهت جميع الأسئلة - ابدأ المراجعة
      _startReview();
      return;
    }

    setState(() {
      index++;
      selectedKey = null;
      writtenAnswer = '';
      checked = false;
      isCorrect = null;
      checking = false;
      _isPlayingAudio = false;
    });
    
    _audioPlayer.stop();
  }

  // ✅ بدء المراجعة للأخطاء
  void _startReview() {
    // جمع فهارس الأسئلة الخاطئة
    wrongQuestionIndices.clear();
    for (int i = 0; i < questions.length; i++) {
      final state = questionStates[questions[i].id];
      if (state == null || !state.isCorrect) {
        wrongQuestionIndices.add(i);
      }
    }

    if (wrongQuestionIndices.isEmpty) {
      // كل الأسئلة صحيحة - اذهب لشاشة الإتمام مباشرة
      _showCompletionScreen();
      return;
    }

    // ابدأ المراجعة من أول سؤال خاطئ
    setState(() {
      isReviewMode = true;
      reviewIndex = 0;
      index = wrongQuestionIndices[0];
      selectedKey = null;
      writtenAnswer = '';
      checked = false;
      isCorrect = null;
      checking = false;
      _isPlayingAudio = false;
    });
    _audioPlayer.stop();
  }

  // ✅ التحقق من الأخطاء المتبقية بعد المراجعة
  void _checkRemainingErrors() {
    final remainingErrors = wrongQuestionIndices.where((idx) {
      final state = questionStates[questions[idx].id];
      return state == null || !state.isCorrect;
    }).toList();

    if (remainingErrors.isEmpty) {
      // كل الأسئلة صحيحة الآن - اذهب لشاشة الإتمام
      _showCompletionScreen();
    } else {
      // لا تزال هناك أخطاء - استمر في المراجعة
      wrongQuestionIndices = remainingErrors;
      setState(() {
        reviewIndex = 0;
        index = wrongQuestionIndices[0];
        selectedKey = null;
        writtenAnswer = '';
        checked = false;
        isCorrect = null;
        checking = false;
        _isPlayingAudio = false;
      });
      _audioPlayer.stop();
    }
  }

  // ✅ عرض شاشة الإتمام
  Future<void> _showCompletionScreen() async {
    // ✅ تحديث الباك مع النقاط المكتسبة (فقط إذا كانت المرحلة غير مكتملة مسبقاً)
    // ✅ إذا كانت مكتملة مسبقاً، لا نرسل نقاط (totalPoints = 0)
    final pointsToSend = (_isStageCompleted == true) ? 0 : totalPoints;
    
    try {
      await CurrentJourneyService.completeStage(
        stage: widget.stage,
        points: pointsToSend,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update backend: $e")),
        );
      }
    }

    if (!mounted) return;

    // عرض شاشة الإتمام
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CompletionDialog(
        stage: widget.stage,
        points: totalPoints,
        onNextLevel: () {
          Navigator.of(context).pop(); // إغلاق الدايلوج
          Navigator.of(context).pop(true); // العودة للخريطة مع تحديث
        },
        onBackToMap: () {
          Navigator.of(context).pop(); // إغلاق الدايلوج
          Navigator.of(context).pop(true); // العودة للخريطة مع تحديث
        },
      ),
    );
  }

  Color _optionBg(String key) {
    if (!checked) return Colors.white;

    if (key == selectedKey) {
      return (isCorrect == true) ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }
    return Colors.white;
  }

  Color _optionBorder(String key) {
    if (!checked) {
      return (key == selectedKey) ? accent : Colors.transparent;
    }
    return Colors.transparent;
  }

  Widget _optionTrailing(String key) {
    if (!checked || key != selectedKey) return const SizedBox(width: 22);

    final ok = isCorrect == true;
    return Icon(ok ? Icons.check : Icons.close, color: Colors.white, size: 22);
  }

  // ✅ Options Grid (MCQ, true_false, listening_mcq, image_mcq)
  Widget _buildOptionsGrid() {
    return ListView(
      children: q.options.map((opt) {
        final key = opt.key;
        final isSel = selectedKey == key;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _select(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _optionBg(key),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _optionBorder(key), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ✅ زر الصوت على اليسار (TTS للخيار)
                  IconButton(
                    onPressed: opt.text.isNotEmpty
                        ? () => _playOptionAudio(opt)
                        : null,
                    icon: Icon(
                      _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                      color: opt.text.isNotEmpty
                          ? (_isSpeaking ? Colors.red : accent)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // ✅ نص الخيار في المنتصف
                  Expanded(
                    child: Text(
                      opt.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: checked && key == selectedKey ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ✅ دائرة A/B/C/D على اليمين
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: checked
                          ? Colors.white.withOpacity(0.25)
                          : accent.withOpacity(isSel ? 1.0 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      key.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: checked ? Colors.white : accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _optionTrailing(key),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ✅ Writing/Fill Blank Input
  Widget _buildWritingInput() {
    final borderColor = !checked
        ? accent
        : (isCorrect == true)
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            enabled: !checked,
            onChanged: (val) => writtenAnswer = val,
            maxLines: q.type == 'writing' ? 5 : 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: q.type == 'writing' ? 'Type your answer here...' : 'Fill in the blank...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (checked) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect == true ? Icons.check_circle : Icons.cancel,
                color: isCorrect == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect == true ? 'Correct answer!' : 'Wrong answer',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isCorrect == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Failed to load stage questions"),
                const SizedBox(height: 8),
                Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadQuestions,
                  child: const Text("Try again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, elevation: 0),
        body: const Center(child: Text("No questions found for this stage.")),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Stage ${widget.stage}",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // progress row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isReviewMode
                        ? "Review: ${reviewIndex + 1} of ${wrongQuestionIndices.length}"
                        : "Question ${index + 1} of ${questions.length}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (!isReviewMode)
                    Text("${(((index + 1) / questions.length) * 100).round()}%"),
                ],
              ),
              const SizedBox(height: 10),
              if (!isReviewMode)
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (index + 1) / questions.length,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.orange.shade300, width: 2),
                  ),
                  child: Text(
                    "Review Mode - Fix your mistakes",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ✅ Question Card مع دعم الصوت والصورة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ✅ صورة السؤال (لو موجودة)
                    if (_hasImage) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          q.imageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ✅ نص السؤال
                    Text(
                      q.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w800),
                    ),

                    const SizedBox(height: 12),

                    // ✅ أزرار الصوت
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // TTS - قراءة السؤال
                        IconButton(
                          onPressed: _speakPrompt,
                          icon: Icon(
                            _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                            color: _isSpeaking ? Colors.red : accent,
                            size: 28,
                          ),
                          tooltip: 'Read question',
                        ),

                        // ✅ Audio - لو السؤال فيه صوت
                        if (_hasAudio) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _playAudio,
                            icon: Icon(
                              _isPlayingAudio ? Icons.pause_circle : Icons.play_circle,
                              color: _isPlayingAudio ? Colors.orange : accent,
                              size: 32,
                            ),
                            tooltip: 'Play audio',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // feedback text (after check)
              if (checked)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        isCorrect == true ? Icons.check_circle : Icons.cancel,
                        color: isCorrect == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect == true ? "Correct answer!" : "Wrong answer",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isCorrect == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // ✅ حسب نوع السؤال: options أو text field
              Expanded(
                child: _isWritingType
                    ? _buildWritingInput()
                    : _buildOptionsGrid(),
              ),

              const SizedBox(height: 10),

              // bottom button: Check OR Next
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: checking
                      ? null
                      : (!checked ? _check : _next),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: checking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          !checked 
                              ? "Check" 
                              : (isLast 
                                  ? (isReviewMode ? "Finish Review" : "Finish")
                                  : "Next"),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ شاشة الإتمام
class _CompletionDialog extends StatelessWidget {
  final int stage;
  final int points;
  final VoidCallback onNextLevel;
  final VoidCallback onBackToMap;

  const _CompletionDialog({
    required this.stage,
    required this.points,
    required this.onNextLevel,
    required this.onBackToMap,
  });

  Color get bg => const Color(0xFFF7F3E9);
  Color get accent => const Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ أيقونة النجاح
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            
            // ✅ عنوان مبروك
            const Text(
              "Congratulations!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            // ✅ رسالة الإتمام
            Text(
              "You have completed Stage $stage!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // ✅ عرض النقاط
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Points Earned: $points",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // ✅ أزرار التنقل
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNextLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  "Go to Next Level",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBackToMap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  "Back to Map",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
