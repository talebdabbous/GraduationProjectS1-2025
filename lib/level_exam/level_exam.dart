import 'package:flutter/material.dart';

class LevelExamPage extends StatefulWidget {
  const LevelExamPage({super.key});

  @override
  State<LevelExamPage> createState() => _LevelExamPageState();
}

class _LevelExamPageState extends State<LevelExamPage> {
  final List<_Question> _questions = [
    _Question(
      text: "اختر جمع كلمة (كتاب):",
      options: ["كتابات", "كتب", "كتبة", "كتابون"],
      correctIndex: 1,
    ),
    _Question(
      text: "ما إعراب (العلمُ) في جملة: العلمُ نورٌ؟",
      options: ["مبتدأ مرفوع", "خبر مرفوع", "مفعول به", "حال"],
      correctIndex: 0,
    ),
    _Question(
      text: "ما معنى (يطالع) في الجملة: يطالع الطالب دروسه؟",
      options: ["يسافر", "يقرأ/يراجع", "ينام", "يكتب"],
      correctIndex: 1,
    ),
    _Question(
      text: "مرادف (سريعًا):",
      options: ["بُطئًا", "عَاجِلًا", "قريبًا", "بعيدًا"],
      correctIndex: 1,
    ),
    _Question(
      text: "اختر الكلمة الصحيحة: ذهب ___ المدرسة.",
      options: ["الى", "إلى", "إلا", "إلّا"],
      correctIndex: 1,
    ),
  ];

  int _index = 0;
  final Map<int, int> _answers = {};
  static const Color kBlue = Color(0xFF1E88E5);

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  void _finish() {
    int score = 0;
    for (var i = 0; i < _questions.length; i++) {
      final sel = _answers[i];
      if (sel != null && sel == _questions[i].correctIndex) score++;
    }
    final percent = (score / _questions.length);

    String level;
    if (percent >= 0.85) {
      level = "متقدّم";
    } else if (percent >= 0.6) {
      level = "متوسّط";
    } else if (percent >= 0.35) {
      level = "مبتدئ";
    } else {
      level = "مبتدئ جدًا";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("نتيجتك"),
        content: Text(
          "الإجابات الصحيحة: $score من ${_questions.length}\n"
          "تقييم المستوى: $level",
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("إنهاء"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _index = 0;
                _answers.clear();
              });
            },
            child: const Text("إعادة الاختبار"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    final selected = _answers[_index];
    final progress = (_index + 1) / _questions.length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/welcome_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black26),

          SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "اختبار تحديد المستوى (عربي)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEDF2F4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "السؤال ${_index + 1} من ${_questions.length}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(kBlue),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: double.infinity,
                      child: Text(
                        q.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemCount: q.options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final isSelected = selected == i;
                          final bg = isSelected ? kBlue : Colors.white;
                          final fg = isSelected ? Colors.white : kBlue;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bg,
                                foregroundColor: fg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                setState(() => _answers[_index] = i);
                              },
                              child: Text(
                                q.options[i],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _index == 0 ? null : _prev,
                            child: const Text(
                              "السابق",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: (_answers[_index] == null) ? null : _next,
                            child: Text(
                              _index == _questions.length - 1 ? "إنهاء" : "التالي",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Question {
  final String text;
  final List<String> options;
  final int correctIndex;

  _Question({
    required this.text,
    required this.options,
    required this.correctIndex,
  });
}
