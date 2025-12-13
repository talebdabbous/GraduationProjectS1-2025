import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

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
    _writingController.dispose();
    super.dispose();
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
      
      // تأكد من مستوى الصوت (1.0 = 100%)
      await _audioPlayer.setVolume(1.0);
      print('🔊 Volume set to 1.0 (100%)');
      
      // ضبط التوازن
      await _audioPlayer.setBalance(0.0);
      
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
      
      // تأكد من مستوى الصوت مرة أخرى بعد بدء التشغيل
      Future.delayed(const Duration(milliseconds: 100), () async {
        await _audioPlayer.setVolume(1.0);
        print('🔊 Volume confirmed at 1.0 after playback start');
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
    if (_currentIndex == 0) return;
    setState(() => _currentIndex -= 1);
  }

  Color _backgroundColor() => const Color(0xFFE6F4FF);
  Color _primaryColor() => const Color(0xFF0EA5E9);

  Color _badgeColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFACC15);
      case 1:
        return const Color(0xFF38BDF8);
      case 2:
        return const Color(0xFFA855F7);
      case 3:
      default:
        return const Color(0xFF34D399);
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
        title: const Text('Placement Test', style: TextStyle(fontWeight: FontWeight.bold)),
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
                children: [
                  const SizedBox(height: 8),

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

                  // صندوق السؤال الكبير + listening button + image
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    constraints: const BoxConstraints(minHeight: 190),
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
                      children: [
                        if (q.type == 'listening' && ((q.audioUrl ?? '').isNotEmpty || (q.mediaUrl ?? '').isNotEmpty))
                          Column(
                            children: [
                              IconButton(
                                iconSize: 32,
                                onPressed: () {
                                  // ✅ استخدم audioUrl أولاً (الصوت الجديد من قاعدة البيانات)
                                  // إذا لم يكن موجوداً أو كان رابط غير صحيح، استخدم mediaUrl القديم
                                  String? audioToPlay;
                                  if ((q.audioUrl ?? '').isNotEmpty && 
                                      q.audioUrl!.startsWith('http') && 
                                      !q.audioUrl!.contains('...')) {
                                    // audioUrl موجود وصحيح
                                    audioToPlay = q.audioUrl!;
                                  } else if ((q.mediaUrl ?? '').isNotEmpty) {
                                    // استخدم mediaUrl
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
                              const SizedBox(height: 12),
                            ],
                          ),
                        // ✅ عرض الصورة فقط في السؤال الثاني (index 1)
                        if (_currentIndex == 1 && (q.imageUrl ?? '').isNotEmpty && q.imageUrl!.startsWith('http'))
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  q.imageUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
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
                              const SizedBox(height: 16),
                            ],
                          ),
                        Text(
                          (q.questionTextEN ?? '').isNotEmpty 
                              ? q.questionTextEN 
                              : (q.type == 'writing' 
                                  ? 'Write your answer:' 
                                  : 'Question ${_currentIndex + 1}'),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 20, height: 1.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ MCQ or Writing
                  Expanded(
                    child: q.type == 'writing'
                        ? SingleChildScrollView(
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                    textDirection: TextDirection.rtl,
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
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
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
                                        Expanded(
                                          child: Text(
                                            opt.text,
                                            textAlign: TextAlign.center,
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: _badgeColor(optIndex),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            opt.key.toLowerCase(),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

                  const SizedBox(height: 8),

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
                            backgroundColor: _primaryColor(),
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

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
