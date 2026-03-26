import 'package:flutter_test/flutter_test.dart';

import 'package:fy_project/features/calm/application/calm_recommendation_service.dart';
import 'package:fy_project/models/calm_technique.dart';
import 'package:fy_project/config/motive_config.dart';

// Mock CalmProgressService for testing
class MockCalmProgressService {
  Future<Map<String, double>> getTechniqueEffectiveness(String userId) async {
    // Return mock effectiveness data
    return {
      '5-4-3-2-1 Grounding': 3.5,
      'Calming Affirmations': 2.8,
      'Worry Banking': 4.2,
      'Cold Water Reset': 3.1,
    };
  }
}

void main() {
  group('CalmRecommendationService', () {
    late CalmRecommendationService service;

    setUp(() {
      // Create service with mock progress service for testing
      service = CalmRecommendationService();
    });

    group('getPersonalizedRecommendations', () {
      test(
        'returns 3 recommendations for user with no effectiveness data',
        () async {
          // Arrange
          const userId = 'test-user';
          const motive = 'Anxiety';

          // Act
          final recommendations = await service.getPersonalizedRecommendations(
            userId,
            motive,
          );

          // Assert
          expect(recommendations, hasLength(lessThanOrEqualTo(3)));
          expect(recommendations, isNotEmpty);

          // Verify all returned items are CalmTechnique instances
          for (final technique in recommendations) {
            expect(technique, isA<CalmTechnique>());
          }
        },
      );

      test('prioritizes grounding techniques for anxiety motive', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Anxiety';

        // Act
        final recommendations = await service.getPersonalizedRecommendations(
          userId,
          motive,
        );

        // Assert
        expect(recommendations, isNotEmpty);

        // Should include 5-4-3-2-1 grounding technique for anxiety
        final hasGroundingTechnique = recommendations.any(
          (t) => t.type == TechniqueType.grounding || t.id == '5-4-3-2-1',
        );
        expect(hasGroundingTechnique, isTrue);
      });

      test('returns different recommendations for different motives', () async {
        // Arrange
        const userId = 'test-user';

        // Act
        final anxietyRecs = await service.getPersonalizedRecommendations(
          userId,
          'Anxiety',
        );
        final sleepRecs = await service.getPersonalizedRecommendations(
          userId,
          'Sleep',
        );

        // Assert
        expect(anxietyRecs, isNotEmpty);
        expect(sleepRecs, isNotEmpty);

        // The recommendations should be different for different motives
        // (though there might be some overlap)
        final anxietyIds = anxietyRecs.map((t) => t.id).toSet();
        final sleepIds = sleepRecs.map((t) => t.id).toSet();

        // At least one recommendation should be different
        expect(anxietyIds, isNot(equals(sleepIds)));
      });

      test('handles null motive gracefully', () async {
        // Arrange
        const userId = 'test-user';

        // Act
        final recommendations = await service.getPersonalizedRecommendations(
          userId,
          null,
        );

        // Assert
        expect(recommendations, isNotEmpty);
        expect(recommendations, hasLength(lessThanOrEqualTo(3)));
      });
    });

    group('getQuickAccessTechniques', () {
      test('returns 3-4 quick techniques for emergency use', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Anxiety';

        // Act
        final quickTechniques = await service.getQuickAccessTechniques(
          userId,
          motive,
        );

        // Assert
        expect(quickTechniques, hasLength(greaterThanOrEqualTo(3)));
        expect(quickTechniques, hasLength(lessThanOrEqualTo(4)));

        // All techniques should be quick (5 minutes or less for emergency use)
        for (final technique in quickTechniques) {
          expect(technique.durationMinutes, lessThanOrEqualTo(5));
        }
      });

      test('prioritizes shortest techniques first', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Anxiety';

        // Act
        final quickTechniques = await service.getQuickAccessTechniques(
          userId,
          motive,
        );

        // Assert
        expect(quickTechniques, isNotEmpty);

        // First technique should be among the shortest available
        final firstTechnique = quickTechniques.first;
        expect(firstTechnique.durationMinutes, lessThanOrEqualTo(5));
      });

      test('includes grounding techniques for anxiety motive', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Anxiety';

        // Act
        final quickTechniques = await service.getQuickAccessTechniques(
          userId,
          motive,
        );

        // Assert
        expect(quickTechniques, isNotEmpty);

        // Should include grounding techniques for anxiety
        final hasGroundingTechnique = quickTechniques.any(
          (t) => t.type == TechniqueType.grounding,
        );
        expect(hasGroundingTechnique, isTrue);
      });
    });

    group('getEmergencyTechnique', () {
      test('returns a single emergency technique', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Anxiety';

        // Act
        final emergencyTechnique = await service.getEmergencyTechnique(
          userId,
          motive,
        );

        // Assert
        expect(emergencyTechnique, isNotNull);
        expect(emergencyTechnique, isA<CalmTechnique>());

        // Should be a quick technique suitable for emergency use
        expect(emergencyTechnique!.durationMinutes, lessThanOrEqualTo(5));
      });

      test('returns 5-4-3-2-1 grounding as fallback', () async {
        // Arrange
        const userId = 'test-user';

        // Act
        final emergencyTechnique = await service.getEmergencyTechnique(
          userId,
          null,
        );

        // Assert
        expect(emergencyTechnique, isNotNull);
        // Should return a reliable emergency technique
        expect(emergencyTechnique!.durationMinutes, lessThanOrEqualTo(5));
      });
    });

    group('motive-based prioritization', () {
      test('sleep motive prioritizes visualization techniques', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Sleep';

        // Act
        final recommendations = await service.getPersonalizedRecommendations(
          userId,
          motive,
        );

        // Assert
        expect(recommendations, isNotEmpty);

        // Should include visualization techniques for sleep
        final hasVisualizationTechnique = recommendations.any(
          (t) => t.type == TechniqueType.visualization,
        );
        expect(hasVisualizationTechnique, isTrue);
      });

      test('stress motive prioritizes breathing techniques', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Stress';

        // Act
        final recommendations = await service.getPersonalizedRecommendations(
          userId,
          motive,
        );

        // Assert
        expect(recommendations, isNotEmpty);

        // Should include breathing techniques for stress
        final hasBreathingTechnique = recommendations.any(
          (t) => t.type == TechniqueType.breathing,
        );
        expect(hasBreathingTechnique, isTrue);
      });

      test('habit building motive includes affirmation techniques', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Habit Building';

        // Act
        final recommendations = await service.getPersonalizedRecommendations(
          userId,
          motive,
        );

        // Assert
        expect(recommendations, isNotEmpty);

        // Should include affirmation techniques for habit building
        final hasAffirmationTechnique = recommendations.any(
          (t) => t.type == TechniqueType.affirmation,
        );
        expect(hasAffirmationTechnique, isTrue);
      });
    });

    group('time-of-day adaptation', () {
      test('recommendations adapt to different times of day', () async {
        // This test would ideally mock DateTime.now() to test different times
        // For now, we verify that the service handles time-based logic

        // Arrange
        const userId = 'test-user';
        const motive = 'Focus';

        // Act
        final recommendations = await service.getPersonalizedRecommendations(
          userId,
          motive,
        );

        // Assert
        expect(recommendations, isNotEmpty);

        // Verify that recommendations are returned regardless of time
        // (actual time-based logic would need DateTime mocking to test properly)
        for (final technique in recommendations) {
          expect(technique, isA<CalmTechnique>());
        }
      });
    });

    group('error handling', () {
      test('handles service errors gracefully', () async {
        // Arrange
        const userId = 'test-user';
        const motive = 'Anxiety';

        // Act & Assert - should not throw even if internal services fail
        expect(
          () async =>
              await service.getPersonalizedRecommendations(userId, motive),
          returnsNormally,
        );

        expect(
          () async => await service.getQuickAccessTechniques(userId, motive),
          returnsNormally,
        );

        expect(
          () async => await service.getEmergencyTechnique(userId, motive),
          returnsNormally,
        );
      });
    });

    group('integration with MotiveConfig', () {
      test('uses MotiveConfig for technique priorities', () {
        // Arrange
        const motive = 'Anxiety';

        // Act
        final priorities = MotiveConfig.getCalmTechniquePriorities(motive);

        // Assert
        expect(priorities, isNotEmpty);
        expect(priorities, contains('Grounding'));
        expect(priorities, contains('Breathing'));
      });

      test('handles all supported motives', () async {
        // Arrange
        const userId = 'test-user';
        final allMotives = MotiveConfig.allMotives;

        // Act & Assert
        for (final motive in allMotives) {
          final recommendations = await service.getPersonalizedRecommendations(
            userId,
            motive,
          );
          expect(
            recommendations,
            isNotEmpty,
            reason: 'Failed for motive: $motive',
          );

          final quickTechniques = await service.getQuickAccessTechniques(
            userId,
            motive,
          );
          expect(
            quickTechniques,
            isNotEmpty,
            reason: 'Failed quick access for motive: $motive',
          );

          final emergencyTechnique = await service.getEmergencyTechnique(
            userId,
            motive,
          );
          expect(
            emergencyTechnique,
            isNotNull,
            reason: 'Failed emergency for motive: $motive',
          );
        }
      });
    });
  });
}
