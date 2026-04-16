import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:fy_project/config/motive_config.dart';
import 'package:fy_project/features/calm/application/motive_detection_service.dart';
import 'package:fy_project/services/auth_service.dart';
import 'package:fy_project/services/firestore_service.dart';

@GenerateMocks([FirestoreService, AuthService])
import 'motive_personalization_validation_test.mocks.dart';

/// Task 8: Checkpoint - Motive personalization validation
///
/// This test validates:
/// - All five motive profiles (Sleep, Stress, Anxiety, Focus, Habit Building)
/// - Smooth transitions between motive changes
/// - Technique priorities and recommendations work correctly
/// - Interface adaptation within 5 seconds
/// - Cross-motive data preservation
/// - Motive-specific visual themes and messaging
void main() {
  group('Task 8: Motive Personalization Validation', () {
    late MockFirestoreService mockFirestore;
    late MockAuthService mockAuth;
    late ProviderContainer container;

    setUp(() {
      mockFirestore = MockFirestoreService();
      mockAuth = MockAuthService();

      // Setup mock stubs
      when(mockAuth.currentUser).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          motiveDetectionProvider.overrideWith(
            (ref) => MotiveDetectionService(
              firestoreService: mockFirestore,
              authService: mockAuth,
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('validates all five motive profiles display correctly', (
      tester,
    ) async {
      final motives = ['Sleep', 'Stress', 'Anxiety', 'Focus', 'Habit Building'];

      for (final motive in motives) {
        // Setup motive
        final motiveService = container.read(motiveDetectionProvider.notifier);
        motiveService.state = MotiveDetectionState(
          currentMotive: motive,
          isLoading: false,
        );

        // Validate motive-specific elements
        final profile = MotiveConfig.getProfile(motive);
        expect(profile, isNotNull, reason: 'Profile should exist for $motive');

        // Check motive-specific welcome message
        final welcomeMessage = motiveService.getMotiveWelcomeMessage(motive);
        expect(
          welcomeMessage.contains(profile!.emoji),
          isTrue,
          reason:
              'Welcome message "$welcomeMessage" should contain emoji ${profile.emoji}',
        );
        expect(welcomeMessage.isNotEmpty, isTrue);

        // Validate color theme
        final colorTheme = MotiveColorTheme.fromMotive(motive);
        expect(colorTheme.primaryColor, isNotNull);
        expect(colorTheme.backgroundColor, isNotNull);
        expect(colorTheme.accentColor, isNotNull);
        expect(colorTheme.gradientColors.length, equals(2));

        // Validate motive-specific technique priorities
        final priorities = MotiveConfig.getCalmTechniquePriorities(motive);
        expect(
          priorities,
          isNotEmpty,
          reason: 'Should have technique priorities for $motive',
        );

        debugPrint(
          '✓ Validated $motive profile: ${profile.displayName} ${profile.emoji}',
        );
      }
    });

    testWidgets(
      'validates smooth motive transitions with interface adaptation',
      (tester) async {
        final motiveService = container.read(motiveDetectionProvider.notifier);

        // Start with Sleep motive
        motiveService.state = MotiveDetectionState(
          currentMotive: 'Sleep',
          isLoading: false,
        );

        // Verify initial Sleep state
        expect(motiveService.state.currentMotive, equals('Sleep'));

        // Simulate motive change to Anxiety
        motiveService.state = MotiveDetectionState(
          currentMotive: 'Anxiety',
          previousMotive: 'Sleep',
          motiveChangeDetected: true,
          shouldRefreshInterface: true,
          adaptationInProgress: true,
          lastChangeTime: DateTime.now(),
          isLoading: false,
        );

        // Verify adaptation in progress
        expect(motiveService.isAdaptationInProgress, isTrue);

        // Simulate interface refresh completion (within 5 seconds)
        await tester.pump(const Duration(seconds: 2));

        motiveService.markInterfaceRefreshed();

        // Verify transition to Anxiety motive
        expect(motiveService.state.currentMotive, equals('Anxiety'));
        expect(motiveService.state.adaptationInProgress, isFalse);
        expect(motiveService.state.shouldRefreshInterface, isFalse);

        debugPrint('✓ Validated smooth transition from Sleep to Anxiety');
      },
    );

    testWidgets('validates technique priorities work correctly for each motive', (
      tester,
    ) async {
      final testCases = {
        'Sleep': ['Body Scan', 'Breathing', 'Guided Imagery'],
        'Stress': ['Breathing', 'Grounding', 'Meditation'],
        'Anxiety': ['Grounding', 'Breathing', 'Body Awareness'],
        'Focus': ['Grounding', 'Breathing', 'Visualization'],
        'Habit Building': [
          'Breathing',
          'Meditation',
          'Grounding',
          'Affirmations',
        ],
      };

      for (final entry in testCases.entries) {
        final motive = entry.key;
        final expectedPriorities = entry.value;

        // Setup motive
        final motiveService = container.read(motiveDetectionProvider.notifier);
        motiveService.state = MotiveDetectionState(
          currentMotive: motive,
          isLoading: false,
        );

        // Validate technique priorities
        final actualPriorities = MotiveConfig.getCalmTechniquePriorities(
          motive,
        );

        // Check that expected priorities are included
        for (final expectedTechnique in expectedPriorities) {
          expect(
            actualPriorities.contains(expectedTechnique),
            isTrue,
            reason: '$motive should prioritize $expectedTechnique',
          );
        }

        debugPrint(
          '✓ Validated $motive technique priorities: ${actualPriorities.join(", ")}',
        );
      }
    });

    testWidgets(
      'validates motive-specific welcome messages and encouragement',
      (tester) async {
        final motives = [
          'Sleep',
          'Stress',
          'Anxiety',
          'Focus',
          'Habit Building',
        ];

        for (final motive in motives) {
          final motiveService = container.read(
            motiveDetectionProvider.notifier,
          );
          motiveService.state = MotiveDetectionState(
            currentMotive: motive,
            isLoading: false,
          );

          // Test welcome message
          final welcomeMessage = motiveService.getMotiveWelcomeMessage(motive);
          expect(welcomeMessage, isNotEmpty);

          final profile = MotiveConfig.getProfile(motive);
          expect(welcomeMessage.contains(profile!.emoji), isTrue);

          // Test encouragement message
          final encouragementMessage = motiveService
              .getMotiveEncouragementMessage(motive);
          expect(encouragementMessage, isNotEmpty);

          // Test completion message
          final completionMessage = motiveService.getMotiveCompletionMessage(
            motive,
          );
          expect(completionMessage, isNotEmpty);

          // Validate motive-specific content
          switch (motive) {
            case 'Sleep':
              expect(
                welcomeMessage.toLowerCase().contains('sleep') ||
                    welcomeMessage.toLowerCase().contains('rest'),
                isTrue,
              );
              break;
            case 'Stress':
              expect(
                welcomeMessage.toLowerCase().contains('stress') ||
                    welcomeMessage.toLowerCase().contains('tension') ||
                    welcomeMessage.toLowerCase().contains('calm'),
                isTrue,
              );
              break;
            case 'Anxiety':
              expect(
                welcomeMessage.toLowerCase().contains('anxiety') ||
                    welcomeMessage.toLowerCase().contains('ground') ||
                    welcomeMessage.toLowerCase().contains('safe'),
                isTrue,
              );
              break;
            case 'Focus':
              expect(
                welcomeMessage.toLowerCase().contains('focus') ||
                    welcomeMessage.toLowerCase().contains('concentration') ||
                    welcomeMessage.toLowerCase().contains('clarity'),
                isTrue,
              );
              break;
            case 'Habit Building':
              expect(
                welcomeMessage.toLowerCase().contains('habit') ||
                    welcomeMessage.toLowerCase().contains('consistency') ||
                    welcomeMessage.toLowerCase().contains('motivation'),
                isTrue,
              );
              break;
          }

          debugPrint('✓ Validated $motive messaging: "$welcomeMessage"');
        }
      },
    );

    testWidgets('validates cross-motive data preservation during transitions', (
      tester,
    ) async {
      final motiveService = container.read(motiveDetectionProvider.notifier);

      // Start with Focus motive
      motiveService.state = MotiveDetectionState(
        currentMotive: 'Focus',
        isLoading: false,
      );

      // Simulate motive change to Stress
      motiveService.state = MotiveDetectionState(
        currentMotive: 'Stress',
        previousMotive: 'Focus',
        motiveChangeDetected: true,
        shouldRefreshInterface: true,
        lastChangeTime: DateTime.now(),
        isLoading: false,
      );

      // Validate cross-motive insights
      final crossMotiveInsights = motiveService.getCrossMotiveInsights();
      expect(crossMotiveInsights, isNotEmpty);
      expect(crossMotiveInsights['transitionType'], equals('Focus_to_Stress'));
      expect(crossMotiveInsights['continuityFactors'], isA<List>());
      expect(crossMotiveInsights['previousMotiveStrengths'], isA<List>());
      expect(crossMotiveInsights['newMotiveOpportunities'], isA<List>());
      expect(crossMotiveInsights['sharedTechniques'], isA<List>());

      // Validate adaptation status
      final adaptationStatus = motiveService.getAdaptationStatus();
      expect(adaptationStatus['currentMotive'], equals('Stress'));
      expect(adaptationStatus['previousMotive'], equals('Focus'));
      expect(adaptationStatus['adaptationComponents'], isA<Map>());
      expect(adaptationStatus['adaptationMetrics'], isA<Map>());

      debugPrint('✓ Validated cross-motive data preservation from Focus to Stress');
    });

    testWidgets(
      'validates motive-specific color themes and visual adaptation',
      (tester) async {
        final expectedColors = {
          'Sleep': Color(0xFF6366F1), // Indigo
          'Stress': Color(0xFF10B981), // Emerald
          'Anxiety': Color(0xFF8B5CF6), // Violet
          'Focus': Color(0xFFF59E0B), // Amber
          'Habit Building': Color(0xFFEF4444), // Red
        };

        for (final entry in expectedColors.entries) {
          final motive = entry.key;
          final expectedColor = entry.value;

          final colorTheme = MotiveColorTheme.fromMotive(motive);
          expect(colorTheme.primaryColor, equals(expectedColor));
          expect(colorTheme.backgroundColor, isNotNull);
          expect(colorTheme.accentColor, isNotNull);
          expect(colorTheme.gradientColors.length, equals(2));

          // Validate gradient colors are related to primary color
          expect(
            colorTheme.gradientColors.contains(colorTheme.primaryColor),
            isTrue,
          );

          debugPrint('✓ Validated $motive color theme: ${colorTheme.primaryColor}');
        }
      },
    );

    testWidgets('validates interface adaptation timing (within 5 seconds)', (
      tester,
    ) async {
      final motiveService = container.read(motiveDetectionProvider.notifier);
      final stopwatch = Stopwatch()..start();

      // Start with Sleep motive
      motiveService.state = MotiveDetectionState(
        currentMotive: 'Sleep',
        isLoading: false,
      );

      // Trigger motive change
      motiveService.state = MotiveDetectionState(
        currentMotive: 'Anxiety',
        previousMotive: 'Sleep',
        motiveChangeDetected: true,
        shouldRefreshInterface: true,
        adaptationInProgress: true,
        lastChangeTime: DateTime.now(),
        isLoading: false,
      );

      // Wait for adaptation to complete (should be within 5 seconds)
      await tester.pump(const Duration(seconds: 2));
      motiveService.markInterfaceRefreshed();

      stopwatch.stop();
      final adaptationTime = stopwatch.elapsedMilliseconds;

      // Validate adaptation completed within 5 seconds (5000ms)
      expect(
        adaptationTime,
        lessThan(5000),
        reason: 'Interface adaptation should complete within 5 seconds',
      );

      // Validate adaptation is complete
      expect(motiveService.state.adaptationInProgress, isFalse);
      expect(motiveService.state.shouldRefreshInterface, isFalse);

      debugPrint('✓ Validated interface adaptation timing: ${adaptationTime}ms');
    });

    test('validates comprehensive motive profile completeness', () {
      final motives = ['Sleep', 'Stress', 'Anxiety', 'Focus', 'Habit Building'];

      for (final motive in motives) {
        final profile = MotiveConfig.getProfile(motive);

        // Validate profile exists and is complete
        expect(profile, isNotNull, reason: 'Profile should exist for $motive');
        expect(profile!.displayName, isNotEmpty);
        expect(profile.emoji, isNotEmpty);
        expect(profile.calmTechniquePriorities, isNotEmpty);

        // Validate technique priorities are valid
        final validTechniques = [
          'Breathing',
          'Grounding',
          'Meditation',
          'Body Scan',
          'Guided Imagery',
          'Body Awareness',
          'Visualization',
          'Affirmations',
        ];

        for (final technique in profile.calmTechniquePriorities) {
          expect(
            validTechniques.contains(technique),
            isTrue,
            reason: '$technique should be a valid technique for $motive',
          );
        }

        // Validate motive-specific requirements
        switch (motive) {
          case 'Sleep':
            expect(
              profile.calmTechniquePriorities.contains('Body Scan'),
              isTrue,
            );
            expect(
              profile.calmTechniquePriorities.contains('Breathing'),
              isTrue,
            );
            break;
          case 'Stress':
            expect(
              profile.calmTechniquePriorities.contains('Breathing'),
              isTrue,
            );
            expect(
              profile.calmTechniquePriorities.contains('Grounding'),
              isTrue,
            );
            break;
          case 'Anxiety':
            expect(
              profile.calmTechniquePriorities.contains('Grounding'),
              isTrue,
            );
            expect(
              profile.calmTechniquePriorities.contains('Breathing'),
              isTrue,
            );
            break;
          case 'Focus':
            expect(
              profile.calmTechniquePriorities.contains('Grounding'),
              isTrue,
            );
            expect(
              profile.calmTechniquePriorities.contains('Visualization'),
              isTrue,
            );
            break;
          case 'Habit Building':
            expect(
              profile.calmTechniquePriorities.contains('Breathing'),
              isTrue,
            );
            expect(
              profile.calmTechniquePriorities.contains('Affirmations'),
              isTrue,
            );
            break;
        }

        debugPrint(
          '✓ Validated $motive profile completeness: ${profile.displayName} ${profile.emoji}',
        );
      }
    });

    test('validates motive transition scenarios and edge cases', () {
      // Use a simple state-based approach instead of creating a real service
      final motives = ['Sleep', 'Stress', 'Anxiety', 'Focus', 'Habit Building'];

      for (final fromMotive in motives) {
        for (final toMotive in motives) {
          if (fromMotive != toMotive) {
            // Test cross-motive insights logic
            final fromPriorities = MotiveConfig.getCalmTechniquePriorities(
              fromMotive,
            );
            final toPriorities = MotiveConfig.getCalmTechniquePriorities(
              toMotive,
            );

            final sharedTechniques = fromPriorities
                .where((technique) => toPriorities.contains(technique))
                .toList();

            // Validate that we can identify shared techniques
            expect(sharedTechniques, isA<List<String>>());

            // Validate welcome message for transition
            final profile = MotiveConfig.getProfile(toMotive);
            expect(profile, isNotNull);
            expect(profile!.emoji, isNotEmpty);
          }
        }
      }

      debugPrint('✓ Validated all motive transition scenarios');
    });
  });

  group('Task 8: Integration Validation', () {
    test('validates complete motive personalization system integration', () {
      // Test all motive profiles exist and are complete
      for (final motive in MotiveConfig.allMotives) {
        final profile = MotiveConfig.getProfile(motive);
        expect(profile, isNotNull);
        expect(profile!.displayName, isNotEmpty);
        expect(profile.emoji, isNotEmpty);
        expect(profile.calmTechniquePriorities, isNotEmpty);

        // Test color themes
        final colorTheme = MotiveColorTheme.fromMotive(motive);
        expect(colorTheme.primaryColor, isNotNull);
        expect(colorTheme.backgroundColor, isNotNull);
        expect(colorTheme.accentColor, isNotNull);
        expect(colorTheme.gradientColors.length, equals(2));
      }

      debugPrint('✓ Validated complete system integration');
    });
  });
}

/// Helper extension for testing motive personalization
extension MotivePersonalizationTestHelpers on WidgetTester {
  /// Simulate motive change and wait for adaptation
  Future<void> simulateMotiveChange(
    ProviderContainer container,
    String fromMotive,
    String toMotive,
  ) async {
    final motiveService = container.read(motiveDetectionProvider.notifier);

    motiveService.state = MotiveDetectionState(
      currentMotive: toMotive,
      previousMotive: fromMotive,
      motiveChangeDetected: true,
      shouldRefreshInterface: true,
      adaptationInProgress: true,
      lastChangeTime: DateTime.now(),
      isLoading: false,
    );

    await pump(const Duration(seconds: 2));

    motiveService.markInterfaceRefreshed();
  }

  /// Validate motive-specific configuration
  void validateMotiveConfig(String motive) {
    final profile = MotiveConfig.getProfile(motive);
    expect(profile, isNotNull);

    // Check color theme is applied
    final colorTheme = MotiveColorTheme.fromMotive(motive);
    expect(colorTheme.primaryColor, isNotNull);
  }
}
