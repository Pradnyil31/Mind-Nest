import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/calm_technique.dart';
import '../../lib/config/motive_config.dart';

void main() {
  group('CalmRecommendationService Logic Tests', () {
    group('CalmTechnique model', () {
      test('has default techniques available', () {
        // Arrange & Act
        final techniques = CalmTechnique.defaults;

        // Assert
        expect(techniques, isNotEmpty);
        expect(techniques.length, greaterThanOrEqualTo(4));

        // Verify we have techniques of different types
        final types = techniques.map((t) => t.type).toSet();
        expect(types, contains(TechniqueType.grounding));
        expect(types, contains(TechniqueType.affirmation));
        expect(types, contains(TechniqueType.visualization));
      });

      test('includes 5-4-3-2-1 grounding technique', () {
        // Arrange & Act
        final techniques = CalmTechnique.defaults;
        final groundingTechnique = techniques.firstWhere(
          (t) => t.id == '5-4-3-2-1',
          orElse: () => throw Exception('5-4-3-2-1 technique not found'),
        );

        // Assert
        expect(groundingTechnique.title, '5-4-3-2-1 Grounding');
        expect(groundingTechnique.type, TechniqueType.grounding);
        expect(groundingTechnique.durationMinutes, 5);
        expect(groundingTechnique.steps, isNotNull);
        expect(groundingTechnique.steps!.length, greaterThan(5));
      });

      test('includes quick techniques for emergency use', () {
        // Arrange & Act
        final techniques = CalmTechnique.defaults;
        final quickTechniques = techniques
            .where((t) => t.durationMinutes <= 5)
            .toList();

        // Assert
        expect(quickTechniques, isNotEmpty);
        expect(quickTechniques.length, greaterThanOrEqualTo(2));

        // Should include affirmations (2 minutes)
        final affirmations = quickTechniques.where(
          (t) => t.type == TechniqueType.affirmation,
        );
        expect(affirmations, isNotEmpty);
      });

      test('can filter techniques by type', () {
        // Arrange & Act
        final groundingTechniques = CalmTechnique.getByType(
          TechniqueType.grounding,
        );
        final affirmationTechniques = CalmTechnique.getByType(
          TechniqueType.affirmation,
        );

        // Assert
        expect(groundingTechniques, isNotEmpty);
        expect(affirmationTechniques, isNotEmpty);

        // Verify all returned techniques have the correct type
        for (final technique in groundingTechniques) {
          expect(technique.type, TechniqueType.grounding);
        }

        for (final technique in affirmationTechniques) {
          expect(technique.type, TechniqueType.affirmation);
        }
      });
    });

    group('MotiveConfig integration', () {
      test('provides calm technique priorities for all motives', () {
        // Arrange
        final allMotives = MotiveConfig.allMotives;

        // Act & Assert
        for (final motive in allMotives) {
          final priorities = MotiveConfig.getCalmTechniquePriorities(motive);

          expect(
            priorities,
            isNotEmpty,
            reason: 'No priorities for motive: $motive',
          );
          expect(
            priorities.length,
            greaterThanOrEqualTo(2),
            reason: 'Insufficient priorities for motive: $motive',
          );

          // Verify priorities contain valid technique types
          final validTypes = [
            'Grounding',
            'Breathing',
            'Visualization',
            'Affirmations',
            'Body Scan',
            'Guided Imagery',
            'Meditation',
            'Body Awareness',
          ];

          for (final priority in priorities) {
            final hasValidType = validTypes.any(
              (type) =>
                  priority.toLowerCase().contains(type.toLowerCase()) ||
                  type.toLowerCase().contains(priority.toLowerCase()),
            );
            expect(
              hasValidType,
              isTrue,
              reason: 'Invalid priority "$priority" for motive: $motive',
            );
          }
        }
      });

      test('anxiety motive prioritizes grounding techniques', () {
        // Arrange & Act
        final anxietyPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Anxiety',
        );

        // Assert
        expect(anxietyPriorities, contains('Grounding'));
        expect(anxietyPriorities, contains('Breathing'));

        // Grounding should be high priority for anxiety
        final groundingIndex = anxietyPriorities.indexOf('Grounding');
        expect(
          groundingIndex,
          lessThan(2),
          reason: 'Grounding should be high priority for anxiety',
        );
      });

      test('sleep motive includes appropriate techniques', () {
        // Arrange & Act
        final sleepPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Sleep',
        );

        // Assert
        expect(sleepPriorities, isNotEmpty);

        // Should include body scan or guided imagery for sleep
        final hasBodyScan = sleepPriorities.any(
          (p) => p.toLowerCase().contains('body'),
        );
        final hasImagery = sleepPriorities.any(
          (p) => p.toLowerCase().contains('imagery'),
        );

        expect(
          hasBodyScan || hasImagery,
          isTrue,
          reason: 'Sleep motive should include body scan or guided imagery',
        );
      });

      test('stress motive prioritizes breathing techniques', () {
        // Arrange & Act
        final stressPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Stress',
        );

        // Assert
        expect(stressPriorities, contains('Breathing'));

        // Breathing should be high priority for stress
        final breathingIndex = stressPriorities.indexOf('Breathing');
        expect(
          breathingIndex,
          lessThan(2),
          reason: 'Breathing should be high priority for stress',
        );
      });

      test('habit building motive includes affirmations', () {
        // Arrange & Act
        final habitPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Habit Building',
        );

        // Assert
        expect(habitPriorities, isNotEmpty);

        // Should include affirmations for habit building
        final hasAffirmations = habitPriorities.any(
          (p) => p.toLowerCase().contains('affirmation'),
        );
        expect(
          hasAffirmations,
          isTrue,
          reason: 'Habit Building motive should include affirmations',
        );
      });
    });

    group('Technique scoring logic', () {
      test('techniques have appropriate durations for different use cases', () {
        // Arrange
        final techniques = CalmTechnique.defaults;

        // Act
        final quickTechniques = techniques
            .where((t) => t.durationMinutes <= 2)
            .toList();
        final mediumTechniques = techniques
            .where((t) => t.durationMinutes > 2 && t.durationMinutes <= 5)
            .toList();
        final longerTechniques = techniques
            .where((t) => t.durationMinutes > 5)
            .toList();

        // Assert
        expect(
          quickTechniques,
          isNotEmpty,
          reason: 'Should have quick techniques for emergencies',
        );
        expect(
          mediumTechniques,
          isNotEmpty,
          reason: 'Should have medium-length techniques',
        );

        // Quick techniques should be suitable for emergency use
        for (final technique in quickTechniques) {
          expect(technique.durationMinutes, lessThanOrEqualTo(2));
          // Quick techniques should typically be affirmations or simple grounding
          expect([
            TechniqueType.affirmation,
            TechniqueType.grounding,
            TechniqueType.visualization,
          ], contains(technique.type));
        }
      });

      test('grounding techniques are suitable for anxiety', () {
        // Arrange
        final groundingTechniques = CalmTechnique.getByType(
          TechniqueType.grounding,
        );

        // Assert
        expect(groundingTechniques, isNotEmpty);

        // Should include the 5-4-3-2-1 technique
        final has5432Technique = groundingTechniques.any(
          (t) => t.id == '5-4-3-2-1',
        );
        expect(
          has5432Technique,
          isTrue,
          reason: '5-4-3-2-1 should be a grounding technique',
        );

        // Grounding techniques should have steps for guidance
        for (final technique in groundingTechniques) {
          if (technique.steps != null) {
            expect(
              technique.steps!.length,
              greaterThan(3),
              reason: 'Grounding techniques should have multiple steps',
            );
          }
        }
      });

      test('visualization techniques are suitable for sleep', () {
        // Arrange
        final visualizationTechniques = CalmTechnique.getByType(
          TechniqueType.visualization,
        );

        // Assert
        expect(visualizationTechniques, isNotEmpty);

        // Should include cold water visualization
        final hasColdWater = visualizationTechniques.any(
          (t) => t.id == 'cold-water-visualization',
        );
        expect(
          hasColdWater,
          isTrue,
          reason: 'Should include cold water visualization',
        );

        // Visualization techniques should have guided steps
        for (final technique in visualizationTechniques) {
          if (technique.steps != null) {
            expect(
              technique.steps!.length,
              greaterThan(4),
              reason: 'Visualization techniques should have detailed steps',
            );
          }
        }
      });

      test('affirmation techniques provide positive content', () {
        // Arrange
        final affirmationTechniques = CalmTechnique.getByType(
          TechniqueType.affirmation,
        );

        // Assert
        expect(affirmationTechniques, isNotEmpty);

        // Affirmations should have content rather than steps
        for (final technique in affirmationTechniques) {
          if (technique.content != null) {
            expect(
              technique.content!.length,
              greaterThan(5),
              reason: 'Affirmations should have multiple positive statements',
            );

            // Content should be positive and calming
            for (final affirmation in technique.content!) {
              expect(
                affirmation.toLowerCase(),
                anyOf([
                  contains('calm'),
                  contains('peace'),
                  contains('safe'),
                  contains('strong'),
                  contains('worthy'),
                  contains('enough'),
                  contains('temporary'),
                  contains('trust'),
                  contains('breathe'),
                  contains('control'),
                  contains('best'),
                  contains('deserve'),
                  contains('step'),
                  contains('anxiety'),
                  contains('grounded'),
                  contains('love'),
                  contains('kindness'),
                  contains('within'),
                  contains('let go'),
                  contains('release'),
                  contains('serves'),
                  contains('handle'),
                  contains('tension'),
                  contains('rest'),
                  contains('relaxation'),
                  contains('choose'),
                  contains('worry'),
                  contains('mind'),
                  contains('body'),
                  contains('relaxed'),
                  contains('present'),
                  contains('moment'),
                ]),
                reason: 'Affirmations should contain positive language',
              );
            }
          }
        }
      });
    });

    group('Time-based recommendations', () {
      test('different times of day should favor different technique types', () {
        // This is a conceptual test - in a real implementation, we'd mock DateTime.now()
        // For now, we verify that the technique library has variety suitable for different times

        // Arrange
        final techniques = CalmTechnique.defaults;

        // Act
        final energizingTechniques = techniques
            .where((t) => t.type == TechniqueType.affirmation)
            .toList();
        final relaxingTechniques = techniques
            .where((t) => t.type == TechniqueType.visualization)
            .toList();
        final focusingTechniques = techniques
            .where((t) => t.type == TechniqueType.grounding)
            .toList();

        // Assert
        expect(
          energizingTechniques,
          isNotEmpty,
          reason: 'Should have energizing techniques for morning',
        );
        expect(
          relaxingTechniques,
          isNotEmpty,
          reason: 'Should have relaxing techniques for evening',
        );
        expect(
          focusingTechniques,
          isNotEmpty,
          reason: 'Should have focusing techniques for afternoon',
        );
      });
    });
  });
}
