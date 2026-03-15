/// Motive-specific data for calm techniques
/// This file contains the enhanced technique definitions with motive-specific descriptions and benefits
class MotiveTechniqueData {
  /// Get motive-specific descriptions for techniques
  static const Map<String, Map<String, String>> descriptions = {
    '5-4-3-2-1': {
      'Anxiety':
          'Interrupt anxious thoughts by anchoring yourself in the present moment through your five senses',
      'Stress':
          'Ground yourself when feeling overwhelmed by focusing on immediate sensory experiences',
      'Focus':
          'Clear mental clutter and improve concentration by engaging all your senses',
      'Sleep':
          'Calm racing thoughts before bed by connecting with your physical environment',
      'Habit Building':
          'Build mindfulness habits through consistent sensory awareness practice',
    },
    'worry-banking': {
      'Anxiety':
          'Take control of anxious thoughts by scheduling dedicated worry time',
      'Stress':
          'Manage overwhelming concerns by organizing them into manageable time slots',
      'Focus':
          'Clear mental space for concentration by containing distracting worries',
      'Sleep':
          'Prevent bedtime worry spirals by setting boundaries around anxious thoughts',
      'Habit Building':
          'Develop healthy thought management habits through structured worry processing',
    },
    'body-scan': {
      'Sleep':
          'Release physical tension and prepare your body for deep, restful sleep',
      'Stress':
          'Identify and release stress-related muscle tension throughout your body',
      'Anxiety':
          'Reconnect with your body and reduce anxiety through progressive relaxation',
      'Focus':
          'Improve body awareness and mental clarity through systematic attention',
      'Habit Building':
          'Build consistent relaxation habits through regular body awareness practice',
    },
    'deep-breathing': {
      'Stress':
          'Activate your natural relaxation response to counter stress hormones',
      'Anxiety':
          'Regulate your nervous system and reduce panic symptoms through controlled breathing',
      'Sleep':
          'Slow your heart rate and prepare your body for sleep through deep breathing',
      'Focus': 'Increase oxygen flow to the brain and improve mental clarity',
      'Habit Building':
          'Establish a foundational breathing practice for daily wellness',
    },
    'positive-affirmations': {
      'Anxiety': 'Replace anxious thoughts with calming, reassuring self-talk',
      'Stress':
          'Build resilience and confidence through positive mental reinforcement',
      'Focus':
          'Enhance concentration and motivation through affirming statements',
      'Sleep':
          'Create peaceful mental conditions for rest through soothing affirmations',
      'Habit Building':
          'Strengthen commitment and motivation for positive change',
    },
    'safe-place-visualization': {
      'Anxiety':
          'Create an internal refuge where you can find immediate safety and calm',
      'Sleep':
          'Visualize peaceful environments to ease the transition into sleep',
      'Stress': 'Mentally escape to a calming place when feeling overwhelmed',
      'Focus':
          'Use visualization to create optimal mental conditions for concentration',
      'Habit Building':
          'Develop consistent visualization skills for ongoing wellness',
    },
  };

