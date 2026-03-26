import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fy_project/services/audio_playback_service.dart';
import 'package:fy_project/features/calm/application/ambient_sound_controller.dart';

/// Task 4: Core Services Integration Validation
///
/// This test validates the core integration points that can be tested
/// without Firebase dependencies, focusing on the logic and data flow
/// between services.

void main() {
  group('Task 4: Core Services Integration Validation', () {
    late ProviderContainer container;
    late AmbientSoundController ambientController;
    late AudioPlaybackService audioService;

    setUp(() {
      container = ProviderContainer();
      ambientController = container.read(
        ambientSoundControllerProvider.notifier,
      );
      audioService = AudioPlaybackService();
    });

    tearDown(() {
      container.dispose();
      audioService.dispose();
    });

    test('audio service initializes successfully', () async {
      // Test audio service initialization
      await audioService.initialize();

      // Verify audio service is ready
      expect(audioService.masterVolume, equals(0.7));
      expect(audioService.getActiveSoundIds(), isEmpty);
    });

    test('audio format validation works correctly', () {
      // Test valid formats
      expect(audioService.isValidAudioFormat('test.mp3'), isTrue);
      expect(audioService.isValidAudioFormat('test.aac'), isTrue);
      expect(audioService.isValidAudioFormat('test.ogg'), isTrue);
      expect(audioService.isValidAudioFormat('test.m4a'), isTrue);
      expect(audioService.isValidAudioFormat('test.wav'), isTrue);

      // Test case insensitivity
      expect(audioService.isValidAudioFormat('test.MP3'), isTrue);

      // Test invalid formats
      expect(audioService.isValidAudioFormat('test.txt'), isFalse);
      expect(audioService.isValidAudioFormat('test.jpg'), isFalse);
    });

    test('controller state management works correctly', () async {
      // Test controller initial state
      final initialState = container.read(ambientSoundControllerProvider);
      expect(initialState.activeSounds, isEmpty);
      expect(initialState.masterVolume, equals(0.7));
      expect(initialState.isPlaying, isFalse);

      // Test volume control through controller
      const testVolume = 0.5;
      const testSoundId = 'rain';

      await ambientController.setSoundVolume(testSoundId, testVolume);

      final stateAfterVolume = container.read(ambientSoundControllerProvider);
      expect(
        stateAfterVolume.individualVolumes[testSoundId],
        equals(testVolume),
      );
    });
  });
}
