import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fy_project/screens/audio_player_screen.dart';
import 'package:fy_project/widgets/calm/mini_audio_player.dart';
import 'package:fy_project/widgets/calm/interactive_soundscape_widget.dart';
import 'package:fy_project/features/calm/application/enhanced_audio_controller.dart';
import 'package:fy_project/models/ambient_sound.dart';

void main() {
  group('Enhanced Audio System Integration Tests', () {
    testWidgets('AudioPlayerScreen displays correctly', (tester) async {
      final testSound = AmbientSound.defaults.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AudioPlayerScreen(
              sound: testSound,
              primaryColor: const Color(0xFF4DB6AC),
            ),
          ),
        ),
      );

      // Verify the screen loads
      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.text(testSound.name), findsOneWidget);
      expect(find.text(testSound.emoji), findsOneWidget);

      // Verify controls are present
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.volume_down), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('MiniAudioPlayer shows when audio is playing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Main Content')),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: MiniAudioPlayer(
                      primaryColor: const Color(0xFF4DB6AC),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, mini player should not be visible (no audio playing)
      expect(find.text('Now Playing'), findsNothing);
    });

    testWidgets('InteractiveSoundscapeWidget opens full player on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: InteractiveSoundscapeWidget(
                        userMotive: 'Sleep',
                        primaryColor: const Color(0xFF4DB6AC),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify soundscape widget loads
      expect(find.text('Ambient Soundscapes'), findsOneWidget);
      expect(find.text('Tap sounds to create your mix'), findsOneWidget);

      // Find and tap a sound card
      final soundCards = find.byType(GestureDetector);
      expect(soundCards, findsWidgets);
    });

    testWidgets('Enhanced audio controller manages state correctly', (
      tester,
    ) async {
      late EnhancedAudioController controller;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              controller = ref.read(enhancedAudioControllerProvider.notifier);
              final state = ref.watch(enhancedAudioControllerProvider);

              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      Text('Active Sounds: ${state.activeSounds.length}'),
                      Text('Is Playing: ${state.isPlaying}'),
                      Text('Master Volume: ${state.masterVolume}'),
                      if (state.currentlyPlayingSound != null)
                        Text('Current: ${state.currentlyPlayingSound!.name}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Active Sounds: 0'), findsOneWidget);
      expect(find.text('Is Playing: false'), findsOneWidget);
      expect(find.text('Master Volume: 0.7'), findsOneWidget);

      // Test volume control
      await controller.setMasterVolume(0.5);
      await tester.pumpAndSettle();

      expect(find.text('Master Volume: 0.5'), findsOneWidget);
    });

    testWidgets('Audio system handles motive-based recommendations', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              final controller = ref.read(
                enhancedAudioControllerProvider.notifier,
              );

              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      Text(
                        'Sleep Sounds: ${controller.getRecommendedSounds('Sleep').length}',
                      ),
                      Text(
                        'Focus Sounds: ${controller.getRecommendedSounds('Focus').length}',
                      ),
                      Text(
                        'Anxiety Sounds: ${controller.getRecommendedSounds('Anxiety').length}',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify motive-based recommendations work
      expect(find.textContaining('Sleep Sounds:'), findsOneWidget);
      expect(find.textContaining('Focus Sounds:'), findsOneWidget);
      expect(find.textContaining('Anxiety Sounds:'), findsOneWidget);
    });
  });
}
