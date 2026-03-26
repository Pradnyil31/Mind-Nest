/// Example usage of the enhanced CalmProgressService for task 3.3
/// This demonstrates how to use the comprehensive user statistics dashboard
library;

import 'calm_progress_service.dart';

class CalmProgressUsageExample {
  final CalmProgressService _progressService = CalmProgressService();

  /// Example: Get comprehensive user statistics with motive-specific insights
  Future<void> demonstrateEnhancedUserStats() async {
    const userId = 'example_user_123';
    const userMotive = 'Sleep'; // User's primary motive

    try {
      // Get enhanced user statistics with motive-specific insights
      final stats = await _progressService.getUserStats(
        userId,
        userMotive: userMotive,
      );

      // Access basic statistics
      final totalSessions = stats['totalSessions'] as int;
      final totalMinutes = stats['totalMinutes'] as int;
      final currentStreak = stats['currentStreak'] as int;
      final averageMoodImprovement = stats['averageMoodImprovement'] as double;

      print('📊 Basic Statistics:');
      print('  Total Sessions: $totalSessions');
      print('  Total Minutes: $totalMinutes');
      print('  Current Streak: $currentStreak days');
      print(
        '  Average Mood Improvement: ${averageMoodImprovement.toStringAsFixed(1)} points',
      );

      // Access motive-specific insights (Requirement 20.1)
      final motiveInsights = stats['motiveInsights'] as Map<String, dynamic>;
      final welcomeMessage = motiveInsights['welcomeMessage'] as String;
      final motivationalMessage =
          motiveInsights['motivationalMessage'] as String;
      final recommendedTechniques =
          motiveInsights['recommendedTechniques'] as List<String>;

      print('\n🌙 Motive-Specific Insights:');
      print('  Welcome: $welcomeMessage');
      print('  Motivation: $motivationalMessage');
      print('  Recommended Techniques: ${recommendedTechniques.join(', ')}');

      // Access streak message with motive-appropriate messaging (Requirement 20.2)
      final streakMessage = stats['streakMessage'] as String;
      print('  Streak Message: $streakMessage');

      // Access usage patterns analysis
      final usagePatterns = stats['usagePatterns'] as Map<String, dynamic>;
      final preferredTimes = usagePatterns['preferredTimes'] as List<String>;
      final motiveAlignment = usagePatterns['motiveAlignment'] as double;

      print('\n📈 Usage Patterns:');
      print('  Preferred Times: ${preferredTimes.join(', ')}');
      print('  Motive Alignment: ${motiveAlignment.toStringAsFixed(1)}%');

      // Access weekly statistics (Requirement 6.2)
      final weeklyStats = stats['weeklyStats'] as List<Map<String, dynamic>>;
      print('\n📅 Weekly Statistics:');
      for (final week in weeklyStats.take(2)) {
        final weekLabel = week['weekLabel'] as String;
        final sessionCount = week['sessionCount'] as int;
        final totalMinutes = week['totalMinutes'] as int;
        print('  $weekLabel: $sessionCount sessions, $totalMinutes minutes');
      }

      // Access monthly statistics (Requirement 6.2)
      final monthlyStats = stats['monthlyStats'] as List<Map<String, dynamic>>;
      print('\n📆 Monthly Statistics:');
      for (final month in monthlyStats.take(2)) {
        final monthLabel = month['monthLabel'] as String;
        final sessionCount = month['sessionCount'] as int;
        final avgImprovement = month['averageMoodImprovement'] as double;
        print(
          '  $monthLabel: $sessionCount sessions, ${avgImprovement.toStringAsFixed(1)} avg improvement',
        );
      }

      // Access achievements
      final achievements =
          motiveInsights['achievements'] as List<Map<String, dynamic>>;
      if (achievements.isNotEmpty) {
        print('\n🏆 Recent Achievements:');
        for (final achievement in achievements) {
          final title = achievement['title'] as String;
          final description = achievement['description'] as String;
          final icon = achievement['icon'] as String;
          print('  $icon $title: $description');
        }
      }
    } catch (e) {
      print('Error getting user stats: $e');
    }
  }

