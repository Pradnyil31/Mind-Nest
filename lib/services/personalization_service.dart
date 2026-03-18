import '../config/motive_config.dart';
import '../models/guided_meditation.dart';

/// Recommended exercise item for the home screen.
class RecommendedExercise {
  final String title;
  final String subtitle;
  final String emoji;
  /// Route key: 'meditation', 'breathing', 'grounding', 'journaling', 'calm', 'goals'
  final String routeKey;
  /// If this links to a specific meditation, attach it.
  final GuidedMeditation? meditation;

  const RecommendedExercise({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.routeKey,
    this.meditation,
  });
}

/// Central personalization service that translates onboarding selections
/// into personalized content across the app.
class PersonalizationService {
  // ── Greeting ──────────────────────────────────────────────────────────────
  /// Returns a motive-aware, time-of-day-aware greeting subtitle.
  /// e.g. "Time for your anxiety relief techniques 💜"
  static String getMotiveGreetingHint(String? motive, String? preferredTime) {
    final hour = DateTime.now().hour;
    final profile = MotiveConfig.getProfile(motive);
    if (profile == null) return 'Ready to take care of yourself today?';

    // Match preferred time to give extra-relevant nudge
    final isPreferredTime = _isNowPreferredTime(hour, preferredTime);

    if (isPreferredTime) {
      return 'Perfect time for ${profile.displayName.toLowerCase()} ${profile.emoji}';
    }

    // Time-of-day based hints
    if (hour < 12) {
      return 'Start your morning with ${profile.displayName.toLowerCase()} ${profile.emoji}';
    } else if (hour < 17) {
      return 'Take a pause for ${profile.displayName.toLowerCase()} ${profile.emoji}';
    } else if (hour < 21) {
      return 'Wind down with ${profile.displayName.toLowerCase()} ${profile.emoji}';
    } else {
      return 'Relax into the night ${profile.emoji}';
    }
  }

  static bool _isNowPreferredTime(int hour, String? preferredTime) {
    if (preferredTime == null) return false;
    if (preferredTime.contains('Morning') && hour >= 5 && hour < 12) return true;
    if (preferredTime.contains('Afternoon') && hour >= 12 && hour < 17) return true;
    if (preferredTime.contains('Evening') && hour >= 17 && hour < 21) return true;
    if (preferredTime.contains('Bed') && hour >= 21) return true;
    return false;
  }

  // ── Beginner Nudge ────────────────────────────────────────────────────────
  /// Returns a nudge string for beginners, or null if not a beginner.
  static String? getBeginnerNudge(String? experienceLevel) {
    if (experienceLevel == null) return null;
    if (experienceLevel == 'Never tried') {
      return 'New to meditation? Start with a Quick Reset ✨';
    }
    if (experienceLevel == 'New Beginner') {
      return 'Just starting out? We\'ve picked easy exercises for you 🌱';
    }
    if (experienceLevel == 'Long ago') {
      return 'Welcome back! Let\'s ease you in gently 🌿';
    }
    return null;
  }

  // ── Recommendations ───────────────────────────────────────────────────────
  /// Returns 2-3 recommended exercises based on motive + experience + support areas.
  static List<RecommendedExercise> getRecommendations({
    String? motive,
    String? experienceLevel,
    List<String> supportAreas = const [],
  }) {
    final recommendations = <RecommendedExercise>[];
    final profile = MotiveConfig.getProfile(motive);

    // 1. Top meditation pick based on experience level
    final topMeditation = _getTopMeditation(motive, experienceLevel);
    if (topMeditation != null) {
      recommendations.add(RecommendedExercise(
        title: topMeditation.title,
        subtitle: '${topMeditation.durationMinutes} min · ${topMeditation.difficulty}',
        emoji: _meditationEmoji(topMeditation.category),
        routeKey: 'meditation',
        meditation: topMeditation,
      ));
    }

    // 2. Support-area-driven recommendation
    final supportRec = _getSupportAreaRecommendation(supportAreas, motive);
    if (supportRec != null) {
      recommendations.add(supportRec);
    }

    // 3. Motive-based exercise recommendation
    if (profile != null) {
      final recommended = profile.recommendedScreens;
      // Pick the first recommended screen that's not already in the list
      for (final screen in recommended) {
        final existing = recommendations.map((r) => r.routeKey).toSet();
        if (!existing.contains(screen)) {
          final rec = _screenToRecommendation(screen, profile);
          if (rec != null) {
            recommendations.add(rec);
            break;
          }
        }
      }
    }

    // Ensure we have at least 2, fill with defaults
    if (recommendations.length < 2) {
      if (!recommendations.any((r) => r.routeKey == 'breathing')) {
        recommendations.add(const RecommendedExercise(
          title: 'Deep Breathing',
          subtitle: 'Calm your nervous system',
          emoji: '🌬️',
          routeKey: 'breathing',
        ));
      }
    }

    return recommendations.take(3).toList();
  }

