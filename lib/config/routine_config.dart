/// Centralized configuration for routine activities and their default time periods.
class RoutineConfig {
  static const Map<String, List<String>> _activitiesByPeriod = {
    'Morning': [
      // Hydration & Nutrition
      'Drink 500ml Water', 'Drink water', 'Healthy eating', 'Healthy Breakfast',
      
      // Light & Environment
      'Morning Sunlight', 'Morning sunlight exposure', 'Make Bed', 'Open curtains',
      
      // Movement
      'Stretch', 'Physical activity', 'Gentle movement', 'Movement reminder',
      '5-min micro-exercise', 'Yoga', 'Exercise',
      
      // Mindfulness & Mental State
      'Meditation', 'Morning mindfulness', 'Morning intention setting', 
      'Morning check-in', 'Body appreciation meditation', 'Present moment meditation',
      'Positive affirmations', 'Start the day slowly', 'Smile more',
      
      // Habits & Planning
      'Delay Caffeine', 'Wake routine checklist', 'Screen-free morning hour',
      'Daily anchor habit', 'Stick to the plan', 'Morning routine',
      'Habit stacking practice', 'Small steps today',
      'Task prioritization', 'Review goals', 'Visualizing the day'
    ],
    'Afternoon': [
      // Nutrition & Energy
      'Healthy Lunch', 'Mindful eating moment', 'Eat a healthy snack',
      
      // Movement & Breaks
      'Walk', 'Walk in nature', 'Deep breathing breaks', 'Midday breathing break',
      'Movement break', 'Physical movement', 'Power Nap',
      
      // Focus & Work
      'Deep Work', 'Focus sessions (Pomodoro)', 'Deep work block', 
      'Single-task focus session', 'Phone-free focus block', 'Single-tasking today',
      'Energy management', 'Energy mapping',
      
      // Mental State
      'Mindfulness', 'Check-in', 'Stress check-in', 'Anxiety check-in',
      'Consistency check-in', 'Values check-in',
      'Mindful breathing', 'Mindful breaks',
      'Grounding exercises', 'Pre-social grounding exercise', 'Emergency calm toolkit',
      '4-7-8 breathing', 'Self-compassion practice',
      
      // Social & Connection
      'Connect with a friend', 'Social connection', 'Speak up today',
      
      // Caffeine Control
      'Cut Caffeine', 'Caffeine cutoff (2pm)'
    ],
    'Evening': [
      // Environment
      'Dim Lights', 'Bedroom environment check', 'No Screens', 'Evening digital sunset',
      'Limit screens 1hr before bed', 'Digital detox', 'Digital detox time',
      'Digital detox hour', 'Clear my workspace',
      
      // Relaxation
      'Read Fiction', 'Read a calming book', 'Herbal Tea', 'Herbal tea ritual',
      'Relax', 'Relaxing breathing', 'Nature time', 'Creative activity',
      'Listen to music', 'White noise session',
      
      // Reflection & Journaling
      'Journaling', 'Gratitude journaling', 'Evening reflection', 'Reflection journaling',
      'Worry journaling', 'Brain dump journaling', 'Achievement journaling', 
      'What I can control journaling', 'Find one joy', 'Celebrate small wins',
      'Celebration moments', 'Evening review', 'Progress review', 
      'Write it down', 'Let go of what-ifs', 'Daily habit tracking',
      
      // Planning
      'Plan tomorrow', 'Prepare for tomorrow',
      
      // Sleep Preparation
      'Early Bedtime', 'Consistent bedtime reminder', 'Sleep preparation',
      'Sleep by 10 PM', 'No screens after 9 PM', 'Consistent sleep schedule',
      'Evening wind-down ritual', 'Evening routine',
      
      // Meditation
      'Sleep meditation', 'Body scan', 'Scan body', 'Body scan meditation',
      'Progressive muscle relaxation', 'Safe space meditation', 'Empathy meditation',
      'Focus on the present', 'Clarity meditation', 'Concentration meditation'
    ]
  };

  /// Get the time period for a specific activity.
  /// Returns 'Morning', 'Afternoon', or 'Evening'.
  static String getTimePeriod(String activity) {
    // 1. Check strict mapping
    for (var entry in _activitiesByPeriod.entries) {
      if (entry.value.contains(activity)) {
        return entry.key;
      }
    }
    
    // 2. Heuristic fallback (Case insensitive)
    final lower = activity.toLowerCase();
    
    if (lower.contains('morning') || lower.contains('wake') || lower.contains('start') || lower.contains('sun')) return 'Morning';
    if (lower.contains('lunch') || lower.contains('noon') || lower.contains('afternoon')) return 'Afternoon';
    if (lower.contains('evening') || lower.contains('night') || lower.contains('sleep') || lower.contains('bed')) return 'Evening';
    
    // 3. Default fallback based on keywords known to be common
    if(lower.contains('journal') || lower.contains('reflect') || lower.contains('review')) return 'Evening';
    if(lower.contains('focus') || lower.contains('work')) return 'Afternoon';
    if(lower.contains('affirmation') || lower.contains('intention')) return 'Morning';

    // 4. Ultimate fallback
    return 'Morning';
  }

  /// Get all activities for a specific period (for UI lists)
  static List<String> getActivitiesForPeriod(String period) {
    return _activitiesByPeriod[period] ?? [];
  }
  
  /// Get flattened list of all known activities
  static List<String> getAllActivities() {
    return _activitiesByPeriod.values.expand((element) => element).toList();
  }
}
