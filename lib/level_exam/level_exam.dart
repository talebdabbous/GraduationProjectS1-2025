import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import 'level_question.dart';
import '../services/level_exam_service.dart';
import '../services/auth_service.dart';

class LevelExamScreen extends StatefulWidget {
  const LevelExamScreen({super.key});

  @override
  State<LevelExamScreen> createState() => _LevelExamScreenState();
}

class _LevelExamScreenState extends State<LevelExamScreen> {
  late Future<List<LevelQuestion>> _futureQuestions;
  bool _submitting = false;
  int _currentIndex = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _writingController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsSpeaking = false;

  @override
  void initState() {
    super.initState();
    _futureQuestions = LevelExamService.fetchQuestions();
    
    // إعداد AudioPlayer
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    
    // ضبط مستوى الصوت إلى أقصى حد (1.0 = 100%)
    _audioPlayer.setVolume(1.0);
    
    // ضبط التوازن (0.0 = وسط)
    _audioPlayer.setBalance(0.0);
    
    // ضبط مستوى الصوت في النظام أيضاً
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    
    // استمع لحالة التشغيل
    _audioPlayer.onPlayerStateChanged.listen((state) {
      print('🎵 Player state: $state');
      if (state == PlayerState.playing) {
        print('✅ Audio is now playing!');
      } else if (state == PlayerState.completed) {
        print('✅ Audio playback completed');
      } else if (state == PlayerState.stopped) {
        print('⏹️ Audio stopped');
      } else if (state == PlayerState.paused) {
        print('⏸️ Audio paused');
      }
    });
    
    // استمع للأخطاء
    _audioPlayer.onLog.listen((log) {
      print('🎵 AudioPlayer log: $log');
    });
    
    // استمع لأخطاء التشغيل
    _audioPlayer.onPlayerComplete.listen((_) {
      print('✅ Audio playback finished');
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _flutterTts.stop();
    _writingController.dispose();
    super.dispose();
  }
  
  Future<void> _initTts() async {
    // محاولة استخدام محرك TTS أفضل (Google على Android)
    try {
      // الحصول على قائمة المحركات المتاحة
      final engines = await _flutterTts.getEngines;
      print('🔊 Available TTS engines: $engines');
      
      // البحث عن محرك Google (الأفضل للعربية)
      if (engines != null && engines.isNotEmpty) {
        final googleEngine = engines.firstWhere(
          (engine) => engine['name']?.toString().toLowerCase().contains('google') ?? false,
          orElse: () => engines.first,
        );
        if (googleEngine['name'] != null) {
          await _flutterTts.setEngine(googleEngine['name']);
          print('✅ Using TTS engine: ${googleEngine['name']}');
        }
      }
    } catch (e) {
      print('⚠️ Could not set TTS engine: $e');
    }
    
    // الإعدادات الافتراضية
    await _flutterTts.setLanguage("ar-SA"); // اللغة العربية السعودية (أفضل جودة)
    await _flutterTts.setSpeechRate(0.45); // سرعة أبطأ قليلاً لجودة أفضل
    await _flutterTts.setVolume(1.0); // مستوى الصوت كامل
    await _flutterTts.setPitch(1.0); // نبرة الصوت عادية
    
    _flutterTts.setCompletionHandler(() {
      setState(() => _isTtsSpeaking = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      print('❌ TTS Error: $msg');
      setState(() => _isTtsSpeaking = false);
    });
  }
  
  // تحديد اللغة تلقائياً بناءً على النص
  String _detectLanguage(String text) {
    // تحقق إذا كان النص يحتوي على أحرف عربية
    final arabicPattern = RegExp(r'[\u0600-\u06FF]');
    if (arabicPattern.hasMatch(text)) {
      return 'ar-SA'; // عربي - السعودية (أفضل جودة ووضوح)
    } else {
      return 'en-US'; // إنجليزي - أمريكا (US أفضل جودة)
    }
  }
  
  Future<void> _speakText(String text, {String? language}) async {
    try {
      // إيقاف TTS أولاً إذا كان يعمل
      if (_isTtsSpeaking) {
        await _flutterTts.stop();
        // انتظار قصير للتأكد من إيقاف TTS بشكل كامل
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // إيقاف أي صوت آخر قد يكون قيد التشغيل
      await _flutterTts.stop();
      
      // تحديد اللغة تلقائياً إذا لم يتم تحديدها
      final langToUse = language ?? _detectLanguage(text);
      
      // تحسين الإعدادات حسب اللغة
      if (langToUse.startsWith('en')) {
        // إعدادات أفضل للإنجليزية
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.5); // سرعة متوسطة
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      } else if (langToUse.startsWith('ar')) {
        // إعدادات محسنة للعربية
        await _flutterTts.setLanguage('ar-SA'); // اللغة العربية السعودية (أفضل جودة)
        await _flutterTts.setSpeechRate(0.45); // سرعة أبطأ قليلاً للوضوح
        await _flutterTts.setVolume(1.0); // صوت عالي
        await _flutterTts.setPitch(1.0); // نبرة طبيعية
      } else {
        // إعدادات افتراضية للغات الأخرى
        await _flutterTts.setLanguage(langToUse);
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      }
      
      // تحديث الحالة قبل البدء
      setState(() => _isTtsSpeaking = true);
      
      // تشغيل الصوت
      await _flutterTts.speak(text);
      print('🗣️ Speaking: $text (Language: $langToUse)');
    } catch (e) {
      print('❌ TTS Error: $e');
      setState(() => _isTtsSpeaking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not speak text: $e')),
        );
      }
    }
  }
  
  Future<void> _stopTts() async {
    try {
      await _flutterTts.stop();
      setState(() => _isTtsSpeaking = false);
    } catch (e) {
      print('❌ TTS Stop Error: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playAudio(String url) async {
    print('🎵 Attempting to play audio from: $url');
    
    if (url.isEmpty) {
      print('❌ Audio URL is empty!');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio URL is empty')),
      );
      return;
    }

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
      
      // تأكد من مستوى الصوت (1.0 = 100%) - أقصى حد
      await _audioPlayer.setVolume(1.0);
      print('🔊 Volume set to 1.0 (100%) - Maximum volume');
      
      // ضبط التوازن
      await _audioPlayer.setBalance(0.0);
      
      // محاولة رفع مستوى الصوت مرة أخرى قبل التشغيل
      await Future.delayed(const Duration(milliseconds: 50));
      await _audioPlayer.setVolume(1.0);
      
      // أظهر رسالة للمستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Playing audio...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      print('🎵 Playing audio directly...');
      await _audioPlayer.play(UrlSource(url));
      print('✅ Play command sent successfully');
      
      // تأكد من مستوى الصوت عدة مرات بعد بدء التشغيل
      Future.delayed(const Duration(milliseconds: 100), () async {
        await _audioPlayer.setVolume(1.0);
        print('🔊 Volume set to 1.0 after 100ms');
      });
      
      Future.delayed(const Duration(milliseconds: 300), () async {
        await _audioPlayer.setVolume(1.0);
        print('🔊 Volume confirmed at 1.0 after 300ms');
      });
      
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _audioPlayer.setVolume(1.0);
        print('🔊 Volume confirmed at 1.0 after 500ms');
      });
      
      // انتظر قليلاً ثم تحقق من الحالة
      Future.delayed(const Duration(milliseconds: 500), () {
        print('🎵 Player state after 500ms: ${_audioPlayer.state}');
      });
      
      // تحقق من الحالة بعد ثانية
      Future.delayed(const Duration(seconds: 1), () {
        print('🎵 Player state after 1s: ${_audioPlayer.state}');
        if (_audioPlayer.state == PlayerState.completed) {
          print('⚠️ Audio completed very quickly - might be empty or very short file');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Audio file might be empty or very short'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      });
      
    } catch (e) {
      print('❌ Audio playback error: $e');
      print('❌ Error details: ${e.toString()}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play audio: $e')),
      );
    }
  }

  String _mapLevelCodeToLabel(String code) {
    switch (code) {
      case 'A2':
        return 'Elementary A2';
      case 'B1':
        return 'Intermediate B1';
      case 'A1':
      default:
        return 'Beginner A1';
    }
  }

  Future<void> _submit(List<LevelQuestion> questions) async {
    await _stopAudio();
    setState(() => _submitting = true);

    try {
      final result = await LevelExamService.submitAnswers(questions);

      final levelCode = result['level'] as String;
      final percentage = (result['percentage'] as num).toDouble();
      final prettyLevel = _mapLevelCodeToLabel(levelCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('completed_level_exam', true);
      await prefs.setString('user_level', prettyLevel);

      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        try {
          await AuthService.updateMe(
            token: token,
            // level: prettyLevel,
            completedLevelExam: true,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _submitting = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Your Level'),
          content: Text(
            'Level: $prettyLevel\n'
            'Score: ${percentage.toStringAsFixed(1)}%',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/home_screen');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting test: $e')),
      );
    }
  }

  void _goNext(List<LevelQuestion> questions) async {
    await _stopAudio();
    await _stopTts(); // إيقاف TTS عند الانتقال للسؤال التالي

    final q = questions[_currentIndex];

    // ✅ تحقق حسب النوع
    final hasAnswer = q.type == 'writing'
        ? (q.writtenAnswer != null && q.writtenAnswer!.trim().isNotEmpty)
        : (q.selectedIndex != null);

    if (!hasAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer the question first')),
      );
      return;
    }

    final isLast = _currentIndex == questions.length - 1;
    final total = questions.length;
    final isLastTwo = _currentIndex >= total - 2;
    
    if (isLast) {
      _submit(questions);
    } else {
      // إذا كان من آخر سؤالين وكان من نوع writing، افرغ النص عند الانتقال للسؤال التالي
      if (isLastTwo && q.type == 'writing') {
        _writingController.clear();
      }
      setState(() => _currentIndex += 1);
    }
  }

  void _goPrevious() async {
    await _stopAudio();
    await _stopTts(); // إيقاف TTS عند العودة للسؤال السابق
    if (_currentIndex == 0) return;
    setState(() => _currentIndex -= 1);
  }

  // ألوان من الصورة: أصفر فاتح للخلفية، teal للنهر والعناصر الأساسية
  Color _backgroundColor() => const Color(0xFFF5F1E8); // بيج فاتح
  Color _primaryColor() => const Color(0xFF14B8A6); // Teal/Blue-Green (من النهر في الصورة)

  Color _badgeColor(int index) {
    // كل الرموز بنفس اللون (لون ج الأصلي)
    return const Color(0xFF0D9488); // Teal غامق
  }
  
  // لون التركواز من الجبال والمخطط - للعناصر التفاعلية مثل Next
  Color _turquoiseColor() => const Color(0xFF06B6D4);
  
  // تحويل A, B, C, D إلى أ, ب, ج, د
  String _convertKeyToArabic(String key) {
    switch (key.toUpperCase()) {
      case 'A':
        return 'أ';
      case 'B':
        return 'ب';
      case 'C':
        return 'ج';
      case 'D':
        return 'د';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor(),
      appBar: AppBar(
        backgroundColor: _backgroundColor(),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Placement Test',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        leadingWidth: 56, // عرض طبيعي للسهم
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pushNamed(context, '/ask_level');
          },
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<LevelQuestion>>(
          future: _futureQuestions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Failed to load questions'));
            }

            final questions = snapshot.data!;
            if (questions.isEmpty) {
              return const Center(child: Text('No questions available.'));
            }

            final total = questions.length;
            final q = questions[_currentIndex];
            final isLast = _currentIndex == total - 1;
            
            // طباعة معلومات السؤال للتشخيص
            print('📝 Question ${_currentIndex + 1}: type=${q.type}, text="${q.questionTextEN}", isEmpty=${(q.questionTextEN ?? '').isEmpty}');
            print('🖼️ Image URL: ${q.imageUrl ?? "null"}');
            if (_currentIndex == 1) {
              print('📸 Question 2 detected - checking image...');
              if ((q.imageUrl ?? '').isEmpty) {
                print('❌ imageUrl is empty in database');
              } else if (!q.imageUrl!.startsWith('http')) {
                print('❌ imageUrl does not start with http: ${q.imageUrl}');
              } else {
                print('✅ imageUrl is valid: ${q.imageUrl}');
              }
            }
            if (q.type == 'writing') {
              print('✍️ Writing question detected - will show TextField');
            } else {
              print('📋 MCQ question - will show options (count: ${q.options.length})');
            }

            // Sync writing controller with current question's answer
            if (q.type == 'writing') {
              final currentText = _writingController.text;
              final savedAnswer = q.writtenAnswer ?? '';
              if (currentText != savedAnswer) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _writingController.text = savedAnswer;
                  }
                });
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of $total',
                        style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${((_currentIndex + 1) / total * 100).round()}%',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / total,
                      minHeight: 8,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor()),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // صندوق السؤال
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    constraints: const BoxConstraints(minHeight: 180),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // السؤال
                        Builder(
                          builder: (context) {
                            final text = (q.questionTextEN ?? '').isNotEmpty 
                                ? q.questionTextEN 
                                : (q.type == 'writing' 
                                    ? 'Write your answer:' 
                                    : 'Question ${_currentIndex + 1}');
                            final arabicPattern = RegExp(r'[\u0600-\u06FF]');
                            final isArabic = arabicPattern.hasMatch(text);
                            
                            return Text(
                              text,
                              textAlign: TextAlign.center,
                              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                              style: isArabic
                                  ? GoogleFonts.tajawal(
                                      fontSize: 20,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade900,
                                    )
                                  : const TextStyle(
                                      fontSize: 18,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // زر TTS
                        IconButton(
                          icon: Icon(
                            _isTtsSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                            color: _isTtsSpeaking ? _primaryColor() : Colors.grey,
                          ),
                          onPressed: () {
                            final textToSpeak = (q.questionTextEN ?? '').isNotEmpty 
                                ? q.questionTextEN 
                                : (q.type == 'writing' 
                                    ? 'Write your answer' 
                                    : 'Question ${_currentIndex + 1}');
                            if (_isTtsSpeaking) {
                              _stopTts();
                            } else {
                              _speakText(textToSpeak);
                            }
                          },
                          tooltip: 'Listen to question',
                        ),
                        // زر الاستماع للأسئلة السمعية
                        if (q.type == 'listening' && ((q.audioUrl ?? '').isNotEmpty || (q.mediaUrl ?? '').isNotEmpty))
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              IconButton(
                                iconSize: 32,
                                onPressed: () {
                                  String? audioToPlay;
                                  if ((q.audioUrl ?? '').isNotEmpty && 
                                      q.audioUrl!.startsWith('http') && 
                                      !q.audioUrl!.contains('...')) {
                                    audioToPlay = q.audioUrl!;
                                  } else if ((q.mediaUrl ?? '').isNotEmpty) {
                                    audioToPlay = q.mediaUrl!;
                                  }
                                  
                                  if (audioToPlay != null) {
                                    print('🔊 Playing audio from: $audioToPlay');
                                    _playAudio(audioToPlay);
                                  } else {
                                    print('❌ No valid audio URL found');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No audio available')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.volume_up_rounded),
                                color: _primaryColor(),
                              ),
                              const Text('Tap to listen', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        // الصورة للسؤال الثاني
                        if (_currentIndex == 1)
                          Builder(
                            builder: (context) {
                              String? imageToShow;
                              if ((q.imageUrl ?? '').isNotEmpty && q.imageUrl!.startsWith('http')) {
                                imageToShow = q.imageUrl;
                              } else if ((q.mediaUrl ?? '').isNotEmpty && q.mediaUrl!.startsWith('http') && q.type != 'listening') {
                                imageToShow = q.mediaUrl;
                              }
                              
                              print('🖼️ Question 2 - imageUrl: ${q.imageUrl}, mediaUrl: ${q.mediaUrl}, finalImage: $imageToShow');
                              
                              if (imageToShow != null) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageToShow,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ Image load error: $error');
                                          return Container(
                                            height: 200,
                                            color: Colors.grey.shade200,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                                const SizedBox(height: 4),
                                                Text('Failed to load image', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                              ],
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            print('✅ Image loaded successfully');
                                            return child;
                                          }
                                          return Container(
                                            height: 200,
                                            color: Colors.grey.shade100,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                print('⚠️ Question 2 has no valid image (imageUrl or mediaUrl)');
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // الأجوبة (بدون بوكس كبير)
                  Expanded(
                    child: q.type == 'writing'
                        ? Center(
                            child: SingleChildScrollView(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Write your answer:',
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _writingController,
                                      textDirection: TextDirection.rtl,
                                      minLines: 5,
                                      maxLines: 8,
                                      decoration: const InputDecoration(
                                        hintText: 'Type your answer here...',
                                        border: OutlineInputBorder(),
                                        alignLabelWithHint: true,
                                      ),
                                      onChanged: (val) {
                                        q.writtenAnswer = val;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: q.options.length,
                            itemBuilder: (context, optIndex) {
                              final opt = q.options[optIndex];
                              final selected = q.selectedIndex == optIndex;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => setState(() => q.selectedIndex = optIndex),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: selected ? _primaryColor() : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.volume_up, size: 20),
                                          color: Colors.grey.shade600,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            _speakText(opt.text);
                                          },
                                          tooltip: 'Listen to option',
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final arabicPattern = RegExp(r'[\u0600-\u06FF]');
                                              final isArabic = arabicPattern.hasMatch(opt.text);
                                              
                                              return Text(
                                                opt.text,
                                                textAlign: TextAlign.center,
                                                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                                style: isArabic
                                                    ? GoogleFonts.tajawal(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.grey.shade900,
                                                      )
                                                    : TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.grey.shade900,
                                                      ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: _badgeColor(optIndex),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _convertKeyToArabic(opt.key),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            foregroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: _currentIndex == 0 ? null : () => _goPrevious(),
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488), // نفس لون الرموز (Teal غامق)
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          onPressed: _submitting ? null : () => _goNext(questions),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(isLast ? 'Submit Test' : 'Next'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
