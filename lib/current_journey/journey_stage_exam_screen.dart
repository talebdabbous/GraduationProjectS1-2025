import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/journey_exam_service.dart';

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
    _loadQuestions();
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
      final data = await JourneyExamService.fetchStageQuestions(
        level: widget.level,
        stage: widget.stage,
      );

      if (!mounted) return;
      setState(() {
        questions = data;
        loading = false;
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
  bool get isLast => index == questions.length - 1;

  // ✅ نوع السؤال
  bool get _isWritingType => q.type == 'fill_blank' || q.type == 'writing';
  bool get _hasAudio => q.audioUrl != null && q.audioUrl!.isNotEmpty;
  bool get _hasImage => q.imageUrl != null && q.imageUrl!.isNotEmpty;

  // ✅ تشغيل الصوت (audioUrl)
  Future<void> _playAudio() async {
    if (!_hasAudio) return;
    
    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }

    setState(() => _isPlayingAudio = true);
    try {
      await _audioPlayer.play(UrlSource(q.audioUrl!));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingAudio = false);
      });
    } catch (e) {
      if (mounted) setState(() => _isPlayingAudio = false);
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
      setState(() {
        checked = true;
        isCorrect = res.correct;
        checking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => checking = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Check failed: $e")),
      );
    }
  }

  void _next() {
    if (!checked) return;

    if (isLast) {
      Navigator.pop(context, true);
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
                  const SizedBox(width: 10),
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
                isCorrect == true ? 'Correct!' : 'Try again next time',
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
                    "Question ${index + 1} of ${questions.length}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text("${(((index + 1) / questions.length) * 100).round()}%"),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (index + 1) / questions.length,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
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
                  child: Text(
                    (isCorrect == true) ? "Correct!" : "Wrong answer",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: (isCorrect == true) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
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
                          !checked ? "Check" : (isLast ? "Finish" : "Next"),
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
