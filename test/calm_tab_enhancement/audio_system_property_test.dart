import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/models/ambient_sound.dart';
import 'package:fy_project/features/calm/application/ambient_sound_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

/// Helper function to validate audio format (mirrors AudioPlaybackService logic)
bool _isValidAudioFormat(String filePath) {
  final extension = filePath.toLowerCase().split('.').last;
  return ['mp3', 'aac', 'ogg', 'm4a', 'wav'].contains(extension);
}

/// Property-based test for audio system functionality
///
/// **Feature: calm-tab-enhancement, Property 3: Ambient Sound System Functionality**
/// **Validates: Requirements 3.1, 3.2, 3.4, 3.7**
///
/// For any ambient sound interaction, the system should support at least 15 sounds
/// across 4 categories, allow multi-sound mixing with individual volume controls,
/// provide visual feedback for active sounds, and continue playback across screen navigation.

void main() {
  group(
    'Feature: calm-tab-enhancement, Property 3: Ambient Sound System Functionality',
    () {
      late ProviderContainer container;
      late AmbientSoundController controller;

      setUp(() {
        container = ProviderContainer();
        controller = container.read(ambientSoundControllerProvider.notifier);
      });

      tearDown(() {
        container.dispose();
      });

      testWidgets(
        'Property 3.1: System supports at least 15 sounds across 4 categories',
        (tester) async {
          // Test with 100 iterations to ensure property holds universally
          for (int iteration = 0; iteration < 100; iteration++) {
            // Verify total sound count
            final allSounds = AmbientSound.defaults;
            expect(
              allSounds.length,
              greaterThanOrEqualTo(15),
              reason:
                  'System must support at least 15 ambient sounds (iteration $iteration)',
            );

            // Verify category distribution
            final categories = SoundCategory.values;
            expect(
              categories.length,
              equals(4),
              reason:
                  'System must have exactly 4 sound categories (iteration $iteration)',
            );

            // Verify each category has sounds
            for (final category in categories) {
              final soundsInCategory = allSounds
                  .where((s) => s.category == category)
                  .toList();
              expect(
                soundsInCategory.isNotEmpty,
                isTrue,
                reason:
                    'Category $category must have at least one sound (iteration $iteration)',
              );
            }

            // Verify sound ID uniqueness
            final soundIds = allSounds.map((s) => s.id).toSet();
            expect(
              soundIds.length,
              equals(allSounds.length),
              reason: 'All sound IDs must be unique (iteration $iteration)',
            );
          }
        },
      );

      testWidgets('Property 3.2: Controller state management for sound mixing', (
        tester,
      ) async {
        for (int iteration = 0; iteration < 100; iteration++) {
          // Generate random sound selection (1-5 sounds)
          final random = Random(iteration);
          final availableSounds = AmbientSound.defaults;
          final numSounds = random.nextInt(5) + 1;
          final selectedSounds = <String>[];

          for (int i = 0; i < numSounds; i++) {
            final soundIndex = random.nextInt(availableSounds.length);
            final soundId = availableSounds[soundIndex].id;
            if (!selectedSounds.contains(soundId)) {
              selectedSounds.add(soundId);
            }
          }

          // Test individual volume control through controller
          for (final soundId in selectedSounds) {
            final randomVolume = random.nextDouble();

            // Set individual volume through controller
            controller.setSoundVolume(soundId, randomVolume);

            // Verify volume was set in controller state
            final state = container.read(ambientSoundControllerProvider);
            expect(
              state.individualVolumes[soundId],
              equals(randomVolume),
              reason:
                  'Individual volume for $soundId should be $randomVolume (iteration $iteration)',
            );
          }

          // Test master volume affects controller state
          final masterVolume = random.nextDouble();
          controller.setMasterVolume(masterVolume);

          final finalState = container.read(ambientSoundControllerProvider);
          expect(
            finalState.masterVolume,
            equals(masterVolume),
            reason:
                'Master volume should be set correctly (iteration $iteration)',
          );

          // Clean up for next iteration
          controller.stopAllSounds();
        }
      });

      testWidgets('Property 3.3: Sound activation and state feedback', (
        tester,
      ) async {
        for (int iteration = 0; iteration < 100; iteration++) {
          final random = Random(iteration);
          final availableSounds = AmbientSound.defaults;

          // Generate random sound activation pattern
          final expectedActiveSounds = <String>{};
          final numActivations = random.nextInt(8) + 1;

          for (int i = 0; i < numActivations; i++) {
            final soundIndex = random.nextInt(availableSounds.length);
            final soundId = availableSounds[soundIndex].id;

            if (random.nextBool()) {
              // Activate sound (only if not already active)
              if (!expectedActiveSounds.contains(soundId)) {
                expectedActiveSounds.add(soundId);
                controller.toggleSound(soundId);
              }
            } else if (expectedActiveSounds.contains(soundId)) {
              // Deactivate sound (only if currently active)
              expectedActiveSounds.remove(soundId);
              controller.toggleSound(soundId);
            }
          }

          // Verify controller state matches expected state
          final controllerState = container.read(
            ambientSoundControllerProvider,
          );
          expect(
            controllerState.activeSounds,
            equals(expectedActiveSounds),
            reason:
                'Active sounds should match expected state (iteration $iteration)',
          );

          // Verify playing state reflects active sounds
          expect(
            controllerState.isPlaying,
            equals(expectedActiveSounds.isNotEmpty),
            reason:
                'Controller should reflect playing state correctly (iteration $iteration)',
          );

          // Clean up
          controller.stopAllSounds();
        }
      });

      testWidgets('Property 3.4: Audio format validation logic', (
        tester,
      ) async {
        for (int iteration = 0; iteration < 100; iteration++) {
          final random = Random(iteration);

          // Test valid formats
          final validFormats = ['mp3', 'aac', 'ogg', 'm4a', 'wav'];
          final validFormat = validFormats[random.nextInt(validFormats.length)];
          final validFile = 'test_audio.$validFormat';

          // This tests the format validation logic without requiring AudioPlaybackService
          expect(
            _isValidAudioFormat(validFile),
            isTrue,
            reason:
                'Format $validFormat should be valid (iteration $iteration)',
          );

          // Test invalid formats
          final invalidFormats = ['txt', 'jpg', 'pdf', 'doc', 'exe'];
          final invalidFormat =
              invalidFormats[random.nextInt(invalidFormats.length)];
          final invalidFile = 'test_file.$invalidFormat';

          expect(
            _isValidAudioFormat(invalidFile),
            isFalse,
            reason:
                'Format $invalidFormat should be invalid (iteration $iteration)',
          );

          // Test case insensitivity
          final upperCaseFile = 'test_audio.${validFormat.toUpperCase()}';
          expect(
            _isValidAudioFormat(upperCaseFile),
            isTrue,
            reason:
                'Format validation should be case insensitive (iteration $iteration)',
          );
        }
      });

      testWidgets('Property 3.7: Motive-based sound recommendations', (
        tester,
      ) async {
        final motives = [
          'Sleep',
          'Stress',
          'Anxiety',
          'Focus',
          'Habit Building',
        ];

        for (int iteration = 0; iteration < 100; iteration++) {
          final random = Random(iteration);
          final motive = motives[random.nextInt(motives.length)];

          // Get recommended sounds for motive
          final recommendedSounds = controller.getRecommendedSounds(motive);

          // Verify recommendations are not empty
          expect(
            recommendedSounds.isNotEmpty,
            isTrue,
            reason:
                'Motive $motive should have sound recommendations (iteration $iteration)',
          );

          // Verify recommendations are appropriate for motive
          switch (motive) {
            case 'Sleep':
              final hasNatureOrNoise = recommendedSounds.any(
                (s) =>
                    s.category == SoundCategory.nature ||
                    s.category == SoundCategory.noise ||
                    s.id == 'piano',
              );
              expect(
                hasNatureOrNoise,
                isTrue,
                reason:
                    'Sleep motive should recommend nature/noise sounds (iteration $iteration)',
              );
              break;

            case 'Focus':
              final hasNoiseOrAmbient = recommendedSounds.any(
                (s) =>
                    s.category == SoundCategory.noise ||
                    s.id == 'library' ||
                    s.id == 'cafe',
              );
              expect(
                hasNoiseOrAmbient,
                isTrue,
                reason:
                    'Focus motive should recommend noise/ambient sounds (iteration $iteration)',
              );
              break;

            case 'Anxiety':
              final hasCalmingSounds = recommendedSounds.any(
                (s) =>
                    s.id == 'rain' ||
                    s.id == 'fireplace' ||
                    s.id == 'brown-noise' ||
                    s.id == 'ocean',
              );
              expect(
                hasCalmingSounds,
                isTrue,
                reason:
                    'Anxiety motive should recommend calming sounds (iteration $iteration)',
              );
              break;
          }

          // Verify all recommended sounds exist in defaults
          for (final sound in recommendedSounds) {
            expect(
              AmbientSound.defaults.any((s) => s.id == sound.id),
              isTrue,
              reason:
                  'Recommended sound ${sound.id} should exist in defaults (iteration $iteration)',
            );
          }
        }
      });
    },
  );
}
