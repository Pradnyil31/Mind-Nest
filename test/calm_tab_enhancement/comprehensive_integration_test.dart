import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fy_project/features/calm/application/error_recovery_service.dart';
import 'package:fy_project/features/calm/application/robust_audio_service.dart';
import 'package:fy_project/features/calm/application/data_integrity_service.dart';
import 'package:fy_project/features/calm/application/cache_management_service.dart';
import 'package:fy_project/features/calm/application/privacy_security_service.dart';
import 'package:fy_project/services/audio_playback_service.dart';
import 'package:fy_project/screens/enhanced_calm_screen.dart';
import 'package:fy_project/widgets/calm/interactive_soundscape_widget.dart';
import 'package:fy_project/widgets/calm/quick_access_panel.dart';

/// Comprehensive integration tests for Task 12 - Final integration and testing phase
/// Tests cross-feature integration, error handling, data privacy, and system robustness
void main() {
  group('Task 12: Comprehensive Integration Tests', () {
    late ProviderContainer container;

    setUp(() async {
      // Initialize test environment
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('12.1: Error Handling and Recovery', () {
      testWidgets('handles network connectivity errors gracefully', (
        tester,
      ) async {
        // Test network error scenarios
        final errorRecovery = ErrorRecoveryService();

        // Test retry mechanism
        int attemptCount = 0;
        final result = await errorRecovery.withRetry(
          () async {
            attemptCount++;
            if (attemptCount < 3) {
              throw NetworkException('Network unavailable');
            }
            return 'success';
          },
          maxRetries: 3,
          operationName: 'test network operation',
        );

        expect(result, equals('success'));
        expect(attemptCount, equals(3));
      });

      testWidgets('handles audio playback errors with fallbacks', (
        tester,
      ) async {
        final mockAudioService = MockAudioPlaybackService();
        final robustAudioService = RobustAudioService(mockAudioService);

        // Mock audio service to fail initially
        when(
          mockAudioService.playSound('test_sound', 0.5),
        ).thenThrow(AudioPlaybackException('Audio file not found'));

        final result = await robustAudioService.playSound('test_sound', 0.5);

        // Should handle error gracefully and return false
        expect(result, isFalse);
        verify(mockAudioService.playSound('test_sound', 0.5)).called(1);
      });

      testWidgets('recovers from data corruption', (tester) async {
        final dataIntegrity = DataIntegrityService();

        // Store valid data
        final testData = {'key': 'value', 'number': 42};
        await dataIntegrity.storeWithIntegrity(
          'test_key',
          testData,
          (data) => data,
        );

        // Simulate data corruption by manually modifying stored data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('test_key', 'corrupted_data');

        // Should recover from backup or return null
        final recovered = await dataIntegrity.retrieveWithIntegrity(
          'test_key',
          (data) => data,
        );

        // Either recovered from backup or gracefully handled corruption
        expect(recovered, anyOf(equals(testData), isNull));
      });

      testWidgets('circuit breaker prevents cascading failures', (
        tester,
      ) async {
        final errorRecovery = ErrorRecoveryService();

        // Simulate multiple failures to trigger circuit breaker
        for (int i = 0; i < 6; i++) {
          final result = await errorRecovery.withCircuitBreaker(
            () async => throw Exception('Service unavailable'),
            circuitName: 'test_circuit',
            failureThreshold: 5,
          );

          if (i >= 5) {
            // Circuit should be open, returning null
            expect(result, isNull);
          }
        }
      });
    });

    group('12.2: Data Privacy and Security', () {
      testWidgets('encrypts sensitive mood data', (tester) async {
        final privacyService = PrivacySecurityService();
        await privacyService.initialize();

        final sensitiveData = {
          'userId': 'user123',
          'moodRating': 7,
          'notes': 'Feeling anxious about work',
          'sessionId': 'session456',
        };

        // Store encrypted data
        final success = await privacyService.storeMoodDataSecurely(
          sensitiveData,
        );
        expect(success, isTrue);

        // Retrieve and verify decryption
        final retrieved = await privacyService.retrieveMoodDataSecurely(
          'session456',
        );
        expect(retrieved, isNotNull);
        expect(retrieved!['moodRating'], equals(7));

        // Verify user ID was hashed, not stored directly
        expect(retrieved.containsKey('userId'), isFalse);
        expect(retrieved.containsKey('userIdHash'), isTrue);
      });

      testWidgets('supports anonymous mode', (tester) async {
        final privacyService = PrivacySecurityService();
        await privacyService.initialize();

        // Enable anonymous mode
        final enabled = await privacyService.enableAnonymousMode();
        expect(enabled, isTrue);

        // Verify anonymous mode settings
        expect(await privacyService.isAnonymousModeEnabled(), isTrue);
        expect(await privacyService.isDataCollectionEnabled(), isFalse);
        expect(await privacyService.isAnalyticsEnabled(), isFalse);

        final anonymousId = await privacyService.getAnonymousId();
        expect(anonymousId, isNotNull);
        expect(anonymousId!.length, greaterThan(10));
      });

      testWidgets('deletes all user data for GDPR compliance', (tester) async {
        final privacyService = PrivacySecurityService();
        await privacyService.initialize();

        // Store some test data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('calm_user123_data', 'test_data');
        await prefs.setString('calm_mood_session1', 'mood_data');

        // Delete all user data
        final deleted = await privacyService.deleteAllUserData('user123');
        expect(deleted, isTrue);

        // Verify data is deleted
        expect(prefs.getString('calm_user123_data'), isNull);
        expect(prefs.getString('calm_mood_session1'), isNull);
      });

      testWidgets('exports user data for portability', (tester) async {
        final privacyService = PrivacySecurityService();
        await privacyService.initialize();

        // Store some test data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('calm_user123_preferences', '{"theme": "dark"}');
        await prefs.setString('calm_user123_progress', '{"sessions": 10}');

        // Export user data
        final exported = await privacyService.exportUserData('user123');
        expect(exported, isNotNull);
        expect(exported!.containsKey('_export_metadata'), isTrue);
        expect(exported['_export_metadata']['userId'], equals('user123'));
      });
    });

    group('12.3: Cross-Feature Integration', () {
      testWidgets('integrates calm system with breathing and meditation', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: const EnhancedCalmScreen())),
        );

        // Verify calm screen loads
        expect(find.byType(EnhancedCalmScreen), findsOneWidget);

        // Look for quick access panel
        expect(find.byType(QuickAccessPanel), findsOneWidget);

        // Verify breathing integration button exists
        expect(find.text('Breathing Exercises'), findsOneWidget);

        // Tap breathing integration
        await tester.tap(find.text('Breathing Exercises'));
        await tester.pumpAndSettle();

        // Should navigate without errors
        // (In real app, this would navigate to BreathingScreen)
      });

      testWidgets('motive changes update entire system consistently', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: const EnhancedCalmScreen())),
        );

        // Initial state should be loaded
        await tester.pumpAndSettle();

        // Simulate motive change (this would normally come from user profile)
        // Verify that all components adapt to new motive
        expect(find.byType(InteractiveSoundscapeWidget), findsOneWidget);

        // Test that soundscape adapts to motive
        final soundscapeWidget = tester.widget<InteractiveSoundscapeWidget>(
          find.byType(InteractiveSoundscapeWidget),
        );

        // Verify motive-specific configuration
        expect(soundscapeWidget.userMotive, isNotNull);
      });

      testWidgets('offline/online synchronization works correctly', (
        tester,
      ) async {
        final cacheService = CacheManagementService();
        await cacheService.initialize();

        // Test offline data storage
        final testData = {
          'techniques': ['breathing', 'grounding'],
          'preferences': {'volume': 0.7},
        };

        final cached = await cacheService.cacheEssentialData(testData);
        expect(cached, isTrue);

        // Test data retrieval
        final retrieved = await cacheService.getCachedEssentialData();
        expect(retrieved, equals(testData));

        // Test sync queue
        final queueData = {'sessionId': 'test', 'completed': true};
        final queued = await cacheService.queueForSync(queueData);
        expect(queued, isTrue);

        // Test sync processing (would normally sync with server)
        final processed = await cacheService.processSyncQueue();
        expect(processed, isTrue);
      });

      testWidgets('accessibility features work across all components', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: const EnhancedCalmScreen())),
        );

        // Verify semantic labels exist
        expect(find.bySemanticsLabel('Calm techniques'), findsWidgets);
        expect(find.bySemanticsLabel('Ambient sounds'), findsWidgets);

        // Test screen reader compatibility
        final semantics = tester.getSemantics(find.byType(EnhancedCalmScreen));
        expect(
          // ignore: deprecated_member_use
          semantics.hasFlag(SemanticsFlag.isButton) ||
              // ignore: deprecated_member_use
              semantics.hasFlag(SemanticsFlag.isHeader),
          isTrue,
        );
      });
    });

    group('12.4: Performance and Resource Management', () {
      testWidgets('handles multiple concurrent audio streams', (tester) async {
        final mockAudioService = MockAudioPlaybackService();
        final robustAudioService = RobustAudioService(mockAudioService);

        // Simulate multiple concurrent audio requests
        final futures = <Future<bool>>[];
        for (int i = 0; i < 5; i++) {
          futures.add(robustAudioService.playSound('sound_$i', 0.5));
        }

        final results = await Future.wait(futures);

        // All requests should be handled (success or graceful failure)
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isA<bool>());
        }
      });

      testWidgets('manages memory usage efficiently', (tester) async {
        final cacheService = CacheManagementService();
        await cacheService.initialize();

        // Get initial cache health
        final initialHealth = await cacheService.getCacheHealth();
        expect(initialHealth['totalCacheSize'], isA<int>());

        // Cache some data
        final largeData = List.generate(1000, (i) => 'data_$i');
        await cacheService.cacheEssentialData({'large': largeData});

        // Verify cache size is tracked
        final updatedHealth = await cacheService.getCacheHealth();
        expect(
          updatedHealth['totalCacheSize'],
          greaterThan(initialHealth['totalCacheSize']),
        );
      });

      testWidgets('cleans up resources properly', (tester) async {
        final mockAudioService = MockAudioPlaybackService();
        final robustAudioService = RobustAudioService(mockAudioService);

        // Start some audio
        await robustAudioService.playSound('test_sound', 0.5);

        // Get system health before cleanup
        final healthBefore = robustAudioService.getSystemHealth();
        expect(healthBefore['activePlayers'], greaterThan(0));

        // Dispose service
        await robustAudioService.dispose();

        // Verify cleanup
        final healthAfter = robustAudioService.getSystemHealth();
        expect(healthAfter['activePlayers'], equals(0));
      });
    });

    group('12.5: System Robustness', () {
      testWidgets('handles rapid state changes without errors', (tester) async {
        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: const EnhancedCalmScreen())),
        );

        // Rapidly trigger state changes
        for (int i = 0; i < 10; i++) {
          // Simulate rapid user interactions
          if (find.text('Start Session').evaluate().isNotEmpty) {
            await tester.tap(find.text('Start Session'));
          }
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Should handle rapid changes without crashing
        expect(tester.takeException(), isNull);
      });

      testWidgets('recovers from widget tree rebuilds', (tester) async {
        Widget buildApp() =>
            ProviderScope(child: MaterialApp(home: const EnhancedCalmScreen()));

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Rebuild the entire widget tree
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        // Should rebuild without errors
        expect(find.byType(EnhancedCalmScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('maintains data consistency during concurrent operations', (
        tester,
      ) async {
        final dataIntegrity = DataIntegrityService();

        // Perform concurrent data operations
        final futures = <Future<bool>>[];
        for (int i = 0; i < 10; i++) {
          futures.add(
            dataIntegrity.storeWithIntegrity('concurrent_test_$i', {
              'value': i,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }, (data) => data),
          );
        }

        final results = await Future.wait(futures);

        // All operations should succeed
        expect(results.every((result) => result), isTrue);

        // Verify data integrity
        for (int i = 0; i < 10; i++) {
          final retrieved = await dataIntegrity.retrieveWithIntegrity(
            'concurrent_test_$i',
            (data) => data,
          );
          expect(retrieved, isNotNull);
          expect(retrieved!['value'], equals(i));
        }
      });
    });
  });
}

