import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/ambient_sound.dart';
import '../../features/calm/application/ambient_sound_controller.dart';

class InteractiveSoundscapeWidget extends ConsumerStatefulWidget {
  final String? userMotive;
  final Color primaryColor;

  const InteractiveSoundscapeWidget({
    super.key,
    this.userMotive,
    this.primaryColor = const Color(0xFF4DB6AC),
  });

  @override
  ConsumerState<InteractiveSoundscapeWidget> createState() =>
      _InteractiveSoundscapeWidgetState();
}

class _InteractiveSoundscapeWidgetState
    extends ConsumerState<InteractiveSoundscapeWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _timerMinutes = 30;
  final List<int> _timerOptions = [15, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soundState = ref.watch(ambientSoundControllerProvider);
    final soundController = ref.read(ambientSoundControllerProvider.notifier);
    final recommendedSounds = soundController.getRecommendedSounds(
      widget.userMotive ?? 'default',
    );

    // Start pulse animation if sounds are playing
    if (soundState.isPlaying && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!soundState.isPlaying && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: soundState.isPlaying ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        soundState.isPlaying
                            ? Icons.volume_up
                            : Icons.music_note,
                        color: widget.primaryColor,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ambient Soundscapes',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    Text(
                      soundState.isPlaying
                          ? '${soundState.activeSounds.length} sound${soundState.activeSounds.length != 1 ? 's' : ''} playing'
                          : 'Tap sounds to create your mix',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (soundState.isPlaying)
                IconButton(
                  onPressed: soundController.stopAllSounds,
                  icon: Icon(Icons.stop_circle, color: Colors.red.shade400),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Sound Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: recommendedSounds.length,
            itemBuilder: (context, index) {
              final sound = recommendedSounds[index];
              final isActive = soundState.activeSounds.contains(sound.id);

              return _buildSoundCard(sound, isActive, soundController);
            },
          ),

          if (soundState.activeSounds.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildAudioControls(soundState, soundController),
          ],
        ],
      ),
    );
  }

  Widget _buildSoundCard(
    AmbientSound sound,
    bool isActive,
    AmbientSoundController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.toggleSound(sound.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? widget.primaryColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? widget.primaryColor : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: isActive ? 28 : 24),
              child: Text(sound.emoji),
            ),
            const SizedBox(height: 8),
            Text(
              sound.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControls(
    AmbientSoundState soundState,
    AmbientSoundController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active sounds indicator
        if (soundState.activeSounds.isNotEmpty) ...[
          Text(
            'Now Playing',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: soundState.activeSounds.map((soundId) {
              final sound = AmbientSound.defaults.firstWhere(
                (s) => s.id == soundId,
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sound.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      sound.name,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: widget.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Volume Control
        Row(
          children: [
            Icon(Icons.volume_down, color: widget.primaryColor, size: 20),
            Expanded(
              child: Slider(
                value: soundState.masterVolume,
                onChanged: controller.setMasterVolume,
                activeColor: widget.primaryColor,
                inactiveColor: widget.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            Icon(Icons.volume_up, color: widget.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              '${(soundState.masterVolume * 100).round()}%',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Timer Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: widget.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Timer:',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
            DropdownButton<int>(
              value: _timerMinutes,
              underline: const SizedBox(),
              items: _timerOptions.map((minutes) {
                return DropdownMenuItem(
                  value: minutes,
                  child: Text(
                    minutes >= 60
                        ? '${minutes ~/ 60} hour${minutes > 60 ? 's' : ''}'
                        : '$minutes min',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _timerMinutes = value);
                  controller.setTimer(value);
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Audio Status Note (can be removed once audio is fully tested)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Audio playback is now active! Tap sounds to test.',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
