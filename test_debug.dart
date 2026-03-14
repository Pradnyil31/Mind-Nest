import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/features/calm/application/ambient_sound_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('Debug toggleSound behavior', () async {
    final container = ProviderContainer();
    final controller = container.read(ambientSoundControllerProvider.notifier);

    // Wait for initialization
    await Future.delayed(Duration(milliseconds: 100));

    print(
      'Initial state: ${container.read(ambientSoundControllerProvider).activeSounds}',
    );

    // Toggle piano on
    controller.toggleSound('piano');
    print(
      'After toggle piano on: ${container.read(ambientSoundControllerProvider).activeSounds}',
    );

    // Toggle singing-bowls on
    controller.toggleSound('singing-bowls');
    print(
      'After toggle singing-bowls on: ${container.read(ambientSoundControllerProvider).activeSounds}',
    );

    // Expected: {'piano', 'singing-bowls'}
    final state = container.read(ambientSoundControllerProvider);
    print('Final state: ${state.activeSounds}');
    print('Expected: {piano, singing-bowls}');

    container.dispose();
  });
}
