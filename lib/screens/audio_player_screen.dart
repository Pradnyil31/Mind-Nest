import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ambient_sound.dart';
import '../features/calm/application/ambient_sound_controller.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final AmbientSound sound;
  final Color primaryColor;

  const AudioPlayerScreen({
    super.key,
    required this.sound,
    this.primaryColor = const Color(0xFF4DB6AC),
  });

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  double _currentPosition = 0.0;
  double _totalDuration = 300.0; // Default 5 minutes, can be updated
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startProgressTracking() {
    // Simulate progress tracking for ambient sounds (which are typically loops)
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentPosition += 1.0;
          // Reset progress when reaching the end (for looping sounds)
          if (_currentPosition >= _totalDuration) {
            _currentPosition = 0.0;
          }
        });
      }
    });
  }

  void _seekToPosition(double position) {
    setState(() {
      _currentPosition = position;
    });
    // In a real implementation, you would seek the audio player here
    // For ambient sounds that loop, this is less critical
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soundState = ref.watch(ambientSoundControllerProvider);
    final soundController = ref.read(ambientSoundControllerProvider.notifier);
    final isPlaying = soundState.activeSounds.contains(widget.sound.id);

    // Control animations and progress tracking based on playback state
    if (isPlaying) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
      // Start progress tracking if not already running
      if (_progressTimer == null || !_progressTimer!.isActive) {
        _startProgressTracking();
      }
    } else {
      _rotationController.stop();
      _pulseController.stop();
      // Stop progress tracking when not playing
      _progressTimer?.cancel();
    }

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildAlbumArt(isPlaying),
                      const SizedBox(height: 40),
                      _buildSoundInfo(),
                      const SizedBox(height: 30),
                      _buildProgressBar(),
                      const SizedBox(height: 40),
                      _buildPlaybackControls(soundController, isPlaying),
                      const SizedBox(height: 30),
                      _buildVolumeControl(soundState, soundController),
                      const SizedBox(height: 30),
                      _buildAdditionalControls(soundController),
                      const SizedBox(height: 20),
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

  Color _getBackgroundColor() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        widget.primaryColor.withValues(alpha: 0.1),
        Colors.white,
        widget.primaryColor.withValues(alpha: 0.05),
      ],
    ).colors.first;
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: widget.primaryColor,
                size: 24,
              ),
            ),
          ),
          Text(
            'Now Playing',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          GestureDetector(
            onTap: () => _showMoreOptions(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.more_horiz,
                color: widget.primaryColor,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(bool isPlaying) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isPlaying ? _pulseAnimation.value : 1.0,
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: isPlaying ? _rotationAnimation.value * 2 * 3.14159 : 0,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.primaryColor.withValues(alpha: 0.8),
                          widget.primaryColor.withValues(alpha: 0.4),
                          widget.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.sound.emoji,
                            style: const TextStyle(fontSize: 80),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSoundInfo() {
    return Column(
      children: [
        Text(
          widget.sound.name,
          style: GoogleFonts.lato(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.sound.description,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            _getCategoryName(widget.sound.category),
            style: GoogleFonts.lato(
              fontSize: 14,
              color: widget.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getCategoryName(SoundCategory category) {
    switch (category) {
      case SoundCategory.nature:
        return 'Nature Sounds';
      case SoundCategory.urban:
        return 'Urban Ambience';
      case SoundCategory.noise:
        return 'White Noise';
      case SoundCategory.traditional:
        return 'Traditional';
    }
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.primaryColor,
            inactiveTrackColor: widget.primaryColor.withValues(alpha: 0.2),
            thumbColor: widget.primaryColor,
            overlayColor: widget.primaryColor.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: _currentPosition,
            max: _totalDuration,
            onChanged: _seekToPosition,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPlaybackControls(
    AmbientSoundController controller,
    bool isPlaying,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.shuffle,
          onTap: () => _showShuffleOptions(context),
          isSecondary: true,
        ),
        _buildControlButton(
          icon: Icons.skip_previous,
          onTap: () => _previousSound(),
          isSecondary: true,
        ),
        GestureDetector(
          onTap: () => controller.toggleSound(widget.sound.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        _buildControlButton(
          icon: Icons.skip_next,
          onTap: () => _nextSound(),
          isSecondary: true,
        ),
        _buildControlButton(
          icon: Icons.repeat,
          onTap: () => _showRepeatOptions(context),
          isSecondary: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSecondary
              ? Colors.white.withValues(alpha: 0.9)
              : widget.primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isSecondary ? widget.primaryColor : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildVolumeControl(
    AmbientSoundState soundState,
    AmbientSoundController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.volume_down, color: widget.primaryColor, size: 24),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.primaryColor,
                    inactiveTrackColor: widget.primaryColor.withValues(
                      alpha: 0.2,
                    ),
                    thumbColor: widget.primaryColor,
                    overlayColor: widget.primaryColor.withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: soundState.masterVolume,
                    onChanged: controller.setMasterVolume,
                  ),
                ),
              ),
              Icon(Icons.volume_up, color: widget.primaryColor, size: 24),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(soundState.masterVolume * 100).round()}%',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalControls(AmbientSoundController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureButton(
                icon: Icons.timer,
                label: 'Timer',
                onTap: () => _showTimerOptions(context, controller),
              ),
              _buildFeatureButton(
                icon: Icons.favorite_border,
                label: 'Favorite',
                onTap: () => _toggleFavorite(),
              ),
              _buildFeatureButton(
                icon: Icons.playlist_add,
                label: 'Playlist',
                onTap: () => _showPlaylistOptions(context),
              ),
              _buildFeatureButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () => _shareSound(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: widget.primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: widget.primaryColor),
              title: Text('Sound Info', style: GoogleFonts.lato()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.equalizer, color: widget.primaryColor),
              title: Text('Equalizer', style: GoogleFonts.lato()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: widget.primaryColor),
              title: Text('Audio Settings', style: GoogleFonts.lato()),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showTimerOptions(
    BuildContext context,
    AmbientSoundController controller,
  ) {
    final timerOptions = [15, 30, 45, 60, 90, 120];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Sleep Timer',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...timerOptions.map(
              (minutes) => ListTile(
                title: Text(
                  minutes >= 60
                      ? '${minutes ~/ 60} hour${minutes > 60 ? 's' : ''}'
                      : '$minutes minutes',
                  style: GoogleFonts.lato(),
                ),
                onTap: () {
                  controller.setTimer(minutes);
                  Navigator.pop(context);
                  _showTimerConfirmation(minutes);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showTimerConfirmation(int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Timer set for $minutes minutes',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showShuffleOptions(BuildContext context) {
    // Placeholder for shuffle functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Shuffle mode activated',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRepeatOptions(BuildContext context) {
    // Placeholder for repeat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Repeat mode activated',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context) {
    // Placeholder for playlist functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added to playlist',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _previousSound() {
    // Placeholder for previous sound functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Previous sound',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _nextSound() {
    // Placeholder for next sound functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Next sound',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleFavorite() {
    // Placeholder for favorite functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added to favorites',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareSound() {
    // Placeholder for share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sharing ${widget.sound.name}',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: widget.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
