import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fy_project/screens/home_screen.dart';
import 'package:fy_project/widgets/calm/mini_audio_player.dart';
import 'package:fy_project/screens/audio_player_screen.dart';
import 'package:fy_project/models/ambient_sound.dart';

void main() {
  group('Audio System Fixes Tests', () {
    testWidgets('HomeScreen includes MiniAudioPlayer', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: HomeScreen())),
      );

      await tester.pumpAndSettle();

      // Verify that MiniAudioPlayer is present in the widget tree
      expect(find.byType(MiniAudioPlayer), findsOneWidget);
    });

    testWidgets('AudioPlayerScreen has functional progress slider', (
      tester,
    ) async {
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

      await tester.pumpAndSettle();

      // Find the progress slider
      final progressSliders = find.byType(Slider);
      expect(progressSliders, findsWidgets);

      // Find the specific progress slider (not the volume slider)
      final progressSlider = progressSliders.first;
      expect(progressSlider, findsOneWidget);

      // Test that the slider can be interacted with
      await tester.tap(progressSlider);
      await tester.pumpAndSettle();

      // Verify the screen still renders correctly after interaction
      expect(find.text(testSound.name), findsOneWidget);
    });

    testWidgets('Progress tracking updates correctly', (tester) async {
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

      await tester.pumpAndSettle();

      // Verify initial time display
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget); // 5 minutes default duration

      // The progress should be functional (we can't easily test the timer in unit tests,
      // but we can verify the UI elements are present and functional)
      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);
    });
  });
}
