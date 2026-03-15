import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/features/calm/application/navigation_integration_service.dart';
import 'package:fy_project/features/calm/application/ecosystem_integration_service.dart';

void main() {
  group('NavigationIntegrationService - Unit Tests', () {
    late NavigationIntegrationService navigationService;

    setUp(() {
      navigationService = NavigationIntegrationService();
    });

    group('Feature Boundaries', () {
      test('should provide clear feature boundaries', () {
        // Act
        final boundaries = navigationService.getFeatureBoundaries();

        // Assert
        expect(boundaries, hasLength(3));
        expect(
          boundaries['calm'],
          equals('Immediate anxiety relief and grounding techniques'),
        );
        expect(
          boundaries['breathing'],
          equals('Structured breathing exercises and patterns'),
        );
        expect(
          boundaries['meditation'],
          equals('Guided meditation practices and mindfulness'),
        );
      });

      test('should ensure distinct boundaries for each feature', () {
        // Act
        final boundaries = navigationService.getFeatureBoundaries();

        // Assert - Each feature should have distinct boundaries
        final calmBoundary = boundaries['calm']!;
        final breathingBoundary = boundaries['breathing']!;
        final meditationBoundary = boundaries['meditation']!;

        expect(calmBoundary, isNot(equals(breathingBoundary)));
        expect(calmBoundary, isNot(equals(meditationBoundary)));
        expect(breathingBoundary, isNot(equals(meditationBoundary)));

        // Calm should focus on immediate anxiety relief
        expect(calmBoundary, contains('anxiety relief'));
        expect(calmBoundary, contains('grounding'));

        // Breathing should focus on structured exercises
        expect(breathingBoundary.toLowerCase(), contains('structured'));
        expect(breathingBoundary.toLowerCase(), contains('exercises'));

        // Meditation should focus on guided practices
        expect(meditationBoundary.toLowerCase(), contains('guided'));
        expect(meditationBoundary.toLowerCase(), contains('mindfulness'));
      });
    });

    group('Navigation Suggestions', () {
      test('should provide motive-specific navigation suggestions', () {
        // Act
        final suggestions = navigationService.getNavigationSuggestions(
          'Anxiety',
        );

        // Assert
        expect(suggestions, hasLength(2));

        final breathingSuggestion = suggestions.firstWhere(
          (s) => s.category == 'breathing',
        );
        expect(breathingSuggestion.title, equals('Breathing Exercises'));
        expect(breathingSuggestion.description, contains('anxiety management'));
        expect(breathingSuggestion.route, equals('/breathing'));
        expect(breathingSuggestion.estimatedDuration, isNotEmpty);

        final meditationSuggestion = suggestions.firstWhere(
          (s) => s.category == 'meditation',
        );
        expect(meditationSuggestion.title, equals('Guided Meditation'));
        expect(
          meditationSuggestion.description,
          contains('anxiety management'),
        );
        expect(meditationSuggestion.route, equals('/meditation'));
        expect(meditationSuggestion.estimatedDuration, isNotEmpty);
      });

      test('should provide default suggestions for unknown motive', () {
        // Act
        final suggestions = navigationService.getNavigationSuggestions(
          'Unknown',
        );

        // Assert
        expect(suggestions, hasLength(2));

        for (final suggestion in suggestions) {
          expect(suggestion.description, contains('wellness'));
          expect(suggestion.title, isNotEmpty);
          expect(suggestion.route, startsWith('/'));
          expect(suggestion.estimatedDuration, isNotEmpty);
        }
      });

      test('should provide contextual help for all motives', () {
        final motives = [
          'Sleep',
          'Stress',
          'Anxiety',
          'Focus',
          'Habit Building',
        ];

        for (final motive in motives) {
          // Act
          final suggestions = navigationService.getNavigationSuggestions(
            motive,
          );

          // Assert
          expect(suggestions, hasLength(2));

          for (final suggestion in suggestions) {
            expect(suggestion.title, isNotEmpty);
            expect(suggestion.description, isNotEmpty);
            expect(suggestion.estimatedDuration, isNotEmpty);
            expect(suggestion.route, startsWith('/'));
            expect(suggestion.category, isIn(['breathing', 'meditation']));
          }
        }
      });
    });

    group('Motive Context', () {
      test('should provide appropriate context for each motive', () {
        final testCases = {
          'Sleep': 'better sleep preparation',
          'Stress': 'stress relief',
          'Anxiety': 'anxiety management',
          'Focus': 'improved concentration',
          'Habit Building': 'mindful habit formation',
          'Unknown': 'wellness',
        };

        for (final entry in testCases.entries) {
          final suggestions = navigationService.getNavigationSuggestions(
            entry.key,
          );

          for (final suggestion in suggestions) {
            expect(suggestion.description, contains(entry.value));
          }
        }
      });
    });
  });

  group('EcosystemIntegrationService - Unit Tests', () {
    late EcosystemIntegrationService ecosystemService;

    setUp(() {
      ecosystemService = EcosystemIntegrationService();
    });

    group('Feature Links', () {
      test('should provide navigation links to existing features', () {
        // Act
        final links = ecosystemService.getExistingFeatureLinks();

        // Assert
        expect(links, hasLength(3));
        expect(links.keys, contains('breathing'));
        expect(links.keys, contains('meditation'));
        expect(links.keys, contains('journaling'));

        final breathingLink = links['breathing']!;
        expect(breathingLink.title, equals('Breathing Exercises'));
        expect(breathingLink.route, equals('/breathing'));
        expect(breathingLink.category, equals('wellness'));
        expect(breathingLink.description, isNotEmpty);

        final meditationLink = links['meditation']!;
        expect(meditationLink.title, equals('Meditation Library'));
        expect(meditationLink.route, equals('/meditation'));
        expect(meditationLink.category, equals('wellness'));
        expect(meditationLink.description, isNotEmpty);

        final journalingLink = links['journaling']!;
        expect(journalingLink.title, equals('Journaling'));
        expect(journalingLink.route, equals('/journaling'));
        expect(journalingLink.category, equals('reflection'));
        expect(journalingLink.description, isNotEmpty);
      });

      test('should ensure all links have required properties', () {
        // Act
        final links = ecosystemService.getExistingFeatureLinks();

        // Assert
        for (final link in links.values) {
          expect(link.title, isNotEmpty);
          expect(link.description, isNotEmpty);
          expect(link.route, startsWith('/'));
          expect(link.icon, isNotEmpty);
          expect(link.category, isIn(['wellness', 'reflection']));
        }
      });
    });
  });

  group('Integration Validation', () {
    test('should ensure no duplication of existing functionality', () {
      final navigationService = NavigationIntegrationService();

      // Verify that navigation service provides access without duplication
      final boundaries = navigationService.getFeatureBoundaries();

      // Each feature should have distinct boundaries
      final features = boundaries.keys.toList();
      expect(features, hasLength(3));
      expect(features, containsAll(['calm', 'breathing', 'meditation']));

      // Verify no overlap in descriptions
      final descriptions = boundaries.values.toList();
      expect(descriptions.toSet(), hasLength(3)); // All unique
    });

    test('should provide clear contextual help', () {
      final navigationService = NavigationIntegrationService();

      // Test suggestions provide clear context
      final suggestions = navigationService.getNavigationSuggestions('Anxiety');

      for (final suggestion in suggestions) {
        expect(suggestion.title, isNotEmpty);
        expect(suggestion.description, isNotEmpty);
        expect(suggestion.estimatedDuration, isNotEmpty);
        expect(suggestion.route, startsWith('/'));
        expect(suggestion.category, isIn(['breathing', 'meditation']));
      }
    });

    test('should maintain consistent navigation structure', () {
      final navigationService = NavigationIntegrationService();
      final ecosystemService = EcosystemIntegrationService();

      // Get suggestions and links
      final suggestions = navigationService.getNavigationSuggestions('Anxiety');
      final links = ecosystemService.getExistingFeatureLinks();

      // Verify consistency between suggestions and links
      for (final suggestion in suggestions) {
        final correspondingLink = links[suggestion.category];
        if (correspondingLink != null) {
          expect(suggestion.route, equals(correspondingLink.route));
        }
      }
    });
  });
}
