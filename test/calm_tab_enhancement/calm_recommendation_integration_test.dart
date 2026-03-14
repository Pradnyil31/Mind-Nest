import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/calm/application/calm_recommendation_service.dart';
import '../../lib/models/calm_technique.dart';
import '../../lib/config/motive_config.dart';

void main() {
  group('CalmRecommendationService Integration', () {
    late CalmRecommendationService service;

    setUp(() {
      service = CalmRecommendationService();
    });

    test(
      'provides complete recommendation workflow for anxiety user',
      () async {
        // Simulate a user with anxiety motive
        const userId = 'anxiety-user-123';
        const motive = 'Anxiety';

        // Test the complete workflow that would happen in the UI

        // 1. Get personalized recommendations for main screen
        final mainRecommendations = await service
            .getPersonalizedRecommendations(userId, motive);

        expect(mainRecommendations, isNotEmpty);
        expect(mainRecommendations.length, lessThanOrEqualTo(3));

        // Should prioritize grounding techniques for anxiety
        final hasGroundingTechnique = mainRecommendations.any(
          (t) => t.type == TechniqueType.grounding || t.id == '5-4-3-2-1',
        );
        expect(
          hasGroundingTechnique,
          isTrue,
          reason: 'Anxiety users should get grounding techniques',
        );

        // 2. Get quick access techniques for emergency panel
        final quickTechniques = await service.getQuickAccessTechniques(
          userId,
          motive,
        );

        expect(quickTechniques, isNotEmpty);
        expect(quickTechniques.length, greaterThanOrEqualTo(3));
        expect(quickTechniques.length, lessThanOrEqualTo(4));

        // All should be quick (suitable for emergency)
        for (final technique in quickTechniques) {
          expect(technique.durationMinutes, lessThanOrEqualTo(5));
        }

        // 3. Get single emergency technique
        final emergencyTechnique = await service.getEmergencyTechnique(
          userId,
          motive,
        );

        expect(emergencyTechnique, isNotNull);
        expect(emergencyTechnique!.durationMinutes, lessThanOrEqualTo(5));

        // Should be suitable for immediate anxiety relief
        expect([
          TechniqueType.grounding,
          TechniqueType.breathing,
          TechniqueType.affirmation,
        ], contains(emergencyTechnique.type));
      },
    );

    test('adapts recommendations for different motives', () async {
      const userId = 'test-user-456';

      // Test all supported motives
      for (final motive in MotiveConfig.allMotives) {
        final recommendations = await service.getPersonalizedRecommendations(
          userId,
          motive,
        );
        final quickTechniques = await service.getQuickAccessTechniques(
          userId,
          motive,
        );
        final emergencyTechnique = await service.getEmergencyTechnique(
          userId,
          motive,
        );

        // All motives should get valid recommendations
        expect(
          recommendations,
          isNotEmpty,
          reason: 'No recommendations for $motive',
        );
        expect(
          quickTechniques,
          isNotEmpty,
          reason: 'No quick techniques for $motive',
        );
        expect(
          emergencyTechnique,
          isNotNull,
          reason: 'No emergency technique for $motive',
        );

        // Verify motive-specific priorities are reflected
        final motivePriorities = MotiveConfig.getCalmTechniquePriorities(
          motive,
        );
        expect(
          motivePriorities,
          isNotEmpty,
          reason: 'No priorities defined for $motive',
        );

        // At least one recommendation should align with motive priorities
        bool hasMotiveAlignedTechnique = false;
        for (final technique in recommendations) {
          final techniqueTypeName = _getTechniqueTypeName(technique.type);
          for (final priority in motivePriorities) {
            if (priority.toLowerCase().contains(
                  techniqueTypeName.toLowerCase(),
                ) ||
                techniqueTypeName.toLowerCase().contains(
                  priority.toLowerCase(),
                )) {
              hasMotiveAlignedTechnique = true;
              break;
            }
          }
          if (hasMotiveAlignedTechnique) break;
        }

        expect(
          hasMotiveAlignedTechnique,
          isTrue,
          reason: 'No motive-aligned techniques for $motive',
        );
      }
    });

    test('handles edge cases gracefully', () async {
      const userId = 'edge-case-user';

      // Test with null motive
      final nullMotiveRecs = await service.getPersonalizedRecommendations(
        userId,
        null,
      );
      expect(nullMotiveRecs, isNotEmpty, reason: 'Should handle null motive');

      // Test with invalid motive
      final invalidMotiveRecs = await service.getPersonalizedRecommendations(
        userId,
        'InvalidMotive',
      );
      expect(
        invalidMotiveRecs,
        isNotEmpty,
        reason: 'Should handle invalid motive',
      );

      // Test with empty user ID
      final emptyUserRecs = await service.getPersonalizedRecommendations(
        '',
        'Anxiety',
      );
      expect(emptyUserRecs, isNotEmpty, reason: 'Should handle empty user ID');
    });

    test('provides consistent technique quality', () async {
      const userId = 'quality-test-user';
      const motive = 'Focus';

      final recommendations = await service.getPersonalizedRecommendations(
        userId,
        motive,
      );

      // All recommendations should be valid CalmTechnique objects
      for (final technique in recommendations) {
        expect(
          technique.id,
          isNotEmpty,
          reason: 'Technique should have valid ID',
        );
        expect(
          technique.title,
          isNotEmpty,
          reason: 'Technique should have title',
        );
        expect(
          technique.description,
          isNotEmpty,
          reason: 'Technique should have description',
        );
        expect(
          technique.icon,
          isNotEmpty,
          reason: 'Technique should have icon',
        );
        expect(
          technique.durationMinutes,
          greaterThan(0),
          reason: 'Technique should have valid duration',
        );

        // Should have either steps or content for guidance
        expect(
          technique.steps != null || technique.content != null,
          isTrue,
          reason: 'Technique should have guidance (steps or content)',
        );
      }
    });

    test('emergency techniques are truly quick', () async {
      const userId = 'emergency-test-user';

      for (final motive in MotiveConfig.allMotives) {
        final emergencyTechnique = await service.getEmergencyTechnique(
          userId,
          motive,
        );

        expect(
          emergencyTechnique,
          isNotNull,
          reason: 'Should have emergency technique for $motive',
        );
        expect(
          emergencyTechnique!.durationMinutes,
          lessThanOrEqualTo(5),
          reason: 'Emergency technique should be quick for $motive',
        );

        // Emergency techniques should be actionable immediately
        if (emergencyTechnique.steps != null) {
          expect(
            emergencyTechnique.steps!.length,
            greaterThan(0),
            reason: 'Emergency technique should have actionable steps',
          );
        }
        if (emergencyTechnique.content != null) {
          expect(
            emergencyTechnique.content!.length,
            greaterThan(0),
            reason: 'Emergency technique should have actionable content',
          );
        }
      }
    });
  });
}

/// Helper function to convert TechniqueType to string for comparison
String _getTechniqueTypeName(TechniqueType type) {
  switch (type) {
    case TechniqueType.grounding:
      return 'Grounding';
    case TechniqueType.affirmation:
      return 'Affirmations';
    case TechniqueType.breathing:
      return 'Breathing';
    case TechniqueType.visualization:
      return 'Visualization';
  }
}