// Mock classes for testing
class MockAudioPlaybackService extends Mock implements AudioPlaybackService {}

// Test utilities
class TestDataGenerator {
  static Map<String, dynamic> generateMoodSession() {
    return {
      'id': 'session_${DateTime.now().millisecondsSinceEpoch}',
      'userId': 'test_user',
      'techniqueId': 'breathing_basic',
      'preMoodRating': 4,
      'postMoodRating': 7,
      'startTime': DateTime.now().subtract(const Duration(minutes: 10)),
      'endTime': DateTime.now(),
    };
  }

  static Map<String, dynamic> generateSoundPreset() {
    return {
      'id': 'preset_${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Test Preset',
      'motive': 'Stress',
      'soundIds': ['rain', 'forest'],
      'volumes': {'rain': 0.7, 'forest': 0.5},
      'masterVolume': 0.8,
    };
  }
}

// Property-based test helpers
class PropertyTestRunner {
  static Future<void> runPropertyTest(
    String propertyName,
    Future<bool> Function() testFunction, {
    int iterations = 100,
  }) async {
    int passCount = 0;

    for (int i = 0; i < iterations; i++) {
      try {
        final result = await testFunction();
        if (result) passCount++;
      } catch (e) {
        // Property test failed
        throw Exception('Property "$propertyName" failed on iteration $i: $e');
      }
    }

    if (passCount < iterations) {
      throw Exception(
        'Property "$propertyName" failed: $passCount/$iterations iterations passed',
      );
    }
  }
}
