import 'package:flutter/material.dart';

class VocabularyCard extends StatefulWidget {
  final String arabicWord;
  final String? transliteration;
  final String meaning;
  final String? exampleAr;
  final String? exampleEn;
  final bool isBookmarked;
  final bool isLearned;
  final bool isSpeaking; // Add speaking state
  final VoidCallback onSpeak;
  final VoidCallback onToggleBookmark;
  final VoidCallback onToggleLearned;

  const VocabularyCard({
    super.key,
    required this.arabicWord,
    this.transliteration,
    required this.meaning,
    this.exampleAr,
    this.exampleEn,
    required this.isBookmarked,
    required this.isLearned,
    this.isSpeaking = false, // Default to false
    required this.onSpeak,
    required this.onToggleBookmark,
    required this.onToggleLearned,
  });

  @override
  State<VocabularyCard> createState() => _VocabularyCardState();
}

class _VocabularyCardState extends State<VocabularyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSpeak() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onSpeak();
  }

  Color _getAccentColor() => const Color(0xFF0D9488); // Teal dark
  Color _getBackgroundColor() => const Color(0xFFF5F1E8); // Beige light
  Color _getCardBackground() => Colors.white;
  Color _getTextPrimary() => const Color(0xFF1F2937); // Dark gray
  Color _getTextSecondary() => const Color(0xFF6B7280); // Gray

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getCardBackground(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Arabic Word + Action Icons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic Word
                      Text(
                        widget.arabicWord,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          height: 1.2,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      // Transliteration
                      if (widget.transliteration != null &&
                          widget.transliteration!.isNotEmpty &&
                          widget.transliteration != 'null')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            widget.transliteration!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _getTextSecondary(),
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Action Icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconButton(
                      icon: widget.isSpeaking
                          ? Icons.volume_up
                          : Icons.volume_up_outlined,
                      isActive: widget.isSpeaking,
                      onPressed: _handleSpeak,
                      tooltip: 'Listen',
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: widget.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      isActive: widget.isBookmarked,
                      onPressed: widget.onToggleBookmark,
                      tooltip: 'Save',
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: widget.isLearned
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      isActive: widget.isLearned,
                      onPressed: widget.onToggleLearned,
                      tooltip: 'Mark as Learned',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withOpacity(0.08),
            ),

            const SizedBox(height: 20),

            // Meaning Section
            _buildSectionLabel('Meaning'),
            const SizedBox(height: 10),
            Text(
              widget.meaning,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
                height: 1.5,
              ),
            ),

            // Example Section
            if (widget.exampleAr != null &&
                widget.exampleAr!.isNotEmpty &&
                widget.exampleAr != 'null') ...[
              const SizedBox(height: 24),
              _buildSectionLabel('Example'),
              const SizedBox(height: 12),
              _buildExampleCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _getTextSecondary(),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildExampleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: _getAccentColor().withOpacity(0.3),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arabic Example
          Text(
            widget.exampleAr!,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1F2937),
              height: 1.6,
            ),
            textDirection: TextDirection.rtl,
          ),
          // English Example
          if (widget.exampleEn != null &&
              widget.exampleEn!.isNotEmpty &&
              widget.exampleEn != 'null') ...[
            const SizedBox(height: 10),
            Text(
              widget.exampleEn!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _getTextSecondary(),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final scale = (icon == Icons.volume_up_outlined ||
                icon == Icons.volume_up) &&
            widget.isSpeaking
            ? _scaleAnimation.value
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? _getAccentColor().withOpacity(0.1)
                      : Colors.grey.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(
                          color: _getAccentColor().withOpacity(0.3),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive ? _getAccentColor() : _getTextSecondary(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