  /// Returns the best meditation for a user based on motive and experience.
  static GuidedMeditation? _getTopMeditation(String? motive, String? experienceLevel) {
    final all = GuidedMeditation.getByMotive(motive);
    if (all.isEmpty) return null;

    final isBeginner = experienceLevel == 'Never tried' || experienceLevel == 'New Beginner';
    final isReturning = experienceLevel == 'Long ago';

    if (isBeginner) {
      // Find shortest beginner meditation
      final beginnerMeds = all.where((m) => m.difficulty == 'Beginner').toList();
      if (beginnerMeds.isNotEmpty) {
        beginnerMeds.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        // Prefer Quick Reset for absolute beginners
        final quickReset = beginnerMeds.where((m) => m.id == 'quick-reset').toList();
        if (quickReset.isNotEmpty) return quickReset.first;
        return beginnerMeds.first;
      }
    }

    if (isReturning) {
      // Short-medium meditations sorted by relevance
      final shortMeds = all.where((m) => m.durationMinutes <= 10).toList();
      if (shortMeds.isNotEmpty) return shortMeds.first;
    }

    // Default: first motive-relevant meditation
    return all.first;
  }

  static RecommendedExercise? _getSupportAreaRecommendation(
    List<String> supportAreas,
    String? motive,
  ) {
    if (supportAreas.isEmpty) return null;

    // Map support areas to specific exercises
    const supportMap = <String, RecommendedExercise>{
      'Racing thoughts': RecommendedExercise(
        title: 'Journal It Out',
        subtitle: 'Release racing thoughts on paper',
        emoji: '📝',
        routeKey: 'journaling',
      ),
      'Panic attacks': RecommendedExercise(
        title: '4-7-8 Breathing',
        subtitle: 'Emergency calm technique',
        emoji: '🫁',
        routeKey: 'breathing',
      ),
      'Social anxiety': RecommendedExercise(
        title: 'Grounding Exercise',
        subtitle: 'Feel your feet on the ground',
        emoji: '⚓',
        routeKey: 'grounding',
      ),
      'Future worrying': RecommendedExercise(
        title: 'Present Moment',
        subtitle: 'Come back to right now',
        emoji: '🧘',
        routeKey: 'meditation',
      ),
      'Phone distractions': RecommendedExercise(
        title: 'Focus Session',
        subtitle: 'Train your concentration',
        emoji: '🎯',
        routeKey: 'meditation',
      ),
      'Procrastination': RecommendedExercise(
        title: 'Quick Reset',
        subtitle: '5 min to get unstuck',
        emoji: '⚡',
        routeKey: 'meditation',
      ),
      'Work pressure': RecommendedExercise(
        title: 'Breathing Break',
        subtitle: 'Release work tension',
        emoji: '🌬️',
        routeKey: 'breathing',
      ),
      'Stress at night': RecommendedExercise(
        title: 'Body Scan',
        subtitle: 'Melt tension before sleep',
        emoji: '🌙',
        routeKey: 'calm',
      ),
      'Blue light habits': RecommendedExercise(
        title: 'Wind Down',
        subtitle: 'Screen-free relaxation',
        emoji: '📵',
        routeKey: 'calm',
      ),
      'Imposter syndrome': RecommendedExercise(
        title: 'Positive Affirmations',
        subtitle: 'Remind yourself of your worth',
        emoji: '💪',
        routeKey: 'calm',
      ),
      'Screen addiction': RecommendedExercise(
        title: 'Mindful Moment',
        subtitle: 'Step away from the screen',
        emoji: '🌿',
        routeKey: 'breathing',
      ),
      'Consistency': RecommendedExercise(
        title: 'Daily Check-in',
        subtitle: 'Build your streak',
        emoji: '🔥',
        routeKey: 'checkin',
      ),
    };

    for (final area in supportAreas) {
      if (supportMap.containsKey(area)) {
        return supportMap[area];
      }
    }
    return null;
  }

