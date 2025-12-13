class LevelOption {
  final String key;
  final String text;

  LevelOption({required this.key, required this.text});

  factory LevelOption.fromJson(Map<String, dynamic> json) {
    return LevelOption(
      key: json['key'],
      text: json['text'],
    );
  }
}

class LevelQuestion {
  final String id;
  final String questionTextEN;
  final String type; // vocabulary/grammar/reading/listening/writing
  final String skill;
  final String levelTag;
  final List<LevelOption> options;
  final String? mediaUrl;

  int? selectedIndex;     // للـ MCQ
  String? writtenAnswer;  // ✅ للـ writing

  LevelQuestion({
    required this.id,
    required this.questionTextEN,
    required this.type,
    required this.skill,
    required this.levelTag,
    required this.options,
    this.mediaUrl,
    this.selectedIndex,
    this.writtenAnswer,
  });

  factory LevelQuestion.fromJson(Map<String, dynamic> json) {
    return LevelQuestion(
      id: json['_id'],
      questionTextEN: json['questionTextEN'] ?? '',
      type: json['type'] ?? 'vocabulary',
      skill: json['skill'] ?? 'vocabulary',
      levelTag: json['levelTag'] ?? 'A1',
      options: ((json['options'] ?? []) as List)
          .map((o) => LevelOption.fromJson(o))
          .toList(),
      mediaUrl: json['mediaUrl'],
    );
  }
}
