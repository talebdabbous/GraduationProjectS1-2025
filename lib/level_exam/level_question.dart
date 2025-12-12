class LevelOption {
  final String key;   // A, B, C, D
  final String text;  // النص بالعربي

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
  final String type;
  final String skill;
  final String levelTag;
  final List<LevelOption> options;
  final String? mediaUrl;

  int? selectedIndex; // هاي بس للـ UI، مش من الداتا بيس

  LevelQuestion({
    required this.id,
    required this.questionTextEN,
    required this.type,
    required this.skill,
    required this.levelTag,
    required this.options,
    this.mediaUrl,
    this.selectedIndex,
  });

  factory LevelQuestion.fromJson(Map<String, dynamic> json) {
    return LevelQuestion(
      id: json['_id'],
      questionTextEN: json['questionTextEN'],
      type: json['type'],
      skill: json['skill'],
      levelTag: json['levelTag'] ?? 'A1',
      options: (json['options'] as List)
          .map((o) => LevelOption.fromJson(o))
          .toList(),
      mediaUrl: json['mediaUrl'],
    );
  }
}
