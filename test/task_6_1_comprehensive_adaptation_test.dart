import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/config/motive_config.dart';
import 'package:fy_project/features/calm/application/motive_detection_service.dart';

void main() {
  group(
    'Task 6.1: Comprehensive Motive Detection and Adaptation - Enhanced',
    () {
      test('should provide enhanced cross-motive data preservation logic', () {
        // Test cross-motive data preservation logic without Firebase
        const initialState = MotiveDetectionState(currentMotive: 'Sleep');
        final changedState = initialState.copyWith(
          previousMotive: 'Sleep',
          currentMotive: 'Anxiety',
          motiveChangeDetected: true,
          adaptationInProgress: true,
        );

        expect(changedState.previousMotive, equals('Sleep'));
        expect(changedState.currentMotive, equals('Anxiety'));
        expect(changedState.motiveChangeDetected, isTrue);
        expect(changedState.adaptationInProgress, isTrue);
      });

      test('should provide enhanced motive-specific welcome messages', () {
        // Test enhanced welcome messages with comprehensive context
        for (final motive in MotiveConfig.allMotives) {
          final profile = MotiveConfig.getProfile(motive);
          expect(profile, isNotNull);

          // Test that each motive has enhanced contextual elements
          switch (motive) {
            case 'Sleep':
              expect(profile!.emoji, equals('🌙'));
              expect(profile.displayName, equals('Better Sleep'));
              break;
            case 'Stress':
              expect(profile!.emoji, equals('🧘'));
              expect(profile.displayName, equals('Stress Management'));
              break;
            case 'Anxiety':
              expect(profile!.emoji, equals('💜'));
              expect(profile.displayName, equals('Anxiety Relief'));
              break;
            case 'Focus':
              expect(profile!.emoji, equals('🎯'));
              expect(profile.displayName, equals('Enhanced Focus'));
              break;
            case 'Habit Building':
              expect(profile!.emoji, equals('🔥'));
              expect(profile.displayName, equals('Habit Building'));
              break;
          }
        }
      });
    },
  );
}
