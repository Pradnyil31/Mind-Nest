import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/models/ambient_sound.dart';
import 'package:fy_project/features/calm/application/ambient_sound_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

void main() {
  testWidgets('Debug iteration 9 behavior', (tester) async {
    final container = ProviderContainer();
    final controller = container.read(ambientSoundControllerProvider.notifier);

    // Reproduce the exact scenario from iteration 9
    final random = Random(9); // Same seed as failing iteration
    final availableSounds = AmbientSound.defaults;

    // Generate random sound activation pattern (same as test)
    final expectedActiveSounds = <String>{};
    final numActivations = random.nextInt(8) + 1;

    print('numActivations: $numActivations');

    for (int i = 0; i < numActivations; i++) {
      final soundIndex = random.nextInt(availableSounds.length);
      final soundId = availableSounds[soundIndex].id;
      final shouldActivate = random.nextBool();

      print(
        'Step $i: soundId=$soundId, shouldActivate=$shouldActivate, currentExpected=$expectedActiveSounds',
      );

      if (shouldActivate) {
        // Activate sound
        expectedActiveSounds.add(soundId);
        controller.toggleSound(soundId);
        print('  -> Added $soundId to expected, toggled sound');
      } else if (expectedActiveSounds.contains(soundId)) {
        // Deactivate sound
        expectedActiveSounds.remove(soundId);
        controller.toggleSound(soundId);
        print('  -> Removed $soundId from expected, toggled sound');
      } else {
        print('  -> No action (sound not in expected set)');
      }

      final currentState = container.read(ambientSoundControllerProvider);
      print('  -> Current controller state: ${currentState.activeSounds}');
    }

    // Final verification
    final controllerState = container.read(ambientSoundControllerProvider);
    print('Final expected: $expectedActiveSounds');
    print('Final controller: ${controllerState.activeSounds}');

    container.dispose();
  });
}
