import 'package:flutter/material.dart';
import '../services/current_journey_service.dart';

class CurrentJourneyPage extends StatefulWidget {
  const CurrentJourneyPage({super.key});

  @override
  State<CurrentJourneyPage> createState() => _CurrentJourneyPageState();
}

class _CurrentJourneyPageState extends State<CurrentJourneyPage> {
  JourneyLevel _selectedLevel = JourneyLevel.beginner;

  JourneyData? _data;
  bool _loading = true;
  String? _error;

  final ScrollController _scroll = ScrollController();

  // ✅ بدون لاج: نحدّث opacity بدون setState
  final ValueNotifier<double> _headerOpacity = ValueNotifier<double>(1.0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadCurrent();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _headerOpacity.dispose();
    super.dispose();
  }

  void _onScroll() {
    const start = 10.0;
    const end = 170.0;

    final offset = _scroll.offset;
    double t;

    if (offset <= start) {
      t = 1.0;
    } else if (offset >= end) {
      t = 0.0;
    } else {
      t = 1.0 - ((offset - start) / (end - start));
    }

    // ✅ ما بختفي: أقل شي 0.25
    final clamped = 0.25 + (0.75 * t);

    if ((clamped - _headerOpacity.value).abs() > 0.02) {
      _headerOpacity.value = clamped;
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

  Future<void> _loadCurrent() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await CurrentJourneyService.fetchCurrent();
      setState(() {
        _selectedLevel = res.currentLevel;
        _data = res.data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadFor(JourneyLevel level) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final d = await CurrentJourneyService.fetchByLevel(level);
      setState(() {
        _selectedLevel = level;
        _data = d;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF7F3E9);

    if (_loading && _data == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

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

    final j = _data!;
    final accent = _accentColor(_selectedLevel);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // ✅ Scrollable map
            Positioned.fill(
              child: ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                children: [
                  // Spacer for overlay header
                  const SizedBox(height: 265),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: LinearProgressIndicator(),
                    ),

                  const SizedBox(height: 10),

                  _MapSection(
                    mapImageUrl: j.mapImageUrl,
                    fallbackAsset: "assets/images/level_map.png",
                    startLevel: 1,
                    accent: accent,
                  ),
                  _MapSection(
                    mapImageUrl: j.mapImageUrl,
                    fallbackAsset: "assets/images/level_map.png",
                    startLevel: 6,
                    accent: accent,
                  ),
                  _MapSection(
                    mapImageUrl: j.mapImageUrl,
                    fallbackAsset: "assets/images/level_map.png",
                    startLevel: 11,
                    accent: accent,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ✅ Header overlay (no lag)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _headerOpacity,
                builder: (_, op, child) {
                  return Opacity(opacity: op, child: child);
                },
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
                      // Title row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.black87),
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

                      // Expandable top stats
                      _ExpandableTopCard(
                        streak: j.streak,
                        points: j.points,
                        mainLevel: j.mainLevel,
                        subLevel: j.subLevel,
                        accent: accent,
                      ),

                      const SizedBox(height: 12),

                      // Pill level selector
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
// Expandable Top Card
// =========================

class _ExpandableTopCard extends StatefulWidget {
  final int streak;
  final int points;
  final String mainLevel;
  final String subLevel;
  final Color accent;

  const _ExpandableTopCard({
    required this.streak,
    required this.points,
    required this.mainLevel,
    required this.subLevel,
    required this.accent,
  });

  @override
  State<_ExpandableTopCard> createState() => _ExpandableTopCardState();
}

class _ExpandableTopCardState extends State<_ExpandableTopCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: Container(
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
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.school, color: widget.accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.mainLevel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.subLevel,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: widget.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.local_fire_department,
                      color: widget.accent,
                      title: "Streak",
                      value: "${widget.streak}",
                      suffix: "days",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.star,
                      color: const Color(0xFFE9C46A),
                      title: "Points",
                      value: "${widget.points}",
                      suffix: "XP",
                    ),
                  ),
                ],
              ),

              if (_expanded) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    "Tap the level bar to switch journeys. Keep learning daily to grow your streak.",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
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

class _MapSection extends StatelessWidget {
  final String? mapImageUrl;
  final String fallbackAsset;
  final int startLevel;
  final Color accent;

  const _MapSection({
    required this.mapImageUrl,
    required this.fallbackAsset,
    required this.startLevel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (mapImageUrl != null && mapImageUrl!.isNotEmpty)
          Image.network(
            mapImageUrl!,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
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

        // Nodes
        ...List.generate(5, (index) {
          final level = startLevel + index;
          
          // 📍 إحداثيات النودز (المراحل)
          // x: 0.0 (يسار) -> 1.0 (يمين)
          // y: 0.0 (فوق) -> 1.0 (تحت)
          // عدل هذه الأرقام لتطابق رسمة الطريق في صورتك
          final nodePositions = [
            const Offset(0.43, -0.005), // النود الأولى
            const Offset(0.40, 0.20), // النود الثانية
            const Offset(0.55, 0.40), // النود الثالثة
            const Offset(0.45, 0.60), // النود الرابعة
            const Offset(0.50, 0.85), // النود الخامسة
          ];

          final pos = nodePositions[index];

          return Positioned.fill(
            child: Align(
              alignment: Alignment(
                (pos.dx * 2) - 1,
                (pos.dy * 2) - 1,
              ),
              child: _LevelNode(level: level, accent: accent),
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
  const _LevelNode({required this.level, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "$level",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
