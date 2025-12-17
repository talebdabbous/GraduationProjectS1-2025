import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/letter_sounds_service.dart';

class LetterSoundDetailScreen extends StatefulWidget {
  final LetterSound letter;

  const LetterSoundDetailScreen({
    super.key,
    required this.letter,
  });

  @override
  State<LetterSoundDetailScreen> createState() => _LetterSoundDetailScreenState();
}

class _LetterSoundDetailScreenState extends State<LetterSoundDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _currentIndex = 0;

  final List<String> _soundTypes = ['fatha', 'kasra', 'damma', 'sukun'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });

    _initAudioPlayer();
    // Auto-play first sound
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playCurrentSound();
    });
  }

  void _initAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _audioPlayer.setVolume(1.0);
    _audioPlayer.setBalance(0.0);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _onTabChanged(int index) {
    if (_currentIndex != index) {
      _stopAudio();
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Auto-play new sound
      Future.delayed(const Duration(milliseconds: 100), () {
        _playCurrentSound();
      });
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      _stopAudio();
      setState(() {
        _currentIndex = index;
      });
      _tabController.animateTo(index);
      // Auto-play new sound
      Future.delayed(const Duration(milliseconds: 100), () {
        _playCurrentSound();
      });
    }
  }

  Future<void> _playCurrentSound() async {
    final soundType = _soundTypes[_currentIndex];
    final audioUrl = widget.letter.sounds.getAudioUrl(soundType);
    
    if (audioUrl == null || audioUrl.isEmpty) {
      print('⚠️ No audio URL for $soundType');
      return;
    }

    try {
      await _audioPlayer.play(UrlSource(audioUrl));
      print('✅ Playing audio: $audioUrl');
    } catch (e) {
      print('❌ Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('❌ Error stopping audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.letter.letter,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Fatha'),
            Tab(text: 'Kasra'),
            Tab(text: 'Damma'),
            Tab(text: 'Sukun'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: 4,
              itemBuilder: (context, index) {
                return _buildSoundPage(_soundTypes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundPage(String soundType) {
    final arabicForm = widget.letter.sounds.getArabicForm(soundType);
    final transliteration = widget.letter.sounds.getTransliteration(soundType);
    final audioUrl = widget.letter.sounds.getAudioUrl(soundType);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Arabic Form
          if (arabicForm != null && arabicForm.isNotEmpty)
            Text(
              arabicForm,
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            )
          else
            Text(
              widget.letter.letter,
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Transliteration
          if (transliteration != null && transliteration.isNotEmpty)
            Text(
              transliteration,
              style: const TextStyle(
                fontSize: 32,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          const SizedBox(height: 48),
          
          // Play Button
          if (audioUrl != null && audioUrl.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _isPlaying ? null : _playCurrentSound,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
              ),
              label: Text(
                _isPlaying ? 'Playing...' : 'Play Sound',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            const Text(
              'No audio available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}

