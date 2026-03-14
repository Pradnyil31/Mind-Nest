import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/ambient_sound.dart';
import '../../../services/audio_playback_service.dart';

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
  final AudioPlaybackService _audioService = AudioPlaybackService();

  AmbientSoundController() : super(const AmbientSoundState()) {
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    try {
      await _audioService.initialize();
      // Note: We don't listen to the audio service stream here to avoid race conditions
      // The controller manages its own state and calls the audio service directly
    } catch (e) {
      // Handle initialization error gracefully
      print('Failed to initialize audio service: $e');
    }
  }

  Future<void> toggleSound(String soundId) async {
    final newActiveSounds = Set<String>.from(state.activeSounds);
    final individualVolume = state.individualVolumes[soundId] ?? 1.0;

    try {
      if (newActiveSounds.contains(soundId)) {
        newActiveSounds.remove(soundId);
        await _audioService.stopSound(soundId);
      } else {
        newActiveSounds.add(soundId);
        await _audioService.playSound(soundId, individualVolume);
      }

      // Update state after successful audio operation
      state = state.copyWith(
        activeSounds: newActiveSounds,
        isPlaying: newActiveSounds.isNotEmpty,
      );
    } catch (e) {
      // Handle audio errors gracefully - revert state if needed
      print('Audio operation failed for $soundId: $e');
      // Don't update state if audio operation failed
    }
  }

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

  Future<void> stopAllSounds() async {
    state = state.copyWith(activeSounds: const {}, isPlaying: false);
    try {
      await _audioService.stopAllSounds();
    } catch (e) {
      print('Failed to stop all sounds: $e');
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
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
        // Return a balanced mix for unknown motives
        return allSounds.take(8).toList();
    }
  }
}

// Provider for the ambient sound controller
final ambientSoundControllerProvider =
    StateNotifierProvider<AmbientSoundController, AmbientSoundState>(
      (ref) => AmbientSoundController(),
    );
