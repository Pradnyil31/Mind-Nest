import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ambient_sound.dart';
import '../../../services/audio_playback_service.dart';
import '../../../screens/audio_player_screen.dart';

// Enhanced state for audio playback with player screen management
class EnhancedAudioState {
  final Set<String> activeSounds;
  final double masterVolume;
  final Map<String, double> individualVolumes;
  final int? timerMinutes;
  final bool isPlaying;
  final AmbientSound? currentlyPlayingSound;
  final bool isPlayerScreenOpen;

  const EnhancedAudioState({
    this.activeSounds = const {},
    this.masterVolume = 0.7,
    this.individualVolumes = const {},
    this.timerMinutes,
    this.isPlaying = false,
    this.currentlyPlayingSound,
    this.isPlayerScreenOpen = false,
  });

  EnhancedAudioState copyWith({
    Set<String>? activeSounds,
    double? masterVolume,
    Map<String, double>? individualVolumes,
    int? timerMinutes,
    bool? isPlaying,
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
      currentlyPlayingSound: clearCurrentlyPlayingSound
          ? null
          : (currentlyPlayingSound ?? this.currentlyPlayingSound),
      isPlayerScreenOpen: isPlayerScreenOpen ?? this.isPlayerScreenOpen,
    );
  }
}

// Enhanced controller for managing audio playback with full-screen player
class EnhancedAudioController extends StateNotifier<EnhancedAudioState> {
  final AudioPlaybackService _audioService = AudioPlaybackService();

  EnhancedAudioController() : super(const EnhancedAudioState()) {
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    try {
      await _audioService.initialize();
    } catch (e) {
      print('Failed to initialize audio service: $e');
    }
  }

  // Play sound and optionally open full-screen player
  Future<void> playSound(AmbientSound sound, {bool openPlayer = true}) async {
    final individualVolume = state.individualVolumes[sound.id] ?? 1.0;

    try {
      // ALWAYS stop other sounds first - only one sound at a time
      if (state.activeSounds.isNotEmpty) {
        await stopAllSounds();
      }

      // Start the new sound
      final newActiveSounds = <String>{sound.id};
      await _audioService.playSound(sound.id, individualVolume);

      // Update state
      state = state.copyWith(
        activeSounds: newActiveSounds,
        isPlaying: true,
        currentlyPlayingSound: sound,
      );
    } catch (e) {
      print('Audio operation failed for ${sound.id}: $e');
    }
  }

  // Toggle sound playback
  Future<void> toggleSound(AmbientSound sound, {bool openPlayer = true}) async {
    final individualVolume = state.individualVolumes[sound.id] ?? 1.0;

    try {
      if (state.activeSounds.contains(sound.id)) {
        // If this sound is currently playing, stop it
        await _audioService.stopSound(sound.id);

        state = state.copyWith(
          activeSounds: const <String>{},
          isPlaying: false,
          clearCurrentlyPlayingSound: true,
        );
      } else {
        // If this sound is not playing, stop all others and play this one
        if (state.activeSounds.isNotEmpty) {
          await stopAllSounds();
        }

        // Start the new sound
        final newActiveSounds = <String>{sound.id};
        await _audioService.playSound(sound.id, individualVolume);

        state = state.copyWith(
          activeSounds: newActiveSounds,
          isPlaying: true,
          currentlyPlayingSound: sound,
        );
      }
    } catch (e) {
      print('Audio operation failed for ${sound.id}: $e');
    }
  }

  // Open full-screen audio player
  void openAudioPlayer(BuildContext context, AmbientSound sound) {
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
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
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
    } catch (e) {
      print('Failed to set master volume: $e');
    }
  }

  Future<void> setSoundVolume(String soundId, double volume) async {
    final newVolumes = Map<String, double>.from(state.individualVolumes);
    newVolumes[soundId] = volume;

    state = state.copyWith(individualVolumes: newVolumes);
    try {
      await _audioService.setVolume(soundId, volume);
    } catch (e) {
      print('Failed to set volume for $soundId: $e');
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
    } catch (e) {
      print('Failed to set timer: $e');
    }
  }

  // Stop all sounds
  Future<void> stopAllSounds() async {
    state = state.copyWith(
      activeSounds: const {},
      isPlaying: false,
      clearCurrentlyPlayingSound: true,
    );
    try {
      await _audioService.stopAllSounds();
    } catch (e) {
      print('Failed to stop all sounds: $e');
    }
  }

  // Get recommended sounds for a specific motive
  List<AmbientSound> getRecommendedSounds(String motive) {
    final allSounds = AmbientSound.defaults;

    switch (motive.toLowerCase()) {
      case 'sleep':
        return allSounds
            .where(
              (s) =>
                  s.category == SoundCategory.nature ||
                  s.category == SoundCategory.noise ||
                  s.id == 'piano' ||
                  s.id == 'fireplace',
            )
            .toList();

      case 'focus':
        return allSounds
            .where(
              (s) =>
                  s.category == SoundCategory.noise ||
                  s.id == 'library' ||
                  s.id == 'cafe' ||
                  s.id == 'white-noise' ||
                  s.id == 'brown-noise',
            )
            .toList();

      case 'anxiety':
      case 'stress':
        return allSounds
            .where(
              (s) =>
                  s.id == 'rain' ||
                  s.id == 'ocean' ||
                  s.id == 'fireplace' ||
                  s.id == 'brown-noise' ||
                  s.id == 'singing-bowls',
            )
            .toList();

      case 'habit building':
        return allSounds
            .where(
              (s) =>
                  s.category == SoundCategory.traditional ||
                  s.id == 'library' ||
                  s.id == 'cafe',
            )
            .toList();

      default:
        return allSounds.take(8).toList();
    }
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
