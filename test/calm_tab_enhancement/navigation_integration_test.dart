import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/features/calm/application/navigation_integration_service.dart';
import 'package:fy_project/features/calm/application/ecosystem_integration_service.dart';

void main() {
  group('NavigationIntegrationService', () {
    late NavigationIntegrationService navigationService;

    setUp(() {
      navigationService = NavigationIntegrationService();
    });

    group('Quick Access Features', () {
      test('should return breathing techniques suitable for anxiety relief', () {
        // Act
        final techniques = navigationService
            .getQuickAccessBreathingTechniques();

        // Assert
        expect(techniques, isNotEmpty);
        expect(techniques.length, lessThanOrEqualTo(3));

        // Verify techniques are suitable for quick anxiety relief
        for (final technique in techniques) {
          expect(
            technique.title.contains('4-7-8') ||
                technique.title.contains('Box') ||
                technique.title.contains('Calm'),
            isTrue,
            reason:
                'Technique ${technique.title} should be suitable for anxiety relief',
          );
        }
      });

      test('should return meditation previews based on motive', () {
        // Act - Test with anxiety motive
        final anxietyMeditations = navigationService.getMeditationPreviews(
          motive: 'Anxiety',
        );

        // Assert
        expect(anxietyMeditations, isNotEmpty);
        expect(anxietyMeditations.length, lessThanOrEqualTo(3));

        // Act - Test without motive (should default to anxiety/stress)
        final defaultMeditations = navigationService.getMeditationPreviews();

        // Assert
        expect(defaultMeditations, isNotEmpty);
        expect(defaultMeditations.length, lessThanOrEqualTo(3));
      });
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

        final meditationSuggestion = suggestions.firstWhere(
          (s) => s.category == 'meditation',
        );
        expect(meditationSuggestion.title, equals('Guided Meditation'));
        expect(
          meditationSuggestion.description,
          contains('anxiety management'),
        );
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
        }
      });
    });
  });

  group('EcosystemIntegrationService', () {
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
      });
    });
  });

  group('Integration Validation', () {
    test('should ensure no duplication of existing functionality', () {
      final navigationService = NavigationIntegrationService();

      // Verify that navigation service provides access without duplication
      final boundaries = navigationService.getFeatureBoundaries();

      // Each feature should have distinct boundaries
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
      expect(breathingBoundary, contains('structured'));
      expect(breathingBoundary, contains('exercises'));

      // Meditation should focus on guided practices
      expect(meditationBoundary, contains('guided'));
      expect(meditationBoundary, contains('mindfulness'));
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
      }
    });
  });
}
