import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/calm/application/enhanced_audio_controller.dart';

class MiniAudioPlayer extends ConsumerStatefulWidget {
  final Color primaryColor;

  const MiniAudioPlayer({
    super.key,
    this.primaryColor = const Color(0xFF4DB6AC),
  });

  @override
  ConsumerState<MiniAudioPlayer> createState() => _MiniAudioPlayerState();
}

class _MiniAudioPlayerState extends ConsumerState<MiniAudioPlayer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(enhancedAudioControllerProvider);
    final audioController = ref.read(enhancedAudioControllerProvider.notifier);

    // Mini bar is visible whenever there's a sound loaded (playing OR paused)
    final bool hasSound = audioState.currentlyPlayingSound != null;
    final bool showBar = hasSound && !audioState.isPlayerScreenOpen;

    if (showBar) {
      if (!_slideController.isCompleted) _slideController.forward();
      if (audioState.isPlaying) {
        if (!_pulseController.isAnimating)
          _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    } else {
      if (_slideController.isCompleted) _slideController.reverse();
      _pulseController.stop();
    }

    if (!hasSound) return const SizedBox.shrink();

    final sound = audioState.currentlyPlayingSound!;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => audioController.openAudioPlayer(context, sound),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Sound emoji with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: audioState.isPlaying
                            ? _pulseAnimation.value
                            : 1.0,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
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
                                  style:
                                      DefaultTextStyle.of(toHeroContext).style,
                                  child: toHeroContext.widget,
                                );
                              },
                              child: Text(
                                sound.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),

                  // Sound info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sound.name,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D2D2D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              audioState.isPlaying
                                  ? Icons.volume_up
                                  : Icons.pause_circle_outline,
                              size: 14,
                              color: widget.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              audioState.isPlaying ? 'Now Playing' : 'Paused',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Play / Pause button — stops tap from bubbling to InkWell
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (audioState.isPlaying) {
                        audioController.pauseCurrentSound();
                      } else {
                        audioController.resumeCurrentSound();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Close button — fully stops and hides bar
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => audioController.stopAllSounds(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
