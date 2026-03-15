import 'package:flutter/material.dart';
import '../../../screens/breathing_screen.dart';
import '../../../screens/meditation_library_screen.dart';
import '../../../services/meditation_analytics_service.dart';
import '../../../models/breathing_technique.dart';
import '../../../models/guided_meditation.dart';

/// Service for seamless navigation integration between calm features and existing app ecosystem
class NavigationIntegrationService {
  static final NavigationIntegrationService _instance =
      NavigationIntegrationService._internal();
  factory NavigationIntegrationService() => _instance;
  NavigationIntegrationService._internal();

  MeditationAnalyticsService? _meditationAnalytics;

  MeditationAnalyticsService get _analytics {
    _meditationAnalytics ??= MeditationAnalyticsService();
    return _meditationAnalytics!;
  }

  /// Navigate directly to existing BreathingScreen with analytics integration
  Future<void> navigateToBreathing(
    BuildContext context, {
    String? preferredTechnique,
  }) async {
    // Track navigation from calm tab for analytics
    await _trackCalmNavigation('breathing', preferredTechnique);

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BreathingScreen(),
        settings: const RouteSettings(
          name: '/breathing',
          arguments: {'source': 'calm_tab'},
        ),
      ),
    );
  }

  /// Navigate directly to existing MeditationLibraryScreen with analytics integration
  Future<void> navigateToMeditation(
    BuildContext context, {
    String? category,
  }) async {
    // Track navigation from calm tab for analytics
    await _trackCalmNavigation('meditation', category);

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MeditationLibraryScreen(),
        settings: RouteSettings(
          name: '/meditation',
          arguments: {'source': 'calm_tab', 'category': category},
        ),
      ),
    );
  }

  /// Get quick access breathing techniques without duplicating functionality
  List<BreathingTechnique> getQuickAccessBreathingTechniques() {
    // Return subset of existing breathing techniques for quick access
    return BreathingTechnique.defaults
        .where((technique) {
          // Focus on techniques suitable for anxiety relief (≤5 minutes)
          return technique.title.contains('4-7-8') ||
              technique.title.contains('Box') ||
              technique.title.contains('Calm');
        })
        .take(3)
        .toList();
  }

  /// Get meditation previews without duplicating functionality
  List<GuidedMeditation> getMeditationPreviews({String? motive}) {
    // Return subset of existing meditations relevant to calm/anxiety
    final allMeditations = GuidedMeditation.defaults;

    if (motive != null) {
      return GuidedMeditation.getByMotive(motive).take(3).toList();
    }

    // Default to anxiety and stress relief meditations
    return allMeditations
        .where((meditation) {
          return meditation.category == MeditationCategory.anxiety ||
              meditation.category == MeditationCategory.stress;
        })
        .take(3)
        .toList();
  }

  /// Create contextual help for feature boundaries
  Map<String, String> getFeatureBoundaries() {
    return {
      'calm': 'Immediate anxiety relief and grounding techniques',
      'breathing': 'Structured breathing exercises and patterns',
      'meditation': 'Guided meditation practices and mindfulness',
    };
  }

  /// Get navigation suggestions based on current context
  List<NavigationSuggestion> getNavigationSuggestions(String? currentMotive) {
    final suggestions = <NavigationSuggestion>[];

    // Breathing suggestions
    suggestions.add(
      NavigationSuggestion(
        title: 'Breathing Exercises',
        description:
            'Structured breathing patterns for ${_getMotiveContext(currentMotive)}',
        icon: Icons.air,
        route: '/breathing',
        estimatedDuration: '3-10 minutes',
        category: 'breathing',
      ),
    );

    // Meditation suggestions
    suggestions.add(
      NavigationSuggestion(
        title: 'Guided Meditation',
        description:
            'Longer meditation practices for deeper ${_getMotiveContext(currentMotive)}',
        icon: Icons.self_improvement,
        route: '/meditation',
        estimatedDuration: '5-30 minutes',
        category: 'meditation',
      ),
    );

    return suggestions;
  }

  /// Track navigation from calm tab for analytics integration
  Future<void> _trackCalmNavigation(String destination, String? context) async {
    try {
      // This integrates with existing analytics without duplicating
      // The actual tracking would be handled by existing services
      debugPrint(
        'Calm navigation: $destination${context != null ? ' ($context)' : ''}',
      );
    } catch (e) {
      debugPrint('Error tracking calm navigation: $e');
    }
  }

  /// Get motive-specific context for suggestions
  String _getMotiveContext(String? motive) {
    switch (motive) {
      case 'Sleep':
        return 'better sleep preparation';
      case 'Stress':
        return 'stress relief';
      case 'Anxiety':
        return 'anxiety management';
      case 'Focus':
        return 'improved concentration';
      case 'Habit Building':
        return 'mindful habit formation';
      default:
        return 'wellness';
    }
  }

  /// Check if user has used breathing/meditation features today
  Future<Map<String, bool>> getTodayUsageStatus(String userId) async {
    try {
      final hasMeditated = await _analytics.hasMeditatedToday(userId);

      // For breathing, we'd need to check if there's a similar service
      // For now, we'll return meditation status and assume breathing tracking exists
      return {
        'meditation': hasMeditated,
        'breathing':
            false, // Would integrate with breathing analytics if available
      };
    } catch (e) {
      return {'meditation': false, 'breathing': false};
    }
  }

  /// Get unified progress data for dashboard integration
  Future<Map<String, dynamic>> getUnifiedProgressData(String userId) async {
    try {
      final meditationStats = await _analytics.getStats(userId);
      final meditationStreak = await _analytics.getCurrentStreak(userId);

      return {
        'meditation': {
          'totalSessions': meditationStats['totalSessions'] ?? 0,
          'totalMinutes': meditationStats['totalMinutes'] ?? 0,
          'currentStreak': meditationStreak,
        },
        'breathing': {
          // Would integrate with breathing analytics if available
          'totalSessions': 0,
          'totalMinutes': 0,
          'currentStreak': 0,
        },
        'calm': {
          // Calm-specific analytics would be tracked separately
          'totalSessions': 0,
          'totalMinutes': 0,
          'currentStreak': 0,
        },
      };
    } catch (e) {
      return {
        'meditation': {
          'totalSessions': 0,
          'totalMinutes': 0,
          'currentStreak': 0,
        },
        'breathing': {
          'totalSessions': 0,
          'totalMinutes': 0,
          'currentStreak': 0,
        },
        'calm': {'totalSessions': 0, 'totalMinutes': 0, 'currentStreak': 0},
      };
    }
  }
}

/// Navigation suggestion model
class NavigationSuggestion {
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final String estimatedDuration;
  final String category;

  NavigationSuggestion({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.estimatedDuration,
    required this.category,
  });
}
