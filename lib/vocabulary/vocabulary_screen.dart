import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/vocabulary_service.dart';
import '../services/current_journey_service.dart';
import 'vocabulary_card.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  // Setup State
  Set<String> _selectedCategories = {};
  int _selectedWordCount = 10;
  bool _isSetupState = true;

  // Custom Vocabulary State
  String _customTopic = '';
  String? _selectedSituation;
  Set<String> _selectedFocus = {};
  String _difficultyLevel = 'Beginner';

  // Words State
  List<Map<String, dynamic>> _vocabularyWords = [];
  Set<String> _learnedWords = {}; // Changed to String for word IDs from backend
  Set<String> _savedWords = {}; // Changed to String for word IDs from backend
  bool _isLoadingWords = false;
  Map<String, dynamic>? _learningConfig;
  int _currentWordIndex = 0; // Index of currently displayed word
  String? _sessionId; // Store session ID from backend

  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsSpeaking = false;

  // Journey data for progress widget
  int _userStreak = 0;
  int _userPoints = 0;
  String _userMainLevel = 'Beginner';
  String _userSubLevel = 'Low';
  bool _isLoadingJourneyData = false;
  
  // Flag to track if points were added to avoid double counting
  bool _pointsAdded = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Work', 'icon': Icons.work_outline},
    {'label': 'Study', 'icon': Icons.school_outlined},
    {'label': 'Religion', 'icon': Icons.mosque_outlined},
    {'label': 'Daily Life', 'icon': Icons.home_outlined},
    {'label': 'Travel', 'icon': Icons.flight_outlined},
    {'label': 'Shopping', 'icon': Icons.shopping_bag_outlined},
    {'label': 'Technology', 'icon': Icons.computer_outlined},
    {'label': 'Custom', 'icon': Icons.tune_outlined},
  ];

  // Colors from level exam page
  Color _backgroundColor() => const Color(0xFFF5F1E8); // بيج فاتح
  Color _primaryColor() => const Color(0xFF14B8A6); // Teal
  Color _darkTealColor() => const Color(0xFF0D9488); // Teal غامق

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadJourneyData();
  }
  
  Future<void> _loadJourneyData() async {
    setState(() => _isLoadingJourneyData = true);
    try {
      final journeyData = await CurrentJourneyService.fetchCurrent();
      if (mounted) {
        setState(() {
          _userStreak = journeyData.data.streak;
          _userPoints = journeyData.data.points;
          _userMainLevel = journeyData.data.mainLevel;
          _userSubLevel = journeyData.data.subLevel;
          _isLoadingJourneyData = false;
        });
      }
    } catch (e) {
      print('⚠️ Failed to load journey data: $e');
      if (mounted) {
        setState(() => _isLoadingJourneyData = false);
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      // Try to use Google TTS engine (better for Arabic)
      final engines = await _flutterTts.getEngines;
      if (engines != null && engines.isNotEmpty) {
        final googleEngine = engines.firstWhere(
          (engine) => engine['name']?.toString().toLowerCase().contains('google') ?? false,
          orElse: () => engines.first,
        );
        if (googleEngine['name'] != null) {
          await _flutterTts.setEngine(googleEngine['name']);
        }
      }
    } catch (e) {
      print('⚠️ Could not set TTS engine: $e');
    }
    
    // Default settings
    await _flutterTts.setLanguage("ar-SA"); // Arabic - Saudi Arabia (best quality)
    await _flutterTts.setSpeechRate(0.45); // Slightly slower for better quality
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      setState(() => _isTtsSpeaking = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      print('❌ TTS Error: $msg');
      setState(() => _isTtsSpeaking = false);
    });
  }

  // Detect language automatically based on text
  String _detectLanguage(String text) {
    final arabicPattern = RegExp(r'[\u0600-\u06FF]');
    if (arabicPattern.hasMatch(text)) {
      return 'ar-SA'; // Arabic - Saudi Arabia (best quality)
    } else {
      return 'en-US'; // English - US (best quality)
    }
  }

  Future<void> _speakText(String text, {String? language}) async {
    try {
      if (_isTtsSpeaking) {
        await _flutterTts.stop();
      }
      
      setState(() => _isTtsSpeaking = true);
      
      // Detect language automatically if not specified
      final langToUse = language ?? _detectLanguage(text);
      await _flutterTts.setLanguage(langToUse);
      
      // Optimize settings based on language
      if (langToUse.startsWith('en')) {
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      } else if (langToUse.startsWith('ar')) {
        await _flutterTts.setSpeechRate(0.45);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        if (langToUse != 'ar-SA') {
          await _flutterTts.setLanguage('ar-SA');
        }
      } else {
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      }
      
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

  // Removed _generateMockWords - now using API call in _startLearning

  Map<String, dynamic> _buildConfig() {
    if (_isCustomSelected()) {
      return {
        'mode': 'custom',
        'topic': _customTopic,
        'situation': _selectedSituation,
        'focus': _selectedFocus.toList(),
        'level': _difficultyLevel,
        'wordCount': _selectedWordCount,
      };
    } else {
      return {
        'mode': 'preset',
        'categories': _selectedCategories.where((c) => c != 'Custom').toList(),
        'wordCount': _selectedWordCount,
      };
    }
  }

  Future<void> _startLearning() async {
    if (_selectedCategories.isEmpty) return;
    
    // Handle Custom mode - not implemented yet
    if (_isCustomSelected()) {
      if (_customTopic.isEmpty && _selectedSituation == null && _selectedFocus.isEmpty) {
        return; // Need at least one custom option
      }
      // Show SnackBar for custom mode
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom mode is not implemented yet'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Build configuration object
    _learningConfig = _buildConfig();

    // Show loading
    setState(() {
      _isLoadingWords = true;
      _isSetupState = false;
      _currentWordIndex = 0;
    });

    try {
      // Call backend API to start session
      final categories = _selectedCategories.where((c) => c != 'Custom').toList();
      final result = await VocabularyService.startSession(
        categories: categories,
        count: _selectedWordCount,
      );

      // Extract sessionId and words from response
      final sessionId = result['sessionId'] as String?;
      final words = result['words'] as List?;
      
      if (sessionId == null || words == null) {
        throw Exception('Invalid response: missing sessionId or words');
      }

      // Process words: extract learned/saved status
      final learnedWords = <String>{};
      final savedWords = <String>{};
      final processedWords = <Map<String, dynamic>>[];
      
      for (final word in words) {
        if (word is Map<String, dynamic>) {
          final wordId = (word['id'] ?? word['_id'] ?? '').toString();
          
          if (wordId.isNotEmpty) {
            if (word['learned'] == true) {
              learnedWords.add(wordId);
            }
            if (word['saved'] == true) {
              savedWords.add(wordId);
            }
          }
          
          processedWords.add(word);
        }
      }

      setState(() {
        _sessionId = sessionId;
        _vocabularyWords = processedWords;
        _learnedWords = learnedWords;
        _savedWords = savedWords;
        _isLoadingWords = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWords = false;
        _isSetupState = true; // Go back to setup on error
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isCustomSelected() {
    return _selectedCategories.contains('Custom');
  }

  void _toggleSituation(String situation) {
    setState(() {
      _selectedSituation = _selectedSituation == situation ? null : situation;
    });
  }

  void _toggleFocus(String focus) {
    setState(() {
      if (_selectedFocus.contains(focus)) {
        _selectedFocus.remove(focus);
      } else {
        _selectedFocus.add(focus);
      }
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (category == 'Custom') {
        // If clicking Custom
        if (_selectedCategories.contains('Custom')) {
          // Deselect Custom
          _selectedCategories.remove('Custom');
        } else {
          // Select Custom only, clear all preset categories
          _selectedCategories.clear();
          _selectedCategories.add('Custom');
        }
      } else {
        // If clicking a preset category
        if (_selectedCategories.contains('Custom')) {
          // Custom is selected, so deselect it first
          _selectedCategories.remove('Custom');
        }
        // Toggle the preset category
        if (_selectedCategories.contains(category)) {
          _selectedCategories.remove(category);
        } else {
          _selectedCategories.add(category);
        }
      }
    });
  }

  bool _isPresetCategoryDisabled(String category) {
    // Disable preset categories when Custom is selected
    return _isCustomSelected() && category != 'Custom';
  }

  bool _canStartLearning() {
    if (_selectedCategories.isEmpty) return false;
    if (_isCustomSelected()) {
      // For custom, need at least one custom option
      return _customTopic.isNotEmpty || _selectedSituation != null || _selectedFocus.isNotEmpty;
    }
    // For preset categories, can start if at least one is selected
    return true;
  }

  Future<void> _toggleLearned(String wordId) async {
    if (_sessionId == null) return;

    final currentState = _learnedWords.contains(wordId);
    final newState = !currentState;
    final isNewlyLearned = !currentState && newState; // فقط عند التحويل من غير متعلم إلى متعلم

    // Optimistic update
    setState(() {
      if (newState) {
        _learnedWords.add(wordId);
      } else {
        _learnedWords.remove(wordId);
      }
    });

    try {
      // تحديث حالة الكلمة
      await VocabularyService.updateWordStatus(
        sessionId: _sessionId!,
        wordId: wordId,
        learned: newState,
      );
      
      // Note: Points will be added when finishing the session (5 points per learned word)
    } catch (e) {
      // Revert on error
      setState(() {
        if (currentState) {
          _learnedWords.add(wordId);
        } else {
          _learnedWords.remove(wordId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCompletionDialog(int learnedCount, int totalPoints) {
    // Reset points flag when showing dialog
    _pointsAdded = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VocabularyCompletionDialog(
        learnedCount: learnedCount,
        totalPoints: totalPoints,
        onLearnMore: () async {
          // Try to add points to backend (if endpoint exists)
          // Note: Backend should add points automatically when finishing session
          try {
            print('🟢 Attempting to add $totalPoints points to backend...');
            final result = await CurrentJourneyService.addPoints(points: totalPoints);
            _pointsAdded = true;
            print('✅ Points added successfully. New points: ${result.data.points}');
            // Reload journey data to update points display
            await _loadJourneyData();
          } catch (e) {
            print('⚠️ Points endpoint not available. Backend should add points automatically: $e');
            // Don't show error to user - backend may add points automatically
            _pointsAdded = true; // Mark as handled to prevent retry
          }
          
          if (mounted) {
            Navigator.of(context).pop(); // Close dialog
            // Reload journey data to refresh points (in case backend added them)
            await _loadJourneyData();
            // Reset to setup state to start new session
            setState(() {
              _isSetupState = true;
              _vocabularyWords = [];
              _learnedWords = {};
              _savedWords = {};
              _currentWordIndex = 0;
              _sessionId = null;
            });
          }
        },
        onBackToHome: () async {
          // Try to add points to backend (if endpoint exists)
          // Note: Backend should add points automatically when finishing session
          try {
            print('🟢 Attempting to add $totalPoints points to backend...');
            final result = await CurrentJourneyService.addPoints(points: totalPoints);
            _pointsAdded = true;
            print('✅ Points added successfully. New points: ${result.data.points}');
            // Reload journey data to update points display
            await _loadJourneyData();
          } catch (e) {
            print('⚠️ Points endpoint not available. Backend should add points automatically: $e');
            // Don't show error to user - backend may add points automatically
            _pointsAdded = true; // Mark as handled to prevent retry
          }
          
          if (mounted) {
            Navigator.of(context).pop(); // Close dialog
            Navigator.pushReplacementNamed(context, '/home_screen');
          }
        },
      ),
    );
  }

  Future<void> _toggleSaved(String wordId) async {
    if (_sessionId == null) return;

    final currentState = _savedWords.contains(wordId);
    final newState = !currentState;

    // Optimistic update
    setState(() {
      if (newState) {
        _savedWords.add(wordId);
      } else {
        _savedWords.remove(wordId);
      }
    });

    try {
      await VocabularyService.updateWordStatus(
        sessionId: _sessionId!,
        wordId: wordId,
        saved: newState,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        if (currentState) {
          _savedWords.add(wordId);
        } else {
          _savedWords.remove(wordId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor(),
      body: SafeArea(
        child: _isSetupState ? _buildSetupState() : _buildWordsState(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(1), // Vocabulary tab is active
    );
  }

  Widget _buildSetupState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button and Title
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Expanded(
                child: Text(
                  'Vocabulary',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance the back button width
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Widget (only in setup state)
          if (!_isLoadingJourneyData)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _VocabularyProgressWidget(
                streak: _userStreak,
                points: _userPoints,
                mainLevel: _userMainLevel,
                subLevel: _userSubLevel,
                accent: _darkTealColor(),
              ),
            ),
          
          const SizedBox(height: 8),
          const Text(
            'Choose your learning goal and number of words for today.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 32),

          // Step 1: Goal Selection
          const Text(
            'What do you want to learn today?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index]['label']!;
              final icon = _categories[index]['icon']! as IconData;
              final isSelected = _selectedCategories.contains(category);
              final isDisabled = _isPresetCategoryDisabled(category);

              return GestureDetector(
                onTap: isDisabled ? null : () => _toggleCategory(category),
                child: Opacity(
                  opacity: isDisabled ? 0.4 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor().withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _primaryColor() : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 32,
                          color: isSelected ? _primaryColor() : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? _primaryColor() : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle, size: 16, color: Color(0xFF14B8A6)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            _isCustomSelected()
                ? 'Custom mode is active. To select categories, turn off Custom.'
                : 'Select one or more categories.',
            style: TextStyle(
              fontSize: 14,
              color: _isCustomSelected() ? _primaryColor() : Colors.grey.shade600,
              fontStyle: FontStyle.italic,
              fontWeight: _isCustomSelected() ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 32),

          // Custom Vocabulary Sections (shown when Custom is selected)
          if (_isCustomSelected()) ...[
            _buildCustomTopicSection(),
            const SizedBox(height: 24),
            _buildSituationSection(),
            const SizedBox(height: 24),
            _buildFocusSection(),
            const SizedBox(height: 24),
            _buildDifficultySection(),
            const SizedBox(height: 24),
            _buildCustomSummaryCard(),
            const SizedBox(height: 24),
          ],

          // Step 2: Word Count Selection
          const Text(
            'How many words do you want to learn?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _selectedWordCount.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            label: _selectedWordCount.toString(),
            activeColor: _primaryColor(),
            onChanged: (value) {
              setState(() {
                _selectedWordCount = value.toInt();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWordCountButton(5, 'Quick'),
              _buildWordCountButton(10, 'Standard'),
              _buildWordCountButton(20, 'Challenge'),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Today: $_selectedWordCount words',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _darkTealColor(),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Start Learning Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canStartLearning() ? _startLearning : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkTealColor(),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isCustomSelected() ? 'Start Custom Learning' : 'Start Learning',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCustomTopicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your custom topic',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Type a topic you want to learn vocabulary for.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) {
            setState(() {
              _customTopic = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'e.g. travel, hospital, football, cooking, prayer',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSituationSection() {
    final situations = [
      'At work',
      'At school',
      'In conversations',
      'While traveling',
      'At the mosque',
      'Online / social media',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where will you use these words?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: situations.map((situation) {
            final isSelected = _selectedSituation == situation;
            return GestureDetector(
              onTap: () => _toggleSituation(situation),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor() : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _primaryColor() : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Text(
                  situation,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFocusSection() {
    final focusOptions = ['Speaking', 'Reading', 'Writing', 'Listening'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you want to focus on?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: focusOptions.map((focus) {
            final isSelected = _selectedFocus.contains(focus);
            return GestureDetector(
              onTap: () => _toggleFocus(focus),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor().withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _primaryColor() : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(Icons.check_circle, size: 18, color: _primaryColor())
                    else
                      Icon(Icons.circle_outlined, size: 18, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      focus,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? _primaryColor() : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultySection() {
    final difficulties = ['Beginner', 'Intermediate', 'Advanced'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose difficulty level',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: difficulties.map((difficulty) {
            final isSelected = _difficultyLevel == difficulty;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _difficultyLevel = difficulty;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: difficulty != difficulties.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _darkTealColor() : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _darkTealColor() : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    difficulty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Custom Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkTealColor(),
            ),
          ),
          const SizedBox(height: 12),
          if (_customTopic.isNotEmpty)
            _buildSummaryRow('Topic', _customTopic),
          if (_selectedSituation != null)
            _buildSummaryRow('Situation', _selectedSituation!),
          if (_selectedFocus.isNotEmpty)
            _buildSummaryRow('Focus', _selectedFocus.join(', ')),
          _buildSummaryRow('Level', _difficultyLevel),
          _buildSummaryRow('Words', '$_selectedWordCount'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCountButton(int count, String label) {
    final isSelected = _selectedWordCount == count;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWordCount = count;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _darkTealColor() : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _darkTealColor() : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordsState() {
    final learnedCount = _learnedWords.length;
    final totalWords = _vocabularyWords.length;

    // Build subtitle based on config
    String subtitle = '$_selectedWordCount words';
    if (_learningConfig != null) {
      if (_learningConfig!['mode'] == 'preset') {
        final categories = _learningConfig!['categories'] as List;
        subtitle = '${categories.join(', ')} • $_selectedWordCount words';
      } else {
        final topic = _learningConfig!['topic'] as String?;
        if (topic != null && topic.isNotEmpty) {
          subtitle = 'Custom • $topic • $_selectedWordCount words';
        } else {
          subtitle = 'Custom • $_selectedWordCount words';
        }
      }
    }

    // Get current word
    final currentWord = _currentWordIndex < _vocabularyWords.length 
        ? _vocabularyWords[_currentWordIndex] 
        : null;
    final wordId = currentWord != null ? (currentWord['id'] ?? currentWord['_id'] ?? '').toString() : '';
    final isLearned = _learnedWords.contains(wordId);
    final isSaved = _savedWords.contains(wordId);

    return Column(
      children: [
        // Top Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSetupState = true;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Vocabulary List',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate back to setup, keep previous selections
                      setState(() {
                        _isSetupState = true;
                      });
                    },
                    child: Text(
                      'Change',
                      style: TextStyle(
                        color: _primaryColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Single Word Display
        Expanded(
          child: _isLoadingWords
              ? _buildLoadingSkeleton()
              : currentWord == null
                  ? const Center(child: Text('No words available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Word Counter Indicator
                          Text(
                            'Word ${_currentWordIndex + 1} of $totalWords',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Word Card - Using new VocabularyCard widget
                          VocabularyCard(
                            arabicWord: (currentWord['arabic'] ?? 
                                        currentWord['word'] ?? 
                                        currentWord['arabicWord'] ?? 
                                        currentWord['text'] ?? 
                                        '') as String,
                            transliteration: (currentWord['transliteration'] ?? 
                                             currentWord['pronunciation'] ?? 
                                             currentWord['phonetic'] ?? 
                                             '') as String?,
                            meaning: (currentWord['english'] ?? 
                                     currentWord['meaning'] ?? 
                                     currentWord['translation'] ?? 
                                     currentWord['englishWord'] ?? 
                                     '') as String,
                            exampleAr: (currentWord['exampleAr'] ?? 
                                       currentWord['example'] ?? 
                                       currentWord['exampleSentence'] ?? 
                                       currentWord['sentence'] ?? 
                                       '') as String?,
                            exampleEn: (currentWord['exampleEn'] ?? 
                                       currentWord['exampleEnglish'] ?? 
                                       currentWord['exampleTranslation'] ?? 
                                       '') as String?,
                            isBookmarked: isSaved,
                            isLearned: isLearned,
                            isSpeaking: _isTtsSpeaking,
                            onSpeak: () {
                              if (_isTtsSpeaking) {
                                _stopTts();
                              } else {
                                final arabicWord = (currentWord['arabic'] ?? 
                                                   currentWord['word'] ?? 
                                                   currentWord['arabicWord'] ?? 
                                                   currentWord['text'] ?? 
                                                   '') as String;
                                if (arabicWord.isNotEmpty) {
                                  _speakText(arabicWord);
                                }
                              }
                            },
                            onToggleBookmark: () => _toggleSaved(wordId),
                            onToggleLearned: () => _toggleLearned(wordId),
                          ),
                        ],
                      ),
                    ),
        ),

        // Navigation Buttons (Previous/Next)
        if (!_isLoadingWords && totalWords > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentWordIndex > 0
                        ? () {
                            setState(() {
                              _currentWordIndex--;
                            });
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentWordIndex < totalWords - 1
                        ? () {
                            setState(() {
                              _currentWordIndex++;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkTealColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentWordIndex < totalWords - 1 ? 'Next' : 'Last Word'),
                  ),
                ),
              ],
            ),
          ),

        // Progress Indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$learnedCount of $totalWords words learned',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    totalWords > 0 ? '${((learnedCount / totalWords) * 100).toInt()}%' : '0%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _darkTealColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalWords > 0 ? learnedCount / totalWords : 0.0,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_darkTealColor()),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: learnedCount == totalWords && totalWords > 0 && _sessionId != null
                      ? () async {
                          // Call finish session API
                          try {
                            final result = await VocabularyService.finishSession(_sessionId!);
                            final learnedCountFromApi = result['learnedCount'] as int? ?? learnedCount;
                            final savedCount = result['savedCount'] as int? ?? 0;
                            
                            // Calculate total points earned (5 points per learned word)
                            final totalPointsEarned = learnedCountFromApi * 5;
                            
                            if (mounted) {
                              // Show completion dialog with points
                              _showCompletionDialog(learnedCountFromApi, totalPointsEarned);
                            }
                          } catch (e) {
                            // Check if session is already finished
                            final errorMessage = e.toString().replaceFirst('Exception: ', '').toLowerCase();
                            final isAlreadyFinished = errorMessage.contains('already finished') || 
                                                      errorMessage.contains('already completed') ||
                                                      errorMessage.contains('session is already');
                            
                            if (mounted) {
                              if (isAlreadyFinished) {
                                // Session already finished - calculate points and show dialog
                                final totalPointsEarned = learnedCount * 5;
                                _showCompletionDialog(learnedCount, totalPointsEarned);
                              } else {
                                // Other error - show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkTealColor(),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    learnedCount == totalWords && totalWords > 0
                        ? 'Finish Session'
                        : 'Complete all words to finish',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Show 5 skeleton cards
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 24,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(int currentIndex) {
    final primary = Theme.of(context).colorScheme.primary;
    return BottomNavigationBar(
      currentIndex: 0, // Home tab is active (Vocabulary is accessed from Home)
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == 0) {
          Navigator.pushReplacementNamed(context, '/home_screen');
        } else if (i == 3) {
          Navigator.pushNamed(context, '/profile_main_screen');
        }
        // Handle Community and Chatbot tabs as needed
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy_outlined),
          label: 'Chatbot',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}

/// Dialog widget for vocabulary session completion
class _VocabularyCompletionDialog extends StatelessWidget {
  final int learnedCount;
  final int totalPoints;
  final VoidCallback onLearnMore;
  final VoidCallback onBackToHome;

  const _VocabularyCompletionDialog({
    required this.learnedCount,
    required this.totalPoints,
    required this.onLearnMore,
    required this.onBackToHome,
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
            // Success icon
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
            
            // Congratulations title
            const Text(
              "Congratulations!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            // Completion message
            Text(
              "You have learned $learnedCount words!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Points earned
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
                    "Points Earned: $totalPoints",
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
            
            // Learn More button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onLearnMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  "Learn More",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Go to Home button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBackToHome,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  "Go to Home",
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

/// Progress Widget for Vocabulary Screen (without stage progress)
class _VocabularyProgressWidget extends StatelessWidget {
  final int streak;
  final int points;
  final String mainLevel;
  final String subLevel;
  final Color accent;

  const _VocabularyProgressWidget({
    required this.streak,
    required this.points,
    required this.mainLevel,
    required this.subLevel,
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
          // Level Row (without stage progress on the right)
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
            ],
          ),

          const SizedBox(height: 12),

          // Streak and Points Row
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suffix,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
