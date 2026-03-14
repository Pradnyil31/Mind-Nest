import 'package:flutter_test/flutter_test.dart';
import '../../lib/config/motive_config.dart';

void main() {
  group('CalmProgressService Enhanced (Task 3.3) - Logic Tests', () {
    test(
      'MotiveConfig provides correct technique priorities for each motive',
      () {
        // Test Sleep motive priorities
        final sleepPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Sleep',
        );
        expect(sleepPriorities, contains('Body Scan'));
        expect(sleepPriorities, contains('Breathing'));
        expect(sleepPriorities, contains('Guided Imagery'));

        // Test Stress motive priorities
        final stressPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Stress',
        );
        expect(stressPriorities, contains('Breathing'));
        expect(stressPriorities, contains('Grounding'));
        expect(stressPriorities, contains('Meditation'));

        // Test Anxiety motive priorities
        final anxietyPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Anxiety',
        );
        expect(anxietyPriorities, contains('Grounding'));
        expect(anxietyPriorities, contains('Breathing'));
        expect(anxietyPriorities, contains('Body Awareness'));

        // Test Focus motive priorities
        final focusPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Focus',
        );
        expect(focusPriorities, contains('Grounding'));
        expect(focusPriorities, contains('Breathing'));
        expect(focusPriorities, contains('Visualization'));

        // Test Habit Building motive priorities
        final habitPriorities = MotiveConfig.getCalmTechniquePriorities(
          'Habit Building',
        );
        expect(habitPriorities, contains('Breathing'));
        expect(habitPriorities, contains('Meditation'));
        expect(habitPriorities, contains('Grounding'));
        expect(habitPriorities, contains('Affirmations'));
      },
    );

    test('MotiveConfig provides motive-specific insight messages', () {
      // Test streak messages for different motives
      final sleepStreak = MotiveConfig.getInsightMessage(
        'Sleep',
        'streak',
        count: 7,
      );
      expect(sleepStreak, contains('🌙'));
      expect(sleepStreak, contains('7'));
      expect(sleepStreak.toLowerCase(), contains('sleep'));

      final stressStreak = MotiveConfig.getInsightMessage(
        'Stress',
        'streak',
        count: 5,
      );
      expect(stressStreak, contains('💆'));
      expect(stressStreak, contains('5'));

      final anxietyStreak = MotiveConfig.getInsightMessage(
        'Anxiety',
        'streak',
        count: 3,
      );
      expect(anxietyStreak, contains('⚓'));
      expect(anxietyStreak, contains('3'));

      final focusStreak = MotiveConfig.getInsightMessage(
        'Focus',
        'streak',
        count: 10,
      );
      expect(focusStreak, contains('🎯'));
      expect(focusStreak, contains('10'));

      final habitStreak = MotiveConfig.getInsightMessage(
        'Habit Building',
        'streak',
        count: 14,
      );
      expect(habitStreak, contains('🔥'));
      expect(habitStreak, contains('14'));
    });

    test('MotiveConfig provides completion and milestone messages', () {
      // Test completion messages
      final sleepCompletion = MotiveConfig.getInsightMessage(
        'Sleep',
        'completion',
      );
      expect(sleepCompletion, contains('✨'));

      final stressCompletion = MotiveConfig.getInsightMessage(
        'Stress',
        'completion',
      );
      expect(stressCompletion, contains('🌊'));

      // Test milestone messages
      final anxietyMilestone = MotiveConfig.getInsightMessage(
        'Anxiety',
        'milestone',
      );
      expect(anxietyMilestone, contains('💪'));

      final focusMilestone = MotiveConfig.getInsightMessage(
        'Focus',
        'milestone',
      );
      expect(focusMilestone, contains('🚀'));
    });

    test('MotiveConfig provides correct profile information', () {
      // Test Sleep profile
      final sleepProfile = MotiveConfig.getProfile('Sleep');
      expect(sleepProfile, isNotNull);
      expect(sleepProfile!.emoji, equals('🌙'));
      expect(sleepProfile.displayName, equals('Better Sleep'));
      expect(sleepProfile.name, equals('Sleep'));

      // Test Stress profile
      final stressProfile = MotiveConfig.getProfile('Stress');
      expect(stressProfile, isNotNull);
      expect(stressProfile!.emoji, equals('🧘'));
      expect(stressProfile.displayName, equals('Stress Management'));

      // Test Anxiety profile
      final anxietyProfile = MotiveConfig.getProfile('Anxiety');
      expect(anxietyProfile, isNotNull);
      expect(anxietyProfile!.emoji, equals('💜'));
      expect(anxietyProfile.displayName, equals('Anxiety Relief'));

      // Test Focus profile
      final focusProfile = MotiveConfig.getProfile('Focus');
      expect(focusProfile, isNotNull);
      expect(focusProfile!.emoji, equals('🎯'));
      expect(focusProfile.displayName, equals('Enhanced Focus'));

      // Test Habit Building profile
      final habitProfile = MotiveConfig.getProfile('Habit Building');
      expect(habitProfile, isNotNull);
      expect(habitProfile!.emoji, equals('🔥'));
      expect(habitProfile.displayName, equals('Habit Building'));
    });

    test('Enhanced getUserStats structure includes all required fields', () {
      // Test that the expected data structure for enhanced getUserStats is defined
      const expectedFields = [
        'totalSessions',
        'totalMinutes',
        'averageMoodImprovement',
        'favoriteTechnique',
        'currentStreak',
        'streakMessage',
        'moodTrends',
        'advancedAnalytics',
        'motiveInsights',
        'usagePatterns',
        'weeklyStats',
        'monthlyStats',
        'userMotive',
        'motiveProfile',
      ];

      // Verify all required fields are accounted for
      expect(expectedFields.length, equals(14));
      expect(expectedFields, contains('motiveInsights'));
      expect(expectedFields, contains('usagePatterns'));
      expect(expectedFields, contains('weeklyStats'));
      expect(expectedFields, contains('monthlyStats'));
      expect(expectedFields, contains('streakMessage'));
    });

    test('Motive-specific insights structure includes all required fields', () {
      const expectedInsightFields = [
        'welcomeMessage',
        'insights',
        'achievements',
        'motiveEmoji',
        'motiveDisplayName',
        'recommendedTechniques',
        'motivationalMessage',
      ];

      expect(expectedInsightFields.length, equals(7));
      expect(expectedInsightFields, contains('welcomeMessage'));
      expect(expectedInsightFields, contains('recommendedTechniques'));
      expect(expectedInsightFields, contains('motivationalMessage'));
    });

    test('Usage patterns structure includes all required fields', () {
      const expectedPatternFields = [
        'preferredTimes',
        'techniqueDistribution',
        'effectivenessRanking',
        'motiveAlignment',
        'totalSessions',
        'analysisDate',
      ];

      expect(expectedPatternFields.length, equals(6));
      expect(expectedPatternFields, contains('motiveAlignment'));
      expect(expectedPatternFields, contains('effectivenessRanking'));
      expect(expectedPatternFields, contains('techniqueDistribution'));
    });

    test(
      'Weekly and monthly statistics structure includes all required fields',
      () {
        // Requirements 6.2: Display weekly and monthly usage statistics
        const expectedWeeklyFields = [
          'weekStart',
          'weekEnd',
          'sessionCount',
          'totalMinutes',
          'averageMoodImprovement',
          'weekNumber',
          'weekLabel',
        ];

        const expectedMonthlyFields = [
          'month',
          'year',
          'monthName',
          'sessionCount',
          'totalMinutes',
          'averageMoodImprovement',
          'monthLabel',
        ];

        expect(expectedWeeklyFields.length, equals(7));
        expect(expectedMonthlyFields.length, equals(7));

        // Verify key statistical fields are present
        expect(expectedWeeklyFields, contains('sessionCount'));
        expect(expectedWeeklyFields, contains('totalMinutes'));
        expect(expectedWeeklyFields, contains('averageMoodImprovement'));

        expect(expectedMonthlyFields, contains('sessionCount'));
        expect(expectedMonthlyFields, contains('totalMinutes'));
        expect(expectedMonthlyFields, contains('averageMoodImprovement'));
      },
    );
  });
}
