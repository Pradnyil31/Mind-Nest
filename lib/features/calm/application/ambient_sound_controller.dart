import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ambient_sound.dart';
import '../../../services/audio_playback_service.dart';
import '../../../core/logger.dart';

// State for ambient sound playback
class AmbientSoundState {
  final Set<String> activeSounds;
  final double masterVolume;
  final Map<String, double> individualVolumes;
  final int? timerMinutes;
  final bool isPlaying;

  const AmbientSoundState({
    this.activeSounds = const {},
    this.masterVolume = 0.7,
    this.individualVolumes = const {},
    this.timerMinutes,
    this.isPlaying = false,
  });

  AmbientSoundState copyWith({
    Set<String>? activeSounds,
    double? masterVolume,
    Map<String, double>? individualVolumes,
    int? timerMinutes,
    bool? isPlaying,
  }) {
    return AmbientSoundState(
      activeSounds: activeSounds ?? this.activeSounds,
      masterVolume: masterVolume ?? this.masterVolume,
      individualVolumes: individualVolumes ?? this.individualVolumes,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

// Controller for managing ambient sound playback
class AmbientSoundController extends StateNotifier<AmbientSoundState> {
  final AudioPlaybackService _audioService;

  AmbientSoundController({AudioPlaybackService? audioService})
    : _audioService = audioService ?? AudioPlaybackService(),
      super(const AmbientSoundState()) {
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    try {
      await _audioService.initialize();
      // Note: We don't listen to the audio service stream here to avoid race conditions
      // The controller manages its own state and calls the audio service directly
    } catch (e, stackTrace) {
      // Handle initialization error gracefully
      appLogger.e('Failed to initialize audio service', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> toggleSound(String soundId) async {
    final individualVolume = state.individualVolumes[soundId] ?? 1.0;

    try {
      if (state.activeSounds.contains(soundId)) {
        // If this sound is currently playing, stop it
        await _audioService.stopSound(soundId);
        state = state.copyWith(
          activeSounds: const <String>{},
          isPlaying: false,
        );
      } else {
        // If this sound is not playing, stop all others and play this one
        if (state.activeSounds.isNotEmpty) {
          await stopAllSounds();
        }

        // Start the new sound
        final newActiveSounds = <String>{soundId};
        await _audioService.playSound(soundId, individualVolume);

        state = state.copyWith(activeSounds: newActiveSounds, isPlaying: true);
      }
    } catch (e, stackTrace) {
      // Handle audio errors gracefully - revert state if needed
      appLogger.e(
        'Audio operation failed for $soundId',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't update state if audio operation failed
    }
  }

  Future<void> playSound(String soundId) async {
    final individualVolume = state.individualVolumes[soundId] ?? 1.0;

    try {
      // ALWAYS stop other sounds first - only one sound at a time
      if (state.activeSounds.isNotEmpty) {
        await stopAllSounds();
      }

      // Start the new sound
      final newActiveSounds = <String>{soundId};
      await _audioService.playSound(soundId, individualVolume);

      // Update state
      state = state.copyWith(activeSounds: newActiveSounds, isPlaying: true);
    } catch (e, stackTrace) {
      appLogger.e(
        'Audio operation failed for $soundId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setMasterVolume(double volume) async {
    state = state.copyWith(masterVolume: volume);
    try {
      await _audioService.setMasterVolume(volume);
    } catch (e, stackTrace) {
      appLogger.e('Failed to set master volume', error: e, stackTrace: stackTrace);
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

  Future<void> stopAllSounds() async {
    state = state.copyWith(activeSounds: const {}, isPlaying: false);
    try {
      await _audioService.stopAllSounds();
    } catch (e, stackTrace) {
      appLogger.e('Failed to stop all sounds', error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  // Get recommended sounds for a specific motive
  List<AmbientSound> getRecommendedSounds(String motive) {
    return AmbientSound.defaults;
  }
}

// Provider for the ambient sound controller
final ambientSoundControllerProvider =
    StateNotifierProvider<AmbientSoundController, AmbientSoundState>(
      (ref) => AmbientSoundController(),
    );
