/// Motive-specific configuration and profiles
/// Defines personalized content for each user motive

class MotiveProfile {
  final String name;
  final String displayName;
  final String emoji;
  final String description;
  final List<String> routineActivities;
  final List<String> meditationTags;
  final List<String> calmTechniquePriorities;
  final List<String> recommendedScreens;
  final Map<String, String> insightMessages;
  final List<String> badgeThemes;

  /// Personalized deep-dive question for onboarding Step 3
  final String supportQuestion;

  /// Support area label → list of routine activities the app adds
  final Map<String, List<String>> supportAreas;

  const MotiveProfile({
    required this.name,
    required this.displayName,
    required this.emoji,
    required this.description,
    required this.routineActivities,
    required this.meditationTags,
    required this.calmTechniquePriorities,
    required this.recommendedScreens,
    required this.insightMessages,
    required this.badgeThemes,
    this.supportQuestion = 'Is there anything else you\'d like support with?',
    this.supportAreas = const {},
  });
}

class MotiveConfig {
  // All available motives
  static const List<String> allMotives = [
    'Sleep',
    'Stress',
    'Anxiety',
    'Focus',
    'Habit Building',
  ];

  // ─────────────────────────────────────────────
  // Motive profiles with personalized content
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // Motive profiles with personalized content
  // ─────────────────────────────────────────────
  static const Map<String, MotiveProfile> profiles = {

    // ── Sleep ──────────────────────────────────
    'Sleep': MotiveProfile(
      name: 'Sleep',
      displayName: 'Better Sleep',
      emoji: '🌙',
      description: 'Improve sleep quality and build consistent sleep habits',
      supportQuestion: 'What\'s keeping you up at night?',
      supportAreas: {
        'Racing thoughts':     ['Brain dump journaling', 'Sleep meditation'],
        'Blue light habits':   ['No screens after 9 PM', 'Bedroom environment check'],
        'Inconsistent schedule': ['Consistent bedtime reminder', 'Morning sunlight exposure'],
        'Stress at night':     ['Progressive muscle relaxation', 'Evening wind-down ritual'],
        'Caffeine dependency': ['Caffeine cutoff (2pm)', 'Herbal tea ritual'],
        'Partner disturbance': ['White noise session', 'Sleep meditation'],
      },
      routineActivities: [
        'Morning sunlight exposure',
        'Drink 500ml Water',
        'Make Bed',
        'Caffeine cutoff (2pm)',
        'Physical activity',
        'Walk',
        'Limit screens 1hr before bed',
        'Evening wind-down ritual',
        'Sleep meditation',
      ],
      meditationTags: ['sleep', 'bedtime', 'deep-rest', 'body-scan', 'relaxation'],
      calmTechniquePriorities: ['Body Scan', 'Breathing', 'Guided Imagery'],
      recommendedScreens: ['sleep_recovery', 'breathing', 'meditation', 'journaling'],
      insightMessages: {
        'streak': '🌙 {count} nights of better sleep habits!',
        'completion': '✨ Quality rest achieved today!',
        'encouragement': 'Your bedtime routine is becoming a habit!',
        'milestone': '🌟 Sleep consistency milestone reached!',
      },
      badgeThemes: ['moon', 'stars', 'night', 'rest', 'peaceful'],
    ),

    // ── Stress ─────────────────────────────────
    'Stress': MotiveProfile(
      name: 'Stress',
      displayName: 'Stress Management',
      emoji: '🧘',
      description: 'Build stress resilience and relaxation skills',
      supportQuestion: 'What triggers your stress most?',
      supportAreas: {
        'Work pressure':       ['Midday breathing break', 'Task prioritization'],
        'Relationships':       ['Empathy meditation', 'Gratitude journaling'],
        'Financial worries':   ['Gratitude journaling', 'Mindful money moment'],
        'Health concerns':     ['Body scan meditation', 'Movement break'],
        'Social situations':   ['Pre-social grounding exercise', 'Breathing breaks'],
        'Information overload': ['Digital detox hour', 'Single-task focus session'],
      },
      routineActivities: [
        'Morning mindfulness',
        'Start the day slowly',
        'Positive affirmations',
        'Stress check-in',
        'Deep breathing breaks',
        'Walk in nature',
        'Gratitude journaling',
        'Digital detox time',
        'Progressive muscle relaxation',
      ],
      meditationTags: ['stress-relief', 'mindfulness', 'calm', 'peace', 'relaxation'],
      calmTechniquePriorities: ['Breathing', 'Grounding', 'Meditation'],
      recommendedScreens: ['breathing', 'meditation', 'journaling', 'calm'],
      insightMessages: {
        'streak': '💆 {count} days of stress management!',
        'completion': '🌊 Calm achieved today!',
        'encouragement': 'You\'re building resilience!',
        'milestone': '🎯 Stress management mastery unlocked!',
      },
      badgeThemes: ['waves', 'zen', 'balance', 'calm', 'peace'],
    ),

    // ── Anxiety ────────────────────────────────
    'Anxiety': MotiveProfile(
      name: 'Anxiety',
      displayName: 'Anxiety Relief',
      emoji: '💜',
      description: 'Manage anxious thoughts and build coping skills',
      supportQuestion: 'What does your anxiety look like?',
      supportAreas: {
        'Social anxiety':    ['Grounding exercises', 'Pre-social breathing'],
        'Panic attacks':     ['4-7-8 breathing', 'Emergency calm toolkit'],
        'Health anxiety':    ['Body appreciation meditation', 'Worry journaling'],
        'Future worrying':   ['Present moment meditation', 'What I can control journaling'],
        'Decision paralysis': ['Clarity meditation', 'Values check-in'],
        'Imposter syndrome': ['Positive affirmations', 'Achievement journaling'],
      },
      routineActivities: [
        'Daily anchor habit',
        'Morning intention setting',
        'Gentle movement',
        'Anxiety check-in',
        'Grounding exercises',
        'Connect with a friend',
        'Worry journaling',
        'Safe space meditation',
        'Herbal tea ritual',
      ],
      meditationTags: ['anxiety', 'present-moment', 'safety', 'grounding', 'calm'],
      calmTechniquePriorities: ['Grounding', 'Breathing', 'Body Awareness'],
      recommendedScreens: ['grounding', 'breathing', 'meditation', 'affirmations'],
      insightMessages: {
        'streak': '⚓ {count} days of anxiety management!',
        'completion': '🌿 Grounded and present today!',
        'encouragement': 'Your coping skills are growing!',
        'milestone': '💪 Anxiety resilience achieved!',
      },
      badgeThemes: ['anchor', 'roots', 'ground', 'steady', 'strong'],
    ),

    // ── Focus ──────────────────────────────────
    'Focus': MotiveProfile(
      name: 'Focus',
      displayName: 'Enhanced Focus',
      emoji: '🎯',
      description: 'Improve concentration and productivity',
      supportQuestion: 'What breaks your focus most?',
      supportAreas: {
        'Phone distractions':  ['Phone-free focus block', 'Digital detox periods'],
        'Procrastination':     ['2-minute starter task', 'Focus sessions (Pomodoro)'],
        'Multitasking':        ['Single-task commitment', 'Concentration meditation'],
        'Noise sensitivity':   ['Focus sounds session', 'Environment preparation'],
        'Mental fatigue':      ['Power nap', 'Walking break'],
        'Lack of motivation':  ['Morning intention setting', 'Reward planning'],
      },
      routineActivities: [
        'Task prioritization',
        'Clear my workspace',
        'Review goals',
        'Focus sessions (Pomodoro)',
        'Single-task commitment',
        'Energy management',
        'Evening review',
        'Plan tomorrow',
        'Celebrate small wins',
      ],
      meditationTags: ['focus', 'concentration', 'clarity', 'mindfulness', 'productivity'],
      calmTechniquePriorities: ['Grounding', 'Breathing', 'Visualization'],
      recommendedScreens: ['focus', 'breathing', 'meditation', 'goals'],
      insightMessages: {
        'streak': '🎯 {count} days of focused work!',
        'completion': '✨ Productive day achieved!',
        'encouragement': 'Your concentration is strengthening!',
        'milestone': '🚀 Focus mastery unlocked!',
      },
      badgeThemes: ['target', 'laser', 'clarity', 'sharp', 'precise'],
    ),

    // ── Habit Building ────────────────────────
    'Habit Building': MotiveProfile(
      name: 'Habit Building',
      displayName: 'Habit Building',
      emoji: '🔥',
      description: 'Build sustainable positive habits',
      supportQuestion: 'What\'s been hardest to change?',
      supportAreas: {
        'Consistency':         ['Daily anchor habit', 'Streak tracking'],
        'Morning routine':     ['Wake routine checklist', 'Morning intention setting'],
        'Screen addiction':    ['Screen-free morning hour', 'Evening digital sunset'],
        'Exercise motivation': ['Movement reminder', '5-min micro-exercise'],
        'Diet habits':         ['Mindful eating moment', 'Meal prep check-in'],
        'Productivity blocks': ['Energy mapping', 'Deep work block'],
      },
      routineActivities: [
        'Morning routine',
        'Drink water',
        'Visualizing the day',
        'Consistency check-in',
        'Habit stacking practice',
        'Healthy Lunch',
        'Daily habit tracking',
        'Reflection journaling',
        'Prepare for tomorrow',
      ],
      meditationTags: ['motivation', 'commitment', 'mindfulness', 'discipline', 'growth'],
      calmTechniquePriorities: ['Breathing', 'Meditation', 'Grounding', 'Affirmations'],
      recommendedScreens: ['mood_tracking', 'journaling', 'goals', 'meditation'],
      insightMessages: {
        'streak': '🔥 {count} day streak! Unstoppable!',
        'completion': '✅ Consistency wins today!',
        'encouragement': 'Habits are forming!',
        'milestone': '🏆 Habit master achievement!',
      },
      badgeThemes: ['growth', 'momentum', 'achievement', 'consistency', 'fire'],
    ),
  };

