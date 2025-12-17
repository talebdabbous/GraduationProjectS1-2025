import 'package:flutter/material.dart';
import '../services/letter_sounds_service.dart';
import 'letter_sound_detail_screen.dart';

class LetterSoundsScreen extends StatefulWidget {
  const LetterSoundsScreen({super.key});

  @override
  State<LetterSoundsScreen> createState() => _LetterSoundsScreenState();
}

class _LetterSoundsScreenState extends State<LetterSoundsScreen> {
  List<LetterSound> _letters = [];
  bool _isLoading = true;
  String _sortMode = 'difficulty'; // 'difficulty' or 'alphabetical'

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    try {
      print('🔄 Loading letters...');
      final letters = await LetterSoundsService.fetchLetterSounds();
      print('✅ Loaded ${letters.length} letters');
      
      if (mounted) {
        print('📋 Setting state with ${letters.length} letters');
        setState(() {
          _letters = letters;
          _isLoading = false;
        });
        print('📋 State updated, _letters.length = ${_letters.length}');
        _sortLetters();
        
        // Debug: Print first few letters
        if (_letters.isNotEmpty) {
          print('📋 First letter: ${_letters.first.letter}, order: ${_letters.first.order}');
          print('📋 All letters: ${_letters.map((l) => l.letter).join(", ")}');
        } else {
          print('⚠️ Letters list is empty after loading!');
          print('⚠️ This could mean:');
          print('  1. Backend returned empty array');
          print('  2. All items failed to parse');
          print('  3. Check backend response structure');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error loading letters: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading letters: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadLetters();
              },
            ),
          ),
        );
      }
    }
  }

  void _sortLetters() {
    setState(() {
      if (_sortMode == 'difficulty') {
        // Sort by difficultyLevel (1 -> 2 -> 3, easy -> hard)
        _letters.sort((a, b) => a.difficultyLevel.compareTo(b.difficultyLevel));
      } else {
        // Sort by order (alphabetical)
        _letters.sort((a, b) => a.order.compareTo(b.order));
      }
    });
  }

  void _onSortModeChanged(String mode) {
    if (_sortMode != mode) {
      setState(() {
        _sortMode = mode;
      });
      _sortLetters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Letter Sounds Reference',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Toggle Bar
          _buildToggleBar(),
          
          // Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _letters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No letters found (${_letters.length})',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                });
                                _loadLetters();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Debug info
                          if (_letters.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Showing ${_letters.length} letters',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          // Grid
                          Expanded(child: _buildGrid()),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'By Difficulty',
              isSelected: _sortMode == 'difficulty',
              onTap: () => _onSortModeChanged('difficulty'),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Alphabetical',
              isSelected: _sortMode == 'alphabetical',
              onTap: () => _onSortModeChanged('alphabetical'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    print('🔍 Building grid with ${_letters.length} letters');
    if (_letters.isEmpty) {
      return const Center(
        child: Text('No letters to display'),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _letters.length,
      itemBuilder: (context, index) {
        final letter = _letters[index];
        print('🔍 Building card for letter: ${letter.letter} at index $index');
        return _buildLetterCard(letter);
      },
    );
  }

  Widget _buildLetterCard(LetterSound letter) {
    print('🎴 Building card for letter: "${letter.letter}" (isEmpty: ${letter.letter.isEmpty})');
    
    // If letter is empty, show placeholder
    final displayLetter = letter.letter.isEmpty ? '?' : letter.letter;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LetterSoundDetailScreen(letter: letter),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayLetter,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