  /// Example: Get motive-specific insights for different motives
  Future<void> demonstrateMotiveSpecificInsights() async {
    const userId = 'example_user_123';
    final motives = ['Sleep', 'Stress', 'Anxiety', 'Focus', 'Habit Building'];

    print('\n🎯 Motive-Specific Insights Comparison:');

    for (final motive in motives) {
      try {
        final insights = await _progressService.getMotiveSpecificInsights(
          userId,
          motive,
        );

        final welcomeMessage = insights['welcomeMessage'] as String;
        final recommendedTechniques =
            insights['recommendedTechniques'] as List<String>;
        final motiveEmoji = insights['motiveEmoji'] as String;

        print('\n$motiveEmoji $motive:');
        print('  Welcome: $welcomeMessage');
        print('  Top Techniques: ${recommendedTechniques.take(3).join(', ')}');
      } catch (e) {
        print('  Error for $motive: $e');
      }
    }
  }

  /// Example: Demonstrate streak calculation with motive-appropriate messaging
  Future<void> demonstrateStreakMessaging() async {
    const userId = 'example_user_123';
    final motives = ['Sleep', 'Stress', 'Anxiety', 'Focus', 'Habit Building'];

    print('\n🔥 Streak Messaging Examples:');

    for (final motive in motives) {
      try {
        final stats = await _progressService.getUserStats(
          userId,
          userMotive: motive,
        );

        final streakMessage = stats['streakMessage'] as String;
        final currentStreak = stats['currentStreak'] as int;

        print('  $motive ($currentStreak days): $streakMessage');
      } catch (e) {
        print('  Error for $motive: $e');
      }
    }
  }

  /// Example: Demonstrate technique usage pattern analysis
  Future<void> demonstrateUsagePatternAnalysis() async {
    const userId = 'example_user_123';
    const userMotive = 'Anxiety';

    try {
      final stats = await _progressService.getUserStats(
        userId,
        userMotive: userMotive,
      );

      final usagePatterns = stats['usagePatterns'] as Map<String, dynamic>;

      print('\n📊 Technique Usage Pattern Analysis:');

      // Preferred times analysis
      final preferredTimes = usagePatterns['preferredTimes'] as List<String>;
      print('  Preferred Times: ${preferredTimes.join(' > ')}');

      // Technique distribution
      final techniqueDistribution =
          usagePatterns['techniqueDistribution'] as List<Map<String, dynamic>>;
      print('  Top Techniques by Usage:');
      for (final technique in techniqueDistribution.take(3)) {
        final name = technique['technique'] as String;
        final percentage = technique['percentage'] as int;
        final sessionCount = technique['sessionCount'] as int;
        print('    $name: $sessionCount sessions ($percentage%)');
      }

      // Effectiveness ranking
      final effectivenessRanking =
          usagePatterns['effectivenessRanking'] as List<Map<String, dynamic>>;
      print('  Most Effective Techniques:');
      for (final technique in effectivenessRanking.take(3)) {
        final name = technique['technique'] as String;
        final avgImprovement = technique['averageImprovement'] as double;
        final sessionCount = technique['sessionCount'] as int;
        print(
          '    $name: ${avgImprovement.toStringAsFixed(1)} avg improvement ($sessionCount sessions)',
        );
      }

      // Motive alignment score
      final motiveAlignment = usagePatterns['motiveAlignment'] as double;
      print('  Motive Alignment Score: ${motiveAlignment.toStringAsFixed(1)}%');

      if (motiveAlignment > 70) {
        print('    ✅ Great alignment with your $userMotive goals!');
      } else if (motiveAlignment > 40) {
        print(
          '    ⚠️  Moderate alignment - consider trying more $userMotive-focused techniques',
        );
      } else {
        print(
          '    ❌ Low alignment - explore techniques prioritized for $userMotive',
        );
      }
    } catch (e) {
      print('Error analyzing usage patterns: $e');
    }
  }
}