  /// Generate centralized routine based on motive and commitment
  static List<String> generateRoutine({
    required String? motive,
    required String? commitment,
    List<String> supportAreas = const [],
  }) {
    // 1. Determine activity limit based on commitment
    int limit = 5; // Default (10 mins)
    if (commitment != null) {
      if (commitment.startsWith('5')) limit = 3;
      else if (commitment.startsWith('10')) limit = 5;
      else if (commitment.startsWith('15')) limit = 7;
      else if (commitment.startsWith('30')) limit = 9;
    }

    // 2. Get activities
    final baseActivities = getRoutineActivities(motive);
    final supportActivities = getActivitiesForSupportAreas(motive, supportAreas);

    // 3. Combine with priority: Base (Core) -> Support -> Base (Fill)
    final combined = <String>{};
    
    // Always add top 2 base activities first (Core habits)
    combined.addAll(baseActivities.take(2));
    
    // Then add support activities (Personalized needs)
    combined.addAll(supportActivities);
    
    // Then fill rest with remaining base activities
    combined.addAll(baseActivities.skip(2));

    // 4. Return limited list
    return combined.take(limit).toList();
  }

  /// Get profile for a given motive
  static MotiveProfile? getProfile(String? motive) {
    if (motive == null) return null;
    return profiles[motive];
  }