  static RecommendedExercise? _screenToRecommendation(String screen, MotiveProfile profile) {
    switch (screen) {
      case 'breathing':
        return RecommendedExercise(
          title: 'Breathing Exercise',
          subtitle: 'Recommended for ${profile.displayName.toLowerCase()}',
          emoji: '🌬️',
          routeKey: 'breathing',
        );
      case 'meditation':
        return RecommendedExercise(
          title: 'Guided Meditation',
          subtitle: 'Recommended for ${profile.displayName.toLowerCase()}',
          emoji: '🧘',
          routeKey: 'meditation',
        );
      case 'grounding':
        return RecommendedExercise(
          title: 'Grounding Exercise',
          subtitle: '5-4-3-2-1 senses technique',
          emoji: '⚓',
          routeKey: 'grounding',
        );
      case 'journaling':
        return RecommendedExercise(
          title: 'Journaling',
          subtitle: 'Process your thoughts',
          emoji: '📝',
          routeKey: 'journaling',
        );
      case 'goals':
        return RecommendedExercise(
          title: 'Smart Goals',
          subtitle: 'Set clear intentions',
          emoji: '🎯',
          routeKey: 'goals',
        );
      case 'calm':
        return RecommendedExercise(
          title: 'Calm Techniques',
          subtitle: 'Find your peace',
          emoji: '🕊️',
          routeKey: 'calm',
        );
      default:
        return null;
    }
  }

  static String _meditationEmoji(MeditationCategory category) {
    switch (category) {
      case MeditationCategory.sleep:
        return '🌙';
      case MeditationCategory.stress:
        return '🧘';
      case MeditationCategory.anxiety:
        return '💜';
      case MeditationCategory.focus:
        return '🎯';
      case MeditationCategory.mindfulness:
        return '☀️';
      case MeditationCategory.compassion:
        return '💖';
    }
  }

  // ── Daily Insight ─────────────────────────────────────────────────────────
  /// Returns a motive-themed daily insight message.
  static String getDailyInsight(String? motive, int streak) {
    if (streak > 0) {
      return MotiveConfig.getInsightMessage(motive, 'streak', count: streak);
    }
    return MotiveConfig.getInsightMessage(motive, 'encouragement');
  }

  // ── Meditation Library Helpers ────────────────────────────────────────────
  /// Returns true if this user is a beginner who should see the "Start Here" banner.
  static bool shouldShowStartHere(String? experienceLevel) {
    return experienceLevel == 'Never tried' || experienceLevel == 'New Beginner';
  }

  /// Returns true if this user is returning and should see a welcome-back message.
  static bool shouldShowWelcomeBack(String? experienceLevel) {
    return experienceLevel == 'Long ago';
  }

  /// Sorts meditations with experience-awareness: beginners get easy ones first.
  static List<GuidedMeditation> sortByExperience(
    List<GuidedMeditation> meditations,
    String? experienceLevel,
  ) {
    final sorted = List<GuidedMeditation>.from(meditations);
    if (shouldShowStartHere(experienceLevel)) {
      // Sort: Beginner first, then by duration (shortest first)
      sorted.sort((a, b) {
        final aDiff = a.difficulty == 'Beginner' ? 0 : 1;
        final bDiff = b.difficulty == 'Beginner' ? 0 : 1;
        if (aDiff != bDiff) return aDiff.compareTo(bDiff);
        return a.durationMinutes.compareTo(b.durationMinutes);
      });
    } else if (shouldShowWelcomeBack(experienceLevel)) {
      // Sort by duration (shortest first for ease)
      sorted.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    }
    return sorted;
  }
}
