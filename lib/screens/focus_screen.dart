import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/focus_session.dart';
import '../providers/app_providers.dart';
import '../features/calm/application/enhanced_audio_controller.dart';
import '../models/ambient_sound.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with TickerProviderStateMixin {
  // Config

  int _durationMinutes = 25;

  String _taskName = '';

  FocusMode _selectedMode = FocusMode.timer;

  String? _selectedResource; // Video URL or Sound name

  // State

  bool _isActive = false;
  late final ValueNotifier<int> _remainingSeconds;
  Timer? _timer;
  YoutubePlayerController? _videoController;
  DateTime? _sessionStartedAt;

  // Audio Controller for sounds
  EnhancedAudioController? _audioController;

  // Animation
  late AnimationController _breathingController;

  // Resources

  final List<Map<String, String>> _videos = [
    {'title': 'Lofi Girl - Study Music', 'id': 'jfKfPfyJRdk'},
    {'title': 'Soft Piano Music', 'id': 'm7Bc3pLyij0'},
    {'title': 'Nature Sounds Forest', 'id': 'IvjMgVS6kng'},
    {'title': 'Ambient Study Music', 'id': 's49CT4DTAkw'},
  ];

  final List<Map<String, dynamic>> _sounds = [
    {'title': 'Violin', 'emoji': '🎻', 'color': 0xFF9C27B0},
    {'title': 'Piano', 'emoji': '🎹', 'color': 0xFF2196F3},
    {'title': 'Deep Forest', 'emoji': '🌲', 'color': 0xFF4CAF50},
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = ValueNotifier(_durationMinutes * 60);
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    // Initialize audio controller
    _audioController = ref.read(enhancedAudioControllerProvider.notifier);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remainingSeconds.dispose();
    _breathingController.dispose();
    _videoController?.dispose();
    // Stop any playing audio
    _audioController?.stopAllSounds();
    super.dispose();
  }

  void _startFocus() {
    if (_taskName.isEmpty) _taskName = 'Focus';

    // Start playing sound if sound mode is selected
    if (_selectedMode == FocusMode.sound && _selectedResource != null) {
      _playSound(_selectedResource!);
    }

    if (_selectedMode == FocusMode.video && _selectedResource != null) {
      // Stop any playing sounds when starting video
      _audioController?.stopAllSounds();

      // PROPER CLEANUP

      _videoController?.dispose();

      _videoController = YoutubePlayerController(
        initialVideoId: _selectedResource!,

        flags: const YoutubePlayerFlags(
          autoPlay: false, // Manual load only

          mute: false,

          isLive: false,

          forceHD: false, // Reduced for reliability

          enableCaption: false,

          hideControls: false,
        ),
      );
    }

    setState(() {
      _isActive = true;
      _remainingSeconds.value = _durationMinutes * 60;
      _sessionStartedAt = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds.value > 0) {
        _remainingSeconds.value--;
      } else {
        _completeFocus();
      }
    }); // No setState here to prevent rebuilding Video Player
  }

  Future<void> _completeFocus() async {
    _timer?.cancel();

    _videoController?.pause();

    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final session = FocusSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        startTime: _sessionStartedAt ?? DateTime.now(),
        durationMinutes: _durationMinutes,
        taskName: _taskName,
        mode: _selectedMode,
        resourceId: _selectedResource,
        completed: true,
      );

      await ref.read(focusServiceProvider).saveSession(session);
    }

    setState(() {
      _isActive = false;
      _sessionStartedAt = null;
    });

    if (mounted) {
      showDialog(
        context: context,

        builder: (context) => AlertDialog(
          title: const Text('Session Complete'),

          content: Text(
            'Great job focusing on "$_taskName" for $_durationMinutes mins!',
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),

              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _stopFocus() {
    _timer?.cancel();
    _videoController?.pause();
    // Stop playing sounds
    _audioController?.stopAllSounds();
    setState(() {
      _isActive = false;
      _sessionStartedAt = null;
    });
  }

  void _playSound(String soundTitle) {
    // Find the AmbientSound that matches the title
    final sound = AmbientSound.defaults.firstWhere(
      (s) => s.name == soundTitle,
      orElse: () => AmbientSound.defaults.first,
    );
    _audioController?.playSound(sound, openPlayer: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isActive &&
        _selectedMode == FocusMode.video &&
        _videoController != null) {
      return _buildVideoFocusView();
    }

    if (_isActive) {
      return _buildActiveTimerView();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea), // Soft purple
              Color(0xFF764ba2), // Soft violet
              Color(0xFFf093fb), // Soft pink
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Focus Session',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Task Input Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What are you focusing on?',
                            style: GoogleFonts.lato(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => _taskName = v,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Reading, Coding, Studying...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Duration Section
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Duration',
                      style: GoogleFonts.lato(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [15, 25, 30, 45, 60].map((mins) {
                      final isSelected = _durationMinutes == mins;
                      return GestureDetector(
                        onTap: () => setState(() => _durationMinutes = mins),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFf6d365),
                                      Color(0xFFfda085),
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFf6d365,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '$mins min',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 28),

                // Environment Section
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Environment',
                      style: GoogleFonts.lato(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeTab(
                        'Zen',
                        FocusMode.timer,
                        Icons.self_improvement,
                        const Color(0xFF4facfe),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeTab(
                        'Sound',
                        FocusMode.sound,
                        Icons.music_note,
                        const Color(0xFF43e97b),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeTab(
                        'Video',
                        FocusMode.video,
                        Icons.videocam,
                        const Color(0xFFfa709a),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Resources Grid
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedMode == FocusMode.video
                      ? _buildVideoGrid()
                      : _selectedMode == FocusMode.sound
                      ? _buildSoundGrid()
                      : _buildZenPlaceholder(),
                ),

                const SizedBox(height: 32),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startFocus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFf5576c,
                            ).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Start Focus Session',
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(
    String label,
    FocusMode mode,
    IconData icon,
    Color accentColor,
  ) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMode = mode;
        _selectedResource = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZenPlaceholder() {
    return Container(
      key: const ValueKey('zen'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.self_improvement,
            color: Colors.white.withValues(alpha: 0.8),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Pure Zen Mode',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Focus in silence with just the timer. No distractions.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4facfe).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4facfe).withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'Minimal & Clean',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Curated Focus Videos',
          style: GoogleFonts.lato(color: Colors.white54, fontSize: 12),
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 12,

          runSpacing: 12,

          children: _videos.map((video) {
            final isSelected = _selectedResource == video['id'];

            return GestureDetector(
              onTap: () => setState(() => _selectedResource = video['id']),

              child: Container(
                width: 150,

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                      : Colors.white10,

                  borderRadius: BorderRadius.circular(12),

                  border: isSelected
                      ? Border.all(color: const Color(0xFF6C63FF))
                      : null,
                ),

                child: Column(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 32,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      video['title']!,

                      style: const TextStyle(color: Colors.white, fontSize: 12),

                      overflow: TextOverflow.ellipsis,
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

  Widget _buildSoundGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ambient Sounds',
          style: GoogleFonts.lato(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a sound to accompany your focus session',
          style: GoogleFonts.lato(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _sounds.length,
          itemBuilder: (context, index) {
            final sound = _sounds[index];
            final isSelected = _selectedResource == sound['title'];

            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedResource = sound['title'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6C63FF),
                            const Color(0xFF6C63FF).withValues(alpha: 0.7),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1.5,
                        )
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(fontSize: isSelected ? 40 : 32),
                      child: Text(sound['emoji'] as String),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sound['title'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveTimerView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),

      body: SafeArea(
        child: Stack(
          children: [
            // Zen Circle Animation
            Center(
              child: AnimatedBuilder(
                animation: _breathingController,

                builder: (context, child) {
                  return Container(
                    width: 300 + (_breathingController.value * 20),

                    height: 300 + (_breathingController.value * 20),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withValues(alpha: 0.2),

                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Timer Text
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _remainingSeconds,

                    builder: (context, val, _) => Text(
                      _formatTime(val),

                      style: GoogleFonts.lato(
                        fontSize: 64,

                        fontWeight: FontWeight.w100,

                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _taskName,

                    style: GoogleFonts.lato(
                      fontSize: 24,
                      color: Colors.white70,
                    ),
                  ),

                  if (_selectedMode == FocusMode.sound &&
                      _selectedResource != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          const Icon(
                            Icons.music_note,
                            color: Colors.white54,
                            size: 16,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            'Playing: $_selectedResource',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Stop Button
            Positioned(
              bottom: 60,

              left: 0,

              right: 0,

              child: Center(
                child: FloatingActionButton.large(
                  onPressed: _stopFocus,

                  backgroundColor: Colors.white10,

                  foregroundColor: Colors.white,

                  child: const Icon(Icons.stop),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFocusView() {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Center(
            child: YoutubePlayer(
              controller: _videoController!,

              showVideoProgressIndicator: true,

              progressIndicatorColor: const Color(0xFF6C63FF),

              onReady: () {
                _videoController?.addListener(() {
                  if (mounted && _videoController?.value.errorCode != 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${_videoController?.value.errorCode}',
                        ),
                      ),
                    );
                  }
                });

                _videoController?.load(_selectedResource!);
              },
            ),
          ),

          // Central Play Button (Fallback)
          Positioned.fill(
            child: ValueListenableBuilder<YoutubePlayerValue>(
              valueListenable: _videoController!,

              builder: (context, value, _) {
                if (value.playerState == PlayerState.playing ||
                    value.playerState == PlayerState.buffering) {
                  return const SizedBox.shrink();
                }

                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,

                      shape: BoxShape.circle,
                    ),

                    child: IconButton(
                      iconSize: 80,

                      icon: const Icon(Icons.play_arrow, color: Colors.white),

                      onPressed: () =>
                          _videoController?.load(_selectedResource!),
                    ),
                  ),
                );
              },
            ),
          ),

          if (kDebugMode)
            Positioned(
              bottom: 110,
              left: 24,
              child: ValueListenableBuilder<YoutubePlayerValue>(
                valueListenable: _videoController!,
                builder: (context, value, _) {
                  return Text(
                    'ID: $_selectedResource\nStatus: ${value.playerState}\nErr: ${value.errorCode}\nBuf: ${value.buffered}s',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 10,
                      fontFamily: 'Courier',
                    ),
                  );
                },
              ),
            ),

          // Refresh Button
          Positioned(
            top: 40,

            left: 24,

            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),

              onPressed: () => _videoController?.load(_selectedResource!),

              tooltip: 'Reload Video',
            ),
          ),

          // Overlay Timer
          Positioned(
            top: 40,

            right: 24,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              decoration: BoxDecoration(
                color: Colors.black54,

                borderRadius: BorderRadius.circular(20),
              ),

              child: ValueListenableBuilder<int>(
                valueListenable: _remainingSeconds,

                builder: (context, val, _) => Text(
                  _formatTime(val),

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Stop Button
          Positioned(
            bottom: 40,

            left: 0,

            right: 0,

            child: Center(
              child: FloatingActionButton(
                onPressed: _stopFocus,

                backgroundColor: Colors.black54,

                foregroundColor: Colors.white,

                child: const Icon(Icons.stop),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;

    final s = totalSeconds % 60;

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