  /// Get routine activities for a motive
  static List<String> getRoutineActivities(String? motive) {
    final profile = getProfile(motive);
    return profile?.routineActivities ?? _getDefaultActivities();
  }

  /// Get meditation tags for filtering
  static List<String> getMeditationTags(String? motive) {
    final profile = getProfile(motive);
    return profile?.meditationTags ?? ['mindfulness', 'calm', 'relaxation'];
  }

  /// Get prioritized calm techniques
  static List<String> getCalmTechniquePriorities(String? motive) {
    final profile = getProfile(motive);
    return profile?.calmTechniquePriorities ?? ['Breathing', 'Meditation'];
  }

  /// Get personalized insight message
  static String getInsightMessage(String? motive, String messageType, {int? count}) {
    final profile = getProfile(motive);
    String message = profile?.insightMessages[messageType] ?? _getDefaultMessage(messageType);
    if (count != null) {
      message = message.replaceAll('{count}', count.toString());
    }
    return message;
  }

  /// Default activities for users without a motive set
  static List<String> _getDefaultActivities() {
    return [
      'Morning mindfulness',
      'Breathing exercises',
      'Gratitude journaling',
      'Evening reflection',
      'Physical movement',
      'Digital detox',
      'Self-care moment',
      'Sleep preparation',
    ];
  }

  /// Default messages
  static String _getDefaultMessage(String messageType) {
    switch (messageType) {
      case 'streak':
        return '🌱 {count} day wellness streak!';
      case 'completion':
        return '✨ Great work today!';
      case 'encouragement':
        return 'Keep going, you\'re doing great!';
      case 'milestone':
        return '🎉 Amazing milestone reached!';
      default:
        return '✨ Keep up the good work!';
    }
  }

  /// Check if a calm technique is prioritized for a motive
  static bool isTechniquePrioritized(String? motive, String techniqueName) {
    final priorities = getCalmTechniquePriorities(motive);
    return priorities.contains(techniqueName);
  }

  /// Get recommended screen routes for a motive
  static List<String> getRecommendedScreens(String? motive) {
    final profile = getProfile(motive);
    return profile?.recommendedScreens ?? ['breathing', 'meditation', 'journaling'];
  }

  /// Get the support question for onboarding Step 3
  static String getSupportQuestion(String? motive) {
    final profile = getProfile(motive);
    return profile?.supportQuestion ?? 'Is there anything else you\'d like support with?';
  }

  /// Get support area options for onboarding Step 3
  static List<String> getSupportAreaOptions(String? motive) {
    final profile = getProfile(motive);
    if (profile != null && profile.supportAreas.isNotEmpty) {
      return profile.supportAreas.keys.toList();
    }
    // Default generic options for users without a motive
    return [
      'Low Motivation',
      'Breaking Bad Habits',
      'Self-Reflection',
      'Relationships',
      'Overeating',
    ];
  }

  /// Get routine activities for selected support areas
  static List<String> getActivitiesForSupportAreas(String? motive, List<String> selectedAreas) {
    final profile = getProfile(motive);
    if (profile == null) return [];
    
    final activities = <String>{};
    for (final area in selectedAreas) {
      final areaActivities = profile.supportAreas[area];
      if (areaActivities != null) {
        activities.addAll(areaActivities);
      }
    }
    return activities.toList();
  }
}
