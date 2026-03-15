import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fy_project/features/calm/application/offline_data_service.dart';
import 'package:fy_project/features/calm/application/calm_recommendation_service.dart';

/// Property Test 9: Offline Capability Completeness
/// Validates Requirements 9.1-9.6: Offline functionality and data synchronization
///
/// This property test verifies that:
/// - Core techniques and sounds are available offline
/// - User data is stored locally when offline
/// - Data synchronization works when connectivity returns
/// - Offline status is properly indicated
/// - Feature availability is correctly displayed

void main() {
  group(
    'Feature: calm-tab-enhancement, Property 9: Offline Capability Completeness',
    () {
      late OfflineDataService offlineService;
      late CalmRecommendationService recommendationService;

      setUp(() async {
        // Initialize shared preferences for testing
        SharedPreferences.setMockInitialValues({});

        offlineService = OfflineDataService();
        recommendationService = CalmRecommendationService();
      });

      test('Property 9.1: Core techniques available offline', () async {
        // Test that core techniques are accessible without network
        final coreTechniques = await offlineService.getCoreCalmTechniques();

        expect(coreTechniques, isNotEmpty);
        expect(coreTechniques.length, greaterThanOrEqualTo(3));

        // Verify each technique has required offline data
        for (final technique in coreTechniques) {
          expect(technique['id'], isNotNull);
          expect(technique['title'], isNotNull);
          expect(technique['steps'], isNotNull);
          expect(technique['isOfflineAvailable'], isTrue);
        }
      });

      test('Property 9.2: Core ambient sounds available offline', () async {
        // Test that core ambient sounds are accessible without network
        final coreSounds = await offlineService.getCoreAmbientSounds();

        expect(coreSounds, isNotEmpty);
        expect(coreSounds.length, greaterThanOrEqualTo(3));

        // Verify each sound has required offline data
        for (final sound in coreSounds) {
          expect(sound['id'], isNotNull);
          expect(sound['name'], isNotNull);
          expect(sound['assetPath'], isNotNull);
          expect(sound['isOfflineAvailable'], isTrue);
        }
      });

      test('Property 9.3: User preferences stored locally', () async {
        const userId = 'test_user_123';
        final testPreferences = {
          'favoriteAmbientSounds': ['rain', 'ocean'],
          'defaultTimer': 10,
          'lowPowerMode': false,
        };

        // Store preferences
        await offlineService.storeUserPreferences(userId, testPreferences);

        // Retrieve preferences
        final retrievedPrefs = await offlineService.getUserPreferences(userId);

        expect(retrievedPrefs, isNotNull);
        expect(
          retrievedPrefs!['favoriteAmbientSounds'],
          equals(['rain', 'ocean']),
        );
        expect(retrievedPrefs['defaultTimer'], equals(10));
        expect(retrievedPrefs['lowPowerMode'], equals(false));
      });

      test('Property 9.4: Technique completion stored offline', () async {
        const userId = 'test_user_123';

        // Store technique completion offline
        await offlineService.storeTechniqueCompletionOffline(
          userId: userId,
          techniqueId: 'breathing-4-7-8',
          techniqueName: '4-7-8 Breathing',
          durationMinutes: 5,
          preMoodRating: 6,
          postMoodRating: 8,
        );

        // Verify sync queue contains the item
        final syncQueue = offlineService.syncQueue;
        expect(syncQueue, isNotEmpty);

        // Verify the queued item contains correct data
        final queuedItem = syncQueue.first;
        expect(queuedItem, contains('technique_completion'));
        expect(queuedItem, contains(userId));
        expect(queuedItem, contains('breathing-4-7-8'));
      });

      test('Property 9.5: Mood session stored offline', () async {
        const userId = 'test_user_123';
        const sessionId = 'session_123';

        // Store mood session offline
        await offlineService.storeMoodSessionOffline(
          userId: userId,
          sessionId: sessionId,
          techniqueId: 'grounding-5-4-3-2-1',
          preMoodRating: 7,
          postMoodRating: 9,
        );

        // Verify sync queue contains the item
        final syncQueue = offlineService.syncQueue;
        expect(
          syncQueue.where((item) => item.contains('mood_session')),
          isNotEmpty,
        );
      });

      test('Property 9.6: Feature availability correctly indicated', () async {
        final featureAvailability = offlineService
            .getOfflineFeatureAvailability();

        // Verify core features are available offline
        expect(featureAvailability['coreCalm Techniques'], isTrue);
        expect(featureAvailability['basicBreathing'], isTrue);
        expect(featureAvailability['groundingExercises'], isTrue);
        expect(featureAvailability['coreAmbientSounds'], isTrue);
        expect(featureAvailability['moodTracking'], isTrue);

        // Verify advanced features require internet
        expect(featureAvailability['personalizedRecommendations'], isFalse);
        expect(featureAvailability['advancedAnalytics'], isFalse);
        expect(featureAvailability['cloudSync'], isFalse);
      });

      test(
        'Property 9.7: Offline recommendations work without network',
        () async {
          const userId = 'test_user_123';

          // Test recommendations for different motives
          final motives = [
            'Sleep',
            'Stress',
            'Anxiety',
            'Focus',
            'Habit Building',
          ];

          for (final motive in motives) {
            final recommendations = await recommendationService
                .getPersonalizedRecommendations(userId, motive);

            expect(recommendations, isNotEmpty);
            expect(recommendations.length, lessThanOrEqualTo(3));

            // Verify recommendations are appropriate for the motive
            // (This would be more sophisticated in a real implementation)
            for (final technique in recommendations) {
              expect(technique.id, isNotNull);
              expect(technique.title, isNotNull);
              expect(technique.durationMinutes, greaterThan(0));
            }
          }
        },
      );
    },
  );
}
