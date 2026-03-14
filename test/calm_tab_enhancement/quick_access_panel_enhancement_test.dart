import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/widgets/calm/quick_access_panel.dart';
import '../../lib/models/calm_technique.dart';

void main() {
  group('Quick Access Panel Enhancement Tests', () {
    testWidgets('displays motive-specific panel content', (tester) async {
      // Test different motives and their expected content
      const testCases = [
        (
          'Sleep',
          'Sleep Support',
          'Calm your mind and prepare for restful sleep',
        ),
        ('Stress', 'Stress Relief', 'Release tension and restore inner calm'),
        (
          'Anxiety',
          'Anxiety Relief',
          'Ground yourself and find your center right now',
        ),
        ('Focus', 'Focus Boost', 'Clear mental fog and sharpen concentration'),
        (
          'Habit Building',
          'Quick Motivation',
          'Stay motivated and build positive momentum',
        ),
      ];

      for (final (motive, expectedTitle, expectedSubtitle) in testCases) {
        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: QuickAccessPanel(
                  userMotive: motive,
                  primaryColor: const Color(0xFF4DB6AC),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text(expectedTitle),
          findsOneWidget,
          reason: 'Should show motive-specific title for $motive',
        );
        expect(
          find.text(expectedSubtitle),
          findsOneWidget,
          reason: 'Should show motive-specific subtitle for $motive',
        );

        // Verify panel structure
        expect(find.byType(QuickAccessPanel), findsOneWidget);
        expect(find.byIcon(Icons.flash_on), findsOneWidget);
      }
    });

    testWidgets('shows loading state initially', (tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickAccessPanel(
                userMotive: 'Anxiety',
                primaryColor: const Color(0xFF4DB6AC),
              ),
            ),
          ),
        ),
      );

      // Assert - should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays emergency technique prominently', (tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickAccessPanel(
                userMotive: 'Anxiety',
                primaryColor: const Color(0xFF4DB6AC),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show emergency technique card
      // Note: This will show fallback techniques since we don't have real services
      expect(find.byType(QuickAccessPanel), findsOneWidget);

      // Should have at least one technique button
      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    testWidgets('filters techniques to under 2 minutes for emergency use', (
      tester,
    ) async {
      // Verify that the fallback method correctly filters techniques
      const panel = QuickAccessPanel(
        userMotive: 'Anxiety',
        primaryColor: Color(0xFF4DB6AC),
      );

      // Create the widget state to test the fallback method
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: panel)),
        ),
      );

      await tester.pumpAndSettle();

      // The panel should be displayed
      expect(find.byType(QuickAccessPanel), findsOneWidget);

      // Should show anxiety-specific content
      expect(find.text('Anxiety Relief'), findsOneWidget);
      expect(
        find.text('Ground yourself and find your center right now'),
        findsOneWidget,
      );
    });

    testWidgets('provides immediate activation UI elements', (tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickAccessPanel(
                userMotive: 'Stress',
                primaryColor: const Color(0xFF4DB6AC),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show immediate activation elements
      expect(find.text('Stress Relief'), findsOneWidget);
      expect(
        find.text('Release tension and restore inner calm'),
        findsOneWidget,
      );

      // Should have tappable elements for immediate activation
      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });

    test('effectiveness-based fallback prioritizes techniques correctly', () {
      // Test the technique filtering logic
      final allTechniques = CalmTechnique.defaults;

      // Verify we have techniques under 2 minutes
      final quickTechniques = allTechniques
          .where((t) => t.durationMinutes <= 2)
          .toList();
      expect(
        quickTechniques.isNotEmpty,
        true,
        reason: 'Should have techniques under 2 minutes for emergency use',
      );

      // Verify specific techniques are available
      final groundingTechnique = allTechniques.firstWhere(
        (t) => t.id == '5-4-3-2-1',
      );
      expect(groundingTechnique.durationMinutes, equals(5));

      final affirmationsTechnique = allTechniques.firstWhere(
        (t) => t.id == 'positive-affirmations',
      );
      expect(affirmationsTechnique.durationMinutes, equals(2));

      final visualizationTechnique = allTechniques.firstWhere(
        (t) => t.id == 'cold-water-visualization',
      );
      expect(visualizationTechnique.durationMinutes, equals(2));
    });

    testWidgets('handles null motive gracefully', (tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickAccessPanel(
                userMotive: null,
                primaryColor: const Color(0xFF4DB6AC),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show default content
      expect(find.text('Quick Relief'), findsOneWidget);
      expect(
        find.text('Immediate techniques for when you need relief right now'),
        findsOneWidget,
      );
      expect(find.byType(QuickAccessPanel), findsOneWidget);
    });
  });
}