  /// Get motive-specific benefits for techniques
  static const Map<String, Map<String, List<String>>> benefits = {
    '5-4-3-2-1': {
      'Anxiety': [
        'Reduces panic symptoms',
        'Interrupts worry cycles',
        'Creates immediate safety',
      ],
      'Stress': [
        'Lowers stress hormones',
        'Provides quick relief',
        'Restores mental clarity',
      ],
      'Focus': [
        'Improves present-moment awareness',
        'Enhances concentration',
        'Reduces distractions',
      ],
      'Sleep': [
        'Calms racing thoughts',
        'Prepares mind for rest',
        'Reduces bedtime anxiety',
      ],
      'Habit Building': [
        'Builds mindfulness skills',
        'Creates consistent practice',
        'Strengthens awareness',
      ],
    },
    'worry-banking': {
      'Anxiety': [
        'Controls anxious thoughts',
        'Reduces worry frequency',
        'Improves mental organization',
      ],
      'Stress': [
        'Manages overwhelming concerns',
        'Creates mental boundaries',
        'Reduces cognitive load',
      ],
      'Focus': [
        'Clears mental distractions',
        'Improves task focus',
        'Enhances productivity',
      ],
      'Sleep': [
        'Prevents bedtime worrying',
        'Improves sleep quality',
        'Reduces nighttime anxiety',
      ],
      'Habit Building': [
        'Develops thought discipline',
        'Creates healthy boundaries',
        'Builds mental structure',
      ],
    },
    'body-scan': {
      'Sleep': [
        'Releases physical tension',
        'Improves sleep quality',
        'Reduces restlessness',
      ],
      'Stress': [
        'Identifies stress patterns',
        'Releases muscle tension',
        'Promotes relaxation',
      ],
      'Anxiety': [
        'Grounds in body awareness',
        'Reduces physical anxiety',
        'Improves self-connection',
      ],
      'Focus': [
        'Enhances body awareness',
        'Improves attention skills',
        'Reduces physical distractions',
      ],
      'Habit Building': [
        'Builds body awareness habits',
        'Creates relaxation routine',
        'Develops mindfulness',
      ],
    },
    'deep-breathing': {
      'Stress': [
        'Activates relaxation response',
        'Lowers cortisol levels',
        'Reduces blood pressure',
      ],
      'Anxiety': [
        'Regulates nervous system',
        'Reduces panic symptoms',
        'Improves emotional control',
      ],
      'Sleep': [
        'Slows heart rate',
        'Prepares body for sleep',
        'Reduces sleep anxiety',
      ],
      'Focus': [
        'Increases oxygen to brain',
        'Improves mental clarity',
        'Enhances concentration',
      ],
      'Habit Building': [
        'Creates foundational practice',
        'Builds breathing awareness',
        'Develops consistency',
      ],
    },
    'positive-affirmations': {
      'Anxiety': [
        'Replaces negative thoughts',
        'Builds self-confidence',
        'Reduces self-criticism',
      ],
      'Stress': [
        'Increases resilience',
        'Improves coping skills',
        'Builds positive mindset',
      ],
      'Focus': [
        'Enhances motivation',
        'Improves self-belief',
        'Increases determination',
      ],
      'Sleep': [
        'Creates peaceful mindset',
        'Reduces negative thoughts',
        'Promotes self-compassion',
      ],
      'Habit Building': [
        'Strengthens commitment',
        'Builds motivation',
        'Reinforces positive change',
      ],
    },
    'safe-place-visualization': {
      'Anxiety': [
        'Creates sense of safety',
        'Provides mental refuge',
        'Reduces fear responses',
      ],
      'Sleep': [
        'Promotes peaceful imagery',
        'Eases sleep transition',
        'Reduces bedtime stress',
      ],
      'Stress': [
        'Provides mental escape',
        'Reduces overwhelm',
        'Creates calm environment',
      ],
      'Focus': [
        'Optimizes mental state',
        'Reduces environmental stress',
        'Enhances concentration',
      ],
      'Habit Building': [
        'Develops visualization skills',
        'Creates positive associations',
        'Builds mental resources',
      ],
    },
  };

  /// Get primary motives for each technique
  static const Map<String, List<String>> primaryMotives = {
    '5-4-3-2-1': ['Anxiety', 'Stress'],
    'worry-banking': ['Anxiety', 'Stress'],
    'body-scan': ['Sleep', 'Stress'],
    'mindful-observation': ['Focus', 'Anxiety'],
    'present-moment': ['Anxiety', 'Focus'],
    'deep-breathing': ['Stress', 'Anxiety'],
    'alternate-nostril': ['Focus', 'Stress'],
    'positive-affirmations': ['Anxiety', 'Habit Building'],
    'self-compassion': ['Anxiety', 'Stress'],
    'gratitude-affirmations': ['Habit Building', 'Stress'],
    'loving-kindness': ['Stress', 'Habit Building'],
    'cold-water-visualization': ['Anxiety', 'Stress'],
    'safe-place-visualization': ['Anxiety', 'Sleep'],
    'light-visualization': ['Sleep', 'Stress'],
    'mountain-meditation': ['Focus', 'Stress'],
  };

  /// Get secondary motives for each technique
  static const Map<String, List<String>> secondaryMotives = {
    '5-4-3-2-1': ['Focus', 'Sleep'],
    'worry-banking': ['Focus', 'Sleep'],
    'body-scan': ['Anxiety', 'Focus'],
    'mindful-observation': ['Stress', 'Habit Building'],
    'present-moment': ['Stress', 'Sleep'],
    'deep-breathing': ['Sleep', 'Focus'],
    'alternate-nostril': ['Sleep', 'Anxiety'],
    'positive-affirmations': ['Stress', 'Focus'],
    'self-compassion': ['Sleep', 'Habit Building'],
    'gratitude-affirmations': ['Sleep', 'Focus'],
    'loving-kindness': ['Sleep', 'Focus'],
    'cold-water-visualization': ['Focus', 'Sleep'],
    'safe-place-visualization': ['Stress', 'Focus'],
    'light-visualization': ['Anxiety', 'Focus'],
    'mountain-meditation': ['Anxiety', 'Sleep'],
  };
}
