import 'package:flutter/material.dart';
import '../services/current_journey_service.dart';
import 'journey_stage_exam_screen.dart';

class CurrentJourneyPage extends StatefulWidget {
  const CurrentJourneyPage({super.key});

  @override
  State<CurrentJourneyPage> createState() => _CurrentJourneyPageState();
}

class _CurrentJourneyPageState extends State<CurrentJourneyPage> {
  JourneyLevel _selectedLevel = JourneyLevel.beginner;

  // ✅ أعلى مستوى فعلي مفتوح (جاي من /current)
  JourneyLevel _currentUnlockedLevel = JourneyLevel.beginner;

  // ✅ بيانات المستوى الحالي الثابتة (للعرض في الكارد)
  JourneyData? _currentLevelData;

  // ✅ بيانات المستوى المختار (للخريطة)
  JourneyData? _data;
  bool _loading = true;
  String? _error;

  final ScrollController _scroll = ScrollController();

  // ✅ بدون لاج: نحدّث opacity بدون setState
  final ValueNotifier<double> _headerOpacity = ValueNotifier<double>(1.0);

  static const String _fallbackAsset = "assets/images/level_map.png";

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    // ✅ precache للـ asset أولاً ثم نحمّل البيانات
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await precacheImage(const AssetImage(_fallbackAsset), context);
      _loadCurrent();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _headerOpacity.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final max = _scroll.position.maxScrollExtent;
    final offset = _scroll.offset;

    const fadeRange = 180.0;

    // ✅ مع reverse: true، offset=0 يعني تحت (البداية)، offset=max يعني فوق (النهاية)
    final fromBottom = offset;
    final fromTop = (max - offset).abs();

    final minDist = fromBottom < fromTop ? fromBottom : fromTop;

    double opacity;

    if (minDist <= 0) {
      opacity = 1.0;
    } else if (minDist >= fadeRange) {
      opacity = 0.35;
    } else {
      opacity = 1.0 - (minDist / fadeRange) * 0.65;
    }

