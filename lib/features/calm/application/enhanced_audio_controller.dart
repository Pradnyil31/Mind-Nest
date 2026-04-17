import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ambient_sound.dart';
import '../../../services/audio_playback_service.dart';
import '../../../screens/audio_player_screen.dart';
import '../../../core/logger.dart';

// Enhanced state for audio playback with player screen management
class EnhancedAudioState {
  final Set<String> activeSounds;
  final double masterVolume;
  final Map<String, double> individualVolumes;
  final int? timerMinutes;
  final bool isPlaying;
  final bool isPaused;
  final AmbientSound? currentlyPlayingSound;
  final bool isPlayerScreenOpen;

  const EnhancedAudioState({
    this.activeSounds = const {},
    this.masterVolume = 0.7,
    this.individualVolumes = const {},
    this.timerMinutes,
    this.isPlaying = false,
    this.isPaused = false,
    this.currentlyPlayingSound,
    this.isPlayerScreenOpen = false,
  });

  EnhancedAudioState copyWith({
    Set<String>? activeSounds,
    double? masterVolume,
    Map<String, double>? individualVolumes,
    int? timerMinutes,
    bool? isPlaying,
    bool? isPaused,
    AmbientSound? currentlyPlayingSound,
    bool clearCurrentlyPlayingSound = false,
    bool? isPlayerScreenOpen,
  }) {
    return EnhancedAudioState(
      activeSounds: activeSounds ?? this.activeSounds,
      masterVolume: masterVolume ?? this.masterVolume,
      individualVolumes: individualVolumes ?? this.individualVolumes,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      currentlyPlayingSound: clearCurrentlyPlayingSound
          ? null
          : (currentlyPlayingSound ?? this.currentlyPlayingSound),
      isPlayerScreenOpen: isPlayerScreenOpen ?? this.isPlayerScreenOpen,
    );
  }
}

// Enhanced controller for managing audio playback with full-screen player
class EnhancedAudioController extends StateNotifier<EnhancedAudioState> {
  final AudioPlaybackService _audioService;

  EnhancedAudioController({AudioPlaybackService? audioService})
    : _audioService = audioService ?? AudioPlaybackService(),
      super(const EnhancedAudioState()) {
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    try {
      await _audioService.initialize();
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to initialize audio service',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Play sound and optionally open full-screen player
  Future<void> playSound(AmbientSound sound, {bool openPlayer = true}) async {
    final individualVolume = state.individualVolumes[sound.id] ?? 1.0;

    // Update state IMMEDIATELY for synchronous UI feedback
    final newActiveSounds = <String>{sound.id};
    state = state.copyWith(
      activeSounds: newActiveSounds,
      isPlaying: true,
      isPaused: false,
      currentlyPlayingSound: sound,
    );

    try {
      // Background operation - service calls are still awaited but state is already updated
      await _audioService.stopAllSounds();
      await _audioService.playSound(sound.id, individualVolume);
    } catch (e, stackTrace) {
      appLogger.e(
        'Audio operation failed for ${sound.id}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Toggle sound playback
  Future<void> toggleSound(AmbientSound sound, {bool openPlayer = true}) async {
    final individualVolume = state.individualVolumes[sound.id] ?? 1.0;

    try {
      if (state.activeSounds.contains(sound.id)) {
        // Synchronous state update for immediate feedback
        state = state.copyWith(
          activeSounds: const {},
          isPlaying: false,
          isPaused: true,
        );
        await _audioService.stopAllSounds();
      } else {
        // Synchronous state update
        final newActiveSounds = <String>{sound.id};
        state = state.copyWith(
          activeSounds: newActiveSounds,
          isPlaying: true,
          isPaused: false,
          currentlyPlayingSound: sound,
        );

        await _audioService.stopAllSounds();
        await _audioService.playSound(sound.id, individualVolume);
      }
    } catch (e, stackTrace) {
      appLogger.e(
        'Audio operation failed for ${sound.id}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Open full-screen audio player
  void openAudioPlayer(BuildContext context, AmbientSound sound) {
    // PREVENT DUPLICATE SCREENS: Guard against multiple rapid pushes
    if (state.isPlayerScreenOpen) {
      appLogger.d('Audio player is already open, ignoring duplicate request.');
      return;
    }

    state = state.copyWith(isPlayerScreenOpen: true);

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AudioPlayerScreen(
                  sound: sound,
                  primaryColor: const Color(0xFF4DB6AC),
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const curve = Curves.easeOutQuart;

                  var slideAnimation = Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: curve));

                  var fadeAnimation = Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                    ),
                  );

                  return FadeTransition(
                    opacity: fadeAnimation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        )
        .then((_) {
          // Update state when player is closed
          state = state.copyWith(isPlayerScreenOpen: false);
        });
  }

  // Volume controls
  Future<void> setMasterVolume(double volume) async {
    state = state.copyWith(masterVolume: volume);
    try {
      await _audioService.setMasterVolume(volume);
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to set master volume',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setSoundVolume(String soundId, double volume) async {
    final newVolumes = Map<String, double>.from(state.individualVolumes);
    newVolumes[soundId] = volume;

    state = state.copyWith(individualVolumes: newVolumes);
    try {
      await _audioService.setVolume(soundId, volume);
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to set volume for $soundId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Timer controls
  Future<void> setTimer(int? minutes) async {
    state = state.copyWith(timerMinutes: minutes);

    try {
      if (minutes != null) {
        await _audioService.startTimer(minutes);
      } else {
        _audioService.cancelTimer();
      }
    } catch (e, stackTrace) {
      appLogger.e('Failed to set timer', error: e, stackTrace: stackTrace);
    }
  }

  // Pause — stops audio but keeps currentlyPlayingSound so mini bar stays visible
  Future<void> pauseCurrentSound() async {
    if (state.currentlyPlayingSound == null || state.activeSounds.isEmpty) {
      return;
    }
    state = state.copyWith(
      activeSounds: const {},
      isPlaying: false,
      isPaused: true,
    );
    try {
      await _audioService.stopAllSounds();
    } catch (e, stackTrace) {
      appLogger.e('Failed to pause sound', error: e, stackTrace: stackTrace);
    }
  }

  // Resume the paused sound
  Future<void> resumeCurrentSound() async {
    if (state.currentlyPlayingSound == null) return;
    final sound = state.currentlyPlayingSound!;
    final volume = state.individualVolumes[sound.id] ?? 1.0;
    state = state.copyWith(
      activeSounds: <String>{sound.id},
      isPlaying: true,
      isPaused: false,
    );
    try {
      await _audioService.playSound(sound.id, volume);
    } catch (e, stackTrace) {
      appLogger.e('Failed to resume sound', error: e, stackTrace: stackTrace);
    }
  }

  // Stop completely — clears everything including the mini bar
  Future<void> stopAllSounds() async {
    state = state.copyWith(
      activeSounds: const {},
      isPlaying: false,
      isPaused: false,
      clearCurrentlyPlayingSound: true,
    );
    try {
      await _audioService.stopAllSounds();
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to stop all sounds',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Get recommended sounds for a specific motive
  List<AmbientSound> getRecommendedSounds(String motive) {
    return AmbientSound.defaults;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}

// Provider for the enhanced audio controller
final enhancedAudioControllerProvider =
    StateNotifierProvider<EnhancedAudioController, EnhancedAudioState>(
      (ref) => EnhancedAudioController(),
    );
