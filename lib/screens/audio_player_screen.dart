import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/calm/application/enhanced_audio_controller.dart';
import '../models/ambient_sound.dart';

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
    with SingleTickerProviderStateMixin {
  late String _selectedSoundId;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedSoundId = widget.sound.id;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handlePlayPause(
    EnhancedAudioController controller,
    bool isPlaying,
    AmbientSound sound,
  ) async {
    if (isPlaying) {
      await controller.pauseCurrentSound();
    } else {
      await controller.playSound(sound, openPlayer: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final soundState = ref.watch(enhancedAudioControllerProvider);
    final soundController = ref.read(enhancedAudioControllerProvider.notifier);

    final selectedSound = AmbientSound.defaults.firstWhere(
      (s) => s.id == _selectedSoundId,
      orElse: () => widget.sound,
    );

    final isPlaying = soundState.activeSounds.contains(_selectedSoundId);

    // Drive the pulse animation
    if (isPlaying) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // ── Hero (intrinsic height, no overflow) ──────────────────
          _buildHero(selectedSound, isPlaying, soundController, soundState),
          // ── Body fills the rest exactly ───────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVolumeCard(soundState, soundController),
                        const SizedBox(height: 20),
                        Text(
                          'Available Sounds',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  // ListView fills remaining height — no gap at bottom
                  Expanded(
                    child: _buildSoundList(
                      soundState: soundState,
                      soundController: soundController,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────
  // Uses IntrinsicHeight so it can't overflow regardless of status bar
  Widget _buildHero(
    AmbientSound sound,
    bool isPlaying,
    EnhancedAudioController controller,
    EnhancedAudioState soundState,
  ) {
    // Determine button state - only Play or Pause, no Resume label
    final String buttonLabel = isPlaying ? 'Pause' : 'Play';
    final IconData buttonIcon = isPlaying
        ? Icons.pause_rounded
        : Icons.play_arrow_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.primaryColor.withValues(alpha: 0.85),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 44),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative circles (purely visual, clipped by parent)
              Positioned(
                top: -20,
                right: -30,
                child: Opacity(
                  opacity: 0.08,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                left: -40,
                child: Opacity(
                  opacity: 0.06,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ),
              // Content column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back button row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            'Sound Player',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pulsing emoji
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: isPlaying ? _pulseAnimation.value : 1.0,
                      child: child,
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Hero(
                        tag: 'sound_emoji_${sound.id}',
                        flightShuttleBuilder: (
                          flightContext,
                          animation,
                          flightDirection,
                          fromHeroContext,
                          toHeroContext,
                        ) {
                          return DefaultTextStyle(
                            style: DefaultTextStyle.of(toHeroContext).style,
                            child: toHeroContext.widget,
                          );
                        },
                        child: Text(
                          sound.emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sound.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sound.description,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Play / Pause pill button
                  GestureDetector(
                    onTap: () => _handlePlayPause(controller, isPlaying, sound),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            buttonIcon,
                            color: isPlaying
                                ? Colors.white
                                : widget.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            buttonLabel,
                            style: GoogleFonts.inter(
                              color: isPlaying
                                  ? Colors.white
                                  : widget.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Volume Card ───────────────────────────────────────────────────────
  Widget _buildVolumeCard(
    EnhancedAudioState soundState,
    EnhancedAudioController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.volume_down_rounded, color: widget.primaryColor, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: widget.primaryColor,
                inactiveTrackColor: widget.primaryColor.withValues(alpha: 0.15),
                thumbColor: widget.primaryColor,
                overlayColor: widget.primaryColor.withValues(alpha: 0.12),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: soundState.masterVolume,
                onChanged: controller.setMasterVolume,
              ),
            ),
          ),
          Icon(Icons.volume_up_rounded, color: widget.primaryColor, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '${(soundState.masterVolume * 100).round()}%',
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sound List ────────────────────────────────────────────────────────
  Widget _buildSoundList({
    required EnhancedAudioState soundState,
    required EnhancedAudioController soundController,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: AmbientSound.defaults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sound = AmbientSound.defaults[index];
        final isSelected = sound.id == _selectedSoundId;
        final isActive = soundState.activeSounds.contains(sound.id);

        return GestureDetector(
          onTap: () async {
            setState(() {
              _selectedSoundId = sound.id;
            });
            if (!isActive) {
              await soundController.playSound(sound, openPlayer: false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.primaryColor.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? widget.primaryColor.withValues(alpha: 0.6)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.primaryColor.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Hero(
                    tag: isSelected ? 'sound_emoji_${sound.id}_list' : 'sound_emoji_${sound.id}',
                    child: Text(
                      sound.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sound.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sound.description,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.graphic_eq_rounded,
                      color: widget.primaryColor,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