    if ((opacity - _headerOpacity.value).abs() > 0.02) {
      _headerOpacity.value = opacity;
    }
  }

  Color _accentColor(JourneyLevel level) {
    switch (level) {
      case JourneyLevel.beginner:
        return const Color(0xFF2C8C99);
      case JourneyLevel.intermediate:
        return const Color(0xFFE9C46A);
      case JourneyLevel.advanced:
        return Colors.black87;
    }
  }

  int _levelRank(JourneyLevel l) => l.index;

  bool _isLockedLevel(JourneyLevel selected) {
    return _levelRank(selected) > _levelRank(_currentUnlockedLevel);
  }

  // ✅ إذا المستوى المختار أقل من المستوى الحالي = مخلّصه
  bool _isCompletedLevel(JourneyLevel selected) {
    return _levelRank(selected) < _levelRank(_currentUnlockedLevel);
  }

  String _subLevelFromUnlockedStage(int unlockedStage) {
    final s = unlockedStage.clamp(1, 15);
    if (s <= 5) return "Low";
    if (s <= 10) return "Mid";
    return "High";
  }

  String _progressText(JourneyData j, {required bool locked}) {
    if (locked) return "0/15";

    const total = 15;
    var completedCount = j.completedStages.length;

    if (completedCount == 0 && j.unlockedStage > 1) {
      completedCount = (j.unlockedStage - 1).clamp(0, total);
    }

    completedCount = completedCount.clamp(0, total);
    return "$completedCount/$total";
  }

  Future<void> _loadCurrent() async {
    // ✅ ما نعرض loading - نخلي الـ fallback ظاهر
    _error = null;

    try {
      final res = await CurrentJourneyService.fetchCurrent();

      // ✅ Precache للصورة قبل العرض لتقليل الوميض
      if (res.data.mapImageUrl != null &&
          res.data.mapImageUrl!.isNotEmpty &&
          mounted) {
        await precacheImage(NetworkImage(res.data.mapImageUrl!), context);
      }

      if (!mounted) return;
      setState(() {
        _currentUnlockedLevel = res.currentLevel;
        _selectedLevel = res.currentLevel;
        _currentLevelData = res.data;
        _data = res.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadFor(JourneyLevel level) async {
    // ✅ ما نعرض loading - نخلي المحتوى الحالي ظاهر
    // setState(() {
    //   _loading = true;
    //   _error = null;
    // });

    try {
      final d = await CurrentJourneyService.fetchByLevel(level);

      // ✅ Precache للصورة قبل العرض لتقليل الوميض
      if (d.mapImageUrl != null && d.mapImageUrl!.isNotEmpty && mounted) {
        await precacheImage(NetworkImage(d.mapImageUrl!), context);
      }

      if (!mounted) return;
      
      setState(() {
        _selectedLevel = level;
        _data = d;
        
        // ✅ إذا كان المستوى المختار هو نفس المستوى الحالي، حدث _currentLevelData أيضاً
        if (level == _currentUnlockedLevel) {
          _currentLevelData = d;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _onStageTap(int stageNumber) async {
    if (_isLockedLevel(_selectedLevel)) return;

    // ✅ التحقق: يمكن الدخول على المراحل <= unlockedStage أو المراحل المكتملة مسبقاً
    // ✅ استخدام بيانات المستوى المختار (_data) وليس المستوى الحالي (_currentLevelData)
    final selectedLevelData = _data;
    final unlockedStage = selectedLevelData?.unlockedStage ?? 1;
    final completedStages = selectedLevelData?.completedStages ?? <int>[];
    final isCompleted = completedStages.contains(stageNumber);
    final canAccess = stageNumber <= unlockedStage || isCompleted;
    
    if (!canAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Stage $stageNumber is locked. Unlocked stage is $unlockedStage. Please complete previous stages first."),
        ),
      );
      return;
    }

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JourneyStageExamScreen(
          level: _selectedLevel.apiValue,
          stage: stageNumber,
        ),
      ),
    );

    // لو رجع true => حدّث الخريطة
    if (res == true) {
      // ✅ حفظ المستوى القديم قبل التحديث
      final oldLevel = _currentUnlockedLevel;
      
      // ✅ تحديث البيانات بشكل متوازي
      await Future.wait([
        _loadCurrent(),
        _loadFor(_selectedLevel),
      ]);
      
      // ✅ إذا كانت المرحلة 15 وحدثت ترقية، عرض dialog الترقية
      if (stageNumber == 15 && mounted) {
        final newLevel = _currentUnlockedLevel;
        if (newLevel != oldLevel) {
          await Future.delayed(const Duration(milliseconds: 300)); // تأخير بسيط
          
          if (!mounted) return;
          
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _LevelUpDialog(
              newLevel: newLevel,
              xpEarned: 50,
              onContinue: () {
                Navigator.of(context).pop(); // إغلاق dialog الترقية
              },
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF7F3E9);

    // ✅ خلي صفحة الايرور زي ما هي (بدون تغيير منطق)
    if (_error != null && _data == null) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Failed to load journey"),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadCurrent,
                    child: const Text("Try again"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ✅ بدل ما نرجع Scaffold ثاني أثناء التحميل:
    // استخدم بيانات افتراضية خفيفة فقط لعرض نفس الواجهة بدون فلاش
    final j = _data;
    final currentData = _currentLevelData ?? _data;

    final accent = _accentColor(_selectedLevel);

    final lockedLevel = _isLockedLevel(_selectedLevel);
    final completedLevel = _isCompletedLevel(_selectedLevel);

    // ✅ حسب حالة المستوى المختار:
    // - مقفل → "Locked"
    // - مخلّص → "15/15"
    // - حالي → التقدم الفعلي
    final progressText = lockedLevel
        ? "Locked"
        : completedLevel
            ? "15/15"
            : (currentData == null)
                ? "0/15"
                : _progressText(currentData, locked: false);

    final subLevelText = (currentData == null)
        ? "Low"
        : _subLevelFromUnlockedStage(currentData.unlockedStage);

    final unlockedStage = (j == null)
        ? 1
        : (j.unlockedStage < 1)
            ? 1
            : (j.unlockedStage > 15)
                ? 15
                : j.unlockedStage;

    final completed = (j == null) ? <int>{} : j.completedStages.toSet();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // ✅ Scrollable map with reverse (يبدأ من تحت تلقائياً)
            Positioned.fill(
              child: ListView(
                controller: _scroll,
                reverse: true,
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                children: [
                  // Stage 1-5 (يظهر تحت - أول ما تدخل)
                  _MapSection(
                    mapImageUrl: j?.mapImageUrl,
                    fallbackAsset: _fallbackAsset,
                    startLevel: 1,
                    accent: accent,
                    unlockedStage: lockedLevel ? 0 : unlockedStage,
                    completedStages: lockedLevel ? <int>{} : completed,
                    onTapStage: _onStageTap,
                  ),
                  // Stage 6-10 (وسط)
                  _MapSection(
                    mapImageUrl: j?.mapImageUrl,
                    fallbackAsset: _fallbackAsset,
                    startLevel: 6,
                    accent: accent,
                    unlockedStage: lockedLevel ? 0 : unlockedStage,
                    completedStages: lockedLevel ? <int>{} : completed,
                    onTapStage: _onStageTap,
                  ),
                  // Stage 11-15 (فوق)
                  _MapSection(
                    mapImageUrl: j?.mapImageUrl,
                    fallbackAsset: _fallbackAsset,
                    startLevel: 11,
                    accent: accent,
                    unlockedStage: lockedLevel ? 0 : unlockedStage,
                    completedStages: lockedLevel ? <int>{} : completed,
                    onTapStage: _onStageTap,
                  ),

                  // ✅ مساحة للهيدر (تظهر فوق)
                  const SizedBox(height: 295),
                ],
              ),
            ),

            // ✅ Header overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _headerOpacity,
                builder: (_, op, child) => Opacity(opacity: op, child: child),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: bg.withOpacity(0.45),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context, true), // ✅ إرجاع true للإشارة إلى التحديث
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black87),
                          ),
                          const Expanded(
                            child: Text(
                              "Current Journey",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _loadCurrent,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _ExpandableTopCard(
                        streak: currentData?.streak ?? 0,
                        points: currentData?.points ?? 0,
                        mainLevel: currentData?.mainLevel ?? "",
                        subLevel: subLevelText,
                        progressText: progressText,
                        accent: _accentColor(_currentUnlockedLevel),
                      ),

                      const SizedBox(height: 12),

                      _LevelPillBar(
                        selected: _selectedLevel,
                        accent: accent,
                        onSelect: (lvl) => _loadFor(lvl),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// Top Card
// =========================

class _ExpandableTopCard extends StatelessWidget {
  final int streak;
  final int points;
  final String mainLevel;
  final String subLevel;
  final String progressText;
  final Color accent;

  const _ExpandableTopCard({
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

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: const Color(0xFF10B981), size: 22),
                    const SizedBox(width: 6),
                    Text(
                      progressText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.local_fire_department,
                  color: accent,
                  title: "Streak",
                  value: "$streak",
                  suffix: "days",
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
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

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String suffix;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  "$value $suffix",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// Pill Bar
// =========================

class _LevelPillBar extends StatelessWidget {
  final JourneyLevel selected;
  final Color accent;
  final Function(JourneyLevel) onSelect;

  const _LevelPillBar({
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  String _label(JourneyLevel l) {
    switch (l) {
      case JourneyLevel.beginner:
        return "BEGINNER";
      case JourneyLevel.intermediate:
        return "INTERMEDIATE";
      case JourneyLevel.advanced:
        return "ADVANCED";
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = JourneyLevel.values;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: levels.map((l) {
          final isSel = l == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(l),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    _label(l),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: isSel ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =========================
// Map Section with Nodes
// =========================

enum _StageStatus { locked, unlocked, completed }

class _MapSection extends StatelessWidget {
  final String? mapImageUrl;
  final String fallbackAsset;
  final int startLevel;
  final Color accent;

  final int unlockedStage;
  final Set<int> completedStages;
  final void Function(int stageNumber) onTapStage;

  const _MapSection({
    required this.mapImageUrl,
    required this.fallbackAsset,
    required this.startLevel,
    required this.accent,
    required this.unlockedStage,
    required this.completedStages,
    required this.onTapStage,
  });

  // ✅ عكسنا ترتيب النودز (عشان يصير 1 تحت و 5 فوق داخل السكشن)
  static const List<Offset> _nodePositions = [
    Offset(0.461, 0.85),
    Offset(0.45, 0.60),
    Offset(0.55, 0.40),
    Offset(0.40, 0.20),
    Offset(0.43, -0.005),
  ];

  _StageStatus _statusFor(int stageNumber) {
    if (completedStages.contains(stageNumber)) return _StageStatus.completed;
    if (stageNumber <= unlockedStage) return _StageStatus.unlocked;
    return _StageStatus.locked;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (mapImageUrl != null && mapImageUrl!.isNotEmpty)
          FadeInImage(
            placeholder: AssetImage(fallbackAsset),
            image: NetworkImage(mapImageUrl!),
            width: double.infinity,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 100),
            imageErrorBuilder: (_, __, ___) => Image.asset(
              fallbackAsset,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Image.asset(
            fallbackAsset,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ...List.generate(5, (index) {
          final stageNumber = startLevel + index;
          final pos = _nodePositions[index];
          final st = _statusFor(stageNumber);

          return Positioned.fill(
            child: Align(
              alignment: Alignment((pos.dx * 2) - 1, (pos.dy * 2) - 1),
              child: _LevelNode(
                level: stageNumber,
                accent: accent,
                status: st,
                onTap: () {
                  if (st != _StageStatus.locked) onTapStage(stageNumber);
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LevelNode extends StatelessWidget {
  final int level;
  final Color accent;
  final _StageStatus status;
  final VoidCallback onTap;

  const _LevelNode({
    required this.level,
    required this.accent,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = status == _StageStatus.locked;
    final isCompleted = status == _StageStatus.completed;

    // ✅ ألوان حسب الحالة
    const greenColor = Color(0xFF10B981); // أخضر للـ completed
    
    // ✅ لون الظل الخارجي
    final outerShadowColor = isCompleted
        ? greenColor.withOpacity(0.50) // Glow أخضر للـ completed
        : isLocked
            ? Colors.black.withOpacity(0.10)
            : accent.withOpacity(0.40);

    // ✅ لون الدائرة الداخلية - أخضر للـ completed
    final innerColor = isCompleted
        ? greenColor
        : isLocked
            ? Colors.grey.shade400
            : accent;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.55 : 1.0,
        child: SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ✅ العقدة الأساسية
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: outerShadowColor,
                        blurRadius: isCompleted ? 16 : 12,
                        spreadRadius: isCompleted ? 2 : 0,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: innerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isLocked
                            ? Icon(Icons.lock,
                                color: Colors.white.withOpacity(0.75), size: 20)
                            : Text(
                                "$level",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // ✅ Badge صح صغير للـ completed
              if (isCompleted)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: greenColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: greenColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 14),
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

// ✅ Dialog الترقية (Level Up)
class _LevelUpDialog extends StatelessWidget {
  final JourneyLevel newLevel;
  final int xpEarned;
  final VoidCallback onContinue;

  const _LevelUpDialog({
    required this.newLevel,
    required this.xpEarned,
    required this.onContinue,
  });

  Color get bg => const Color(0xFFF7F3E9);
  
  Color _getLevelColor(JourneyLevel level) {
    switch (level) {
      case JourneyLevel.beginner:
        return const Color(0xFF2C8C99);
      case JourneyLevel.intermediate:
        return const Color(0xFFE9C46A);
      case JourneyLevel.advanced:
        return Colors.black87;
    }
  }
  
  String _getLevelName(JourneyLevel level) {
    switch (level) {
      case JourneyLevel.beginner:
        return "Beginner";
      case JourneyLevel.intermediate:
        return "Intermediate";
      case JourneyLevel.advanced:
        return "Advanced";
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _getLevelColor(newLevel);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ أيقونة الترقية مع تأثير
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent,
                    accent.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            
            // ✅ عنوان "مبروك"
            const Text(
              "مبروك!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // ✅ رسالة الترقية
            Text(
              "Level Up!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            
            // ✅ المستوى الجديد
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent, width: 2),
              ),
              child: Text(
                _getLevelName(newLevel),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // ✅ XP المكتسبة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9C46A), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: Color(0xFFE9C46A), size: 32),
                  const SizedBox(width: 12),
                  Text(
                    "+$xpEarned XP",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE9C46A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            // ✅ زر المتابعة
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
