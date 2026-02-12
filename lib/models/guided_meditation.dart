enum MeditationCategory { sleep, stress, focus, anxiety, mindfulness, compassion }

class GuidedMeditation {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final MeditationCategory category;
  final String difficulty;
  final List<String> scriptSteps; // Step-by-step meditation script
  final String? thumbnailIcon; // Material icon name

  const GuidedMeditation({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.category,
    this.difficulty = 'Beginner',
    required this.scriptSteps,
    this.thumbnailIcon,
  });

  // Predefined meditation library
  static const List<GuidedMeditation> defaults = [
    GuidedMeditation(
      id: 'morning-mindfulness',
      title: 'Morning Mindfulness',
      description: 'Start your day with clarity and intention',
      durationMinutes: 10,
      category: MeditationCategory.mindfulness,
      difficulty: 'Beginner',
      thumbnailIcon: 'wb_sunny',
      scriptSteps: [
        'Find a comfortable seated position. Close your eyes gently.',
        'Take three deep breaths, inhaling through your nose and exhaling through your mouth.',
        'Notice the sensations in your body. Feel the ground beneath you.',
        'Bring your attention to your breath. Notice the natural rhythm of breathing.',
        'As thoughts arise, acknowledge them without judgment and return to your breath.',
        'Set an intention for your day. What quality do you want to bring forward?',
        'Take one final deep breath. When you\'re ready, gently open your eyes.',
      ],
    ),
    GuidedMeditation(
      id: 'body-scan-relaxation',
      title: 'Body Scan Relaxation',
      description: 'Release tension and stress from your entire body',
      durationMinutes: 15,
      category: MeditationCategory.stress,
      difficulty: 'Beginner',
      thumbnailIcon: 'self_improvement',
      scriptSteps: [
        'Lie down or sit comfortably. Close your eyes and take a deep breath.',
        'Bring awareness to your toes. Notice any sensations. Let them relax.',
        'Move your attention to your feet and ankles. Feel them soften and release.',
        'Scan up to your calves and knees. Allow any tension to melt away.',
        'Focus on your thighs and hips. Breathe into any tightness.',
        'Notice your belly and chest. Feel them rise and fall with each breath.',
        'Bring awareness to your shoulders. Let them drop away from your ears.',
        'Scan your arms, hands, and fingers. Feel warmth and relaxation.',
        'Notice your neck and jaw. Allow them to soften completely.',
        'Finally, scan your entire body. Feel yourself fully relaxed.',
        'Take three deep breaths. Gently wiggle your fingers and toes.',
        'When you\'re ready, slowly open your eyes.',
      ],
    ),
    GuidedMeditation(
      id: 'deep-sleep-journey',
      title: 'Deep Sleep Journey',
      description: 'Drift into peaceful, restorative sleep',
      durationMinutes: 20,
      category: MeditationCategory.sleep,
      difficulty: 'Beginner',
      thumbnailIcon: 'nightlight',
      scriptSteps: [
        'Settle into bed and make yourself comfortable. Close your eyes.',
        'Take a slow, deep breath in... and a long, slow breath out.',
        'Feel your body becoming heavy, sinking into the mattress.',
        'Imagine a warm, golden light starting at the top of your head.',
        'This light slowly moves down, relaxing every muscle it touches.',
        'It flows down your face, neck, and shoulders. Feel the warmth.',
        'The light continues down your arms, chest, and through your torso.',
        'It moves through your hips, legs, and all the way to your toes.',
        'Your entire body is now wrapped in this peaceful, warm light.',
        'With each breath, you sink deeper into relaxation and sleep.',
        'Let go of the day. You are safe. You are calm.',
        'Allow yourself to drift into deep, restorative sleep.',
      ],
    ),
    GuidedMeditation(
      id: 'anxiety-relief',
      title: 'Anxiety Relief',
      description: 'Calm racing thoughts and find your center',
      durationMinutes: 10,
      category: MeditationCategory.anxiety,
      difficulty: 'Beginner',
      thumbnailIcon: 'waves',
      scriptSteps: [
        'Sit comfortably and place one hand on your heart. Close your eyes.',
        'Take a deep breath in for 4 counts... hold for 4... exhale for 6.',
        'Notice the feeling of your hand rising and falling with your breath.',
        'Acknowledge any anxious thoughts without trying to change them.',
        'Imagine each thought as a cloud drifting by in the sky.',
        'You are not your thoughts. You are the observer of your thoughts.',
        'Return your attention to the rhythm of your breathing.',
        'Repeat silently: "I am safe. I am calm. This moment is all there is."',
        'Feel your body grounded and supported where you sit.',
        'Take three more deep breaths, releasing tension with each exhale.',
        'When you\'re ready, gently open your eyes and return to the present.',
      ],
    ),
    GuidedMeditation(
      id: 'focus-clarity',
      title: 'Focus & Clarity',
      description: 'Sharpen your mind and enhance concentration',
      durationMinutes: 15,
      category: MeditationCategory.focus,
      difficulty: 'Intermediate',
      thumbnailIcon: 'center_focus_strong',
      scriptSteps: [
        'Sit upright with a straight spine. Close your eyes.',
        'Take three energizing breaths, breathing in clarity and out distraction.',
        'Visualize your mind as a clear, still lake.',
        'Notice any ripples (thoughts) on the surface. Let them settle.',
        'Focus your attention on a single point - perhaps your breath.',
        'Each time your mind wanders, gently guide it back without judgment.',
        'See your focus as a muscle you\'re training with each return.',
        'Imagine a bright light at the center of your forehead - your mind\'s eye.',
        'This light represents your mental clarity and concentration.',
        'Feel it growing brighter and more steady with each breath.',
        'Set an intention to carry this clarity into your work.',
        'Take a final deep breath. Open your eyes with renewed focus.',
      ],
    ),
    GuidedMeditation(
      id: 'loving-kindness',
      title: 'Loving-Kindness',
      description: 'Cultivate self-compassion and kindness',
      durationMinutes: 10,
      category: MeditationCategory.compassion,
      difficulty: 'Beginner',
      thumbnailIcon: 'favorite',
      scriptSteps: [
        'Sit comfortably with your hands resting on your lap. Close your eyes.',
        'Take a few deep breaths and settle into this moment.',
        'Bring to mind an image of yourself. See yourself with kindness.',
        'Repeat silently: "May I be happy. May I be healthy. May I be at peace."',
        'Feel these words resonating in your heart. You deserve compassion.',
        'Now think of someone you love. Picture their face.',
        'Send them kindness: "May you be happy. May you be healthy. May you be at peace."',
        'Extend this to someone neutral - perhaps a stranger you passed today.',
        'Finally, if you can, extend kindness even to someone you find difficult.',
        'Remember that everyone wants to be happy and free from suffering.',
        'Return to yourself. Place a hand on your heart.',
        'Take a deep breath and open your eyes, carrying this kindness forward.',
      ],
    ),
    GuidedMeditation(
      id: 'quick-reset',
      title: 'Quick Reset',
      description: 'A brief pause to center yourself',
      durationMinutes: 5,
      category: MeditationCategory.mindfulness,
      difficulty: 'Beginner',
      thumbnailIcon: 'refresh',
      scriptSteps: [
        'Wherever you are, pause and take a comfortable position.',
        'Close your eyes or lower your gaze.',
        'Take a deep breath in through your nose... hold... and exhale slowly.',
        'Notice five things: What do you hear? What do you feel?',
        'Bring your attention to your breath. Follow one full breath cycle.',
        'Silently say: "This moment is enough. I am enough."',
        'Take one more deep breath. Feel yourself reset and refreshed.',
        'When you\'re ready, open your eyes and continue your day.',
      ],
    ),
  ];

  // Helper method to get meditations by category
  static List<GuidedMeditation> getByCategory(MeditationCategory category) {
    return defaults.where((m) => m.category == category).toList();
  }

  // Helper method to get meditations by duration
  static List<GuidedMeditation> getByDuration(int maxMinutes) {
    return defaults.where((m) => m.durationMinutes <= maxMinutes).toList();
  }

  // Helper method to get meditations by user motive
  static List<GuidedMeditation> getByMotive(String? motive) {
    if (motive == null) return defaults;
    
    // Map motives to relevant meditation categories
    final Map<String, List<MeditationCategory>> motiveMapping = {
      'Sleep': [MeditationCategory.sleep, MeditationCategory.stress],
      'Stress': [MeditationCategory.stress, MeditationCategory.mindfulness, MeditationCategory.compassion],
      'Anxiety': [MeditationCategory.anxiety, MeditationCategory.mindfulness, MeditationCategory.stress],
      'Focus': [MeditationCategory.focus, MeditationCategory.mindfulness],
      'Habit Building': [MeditationCategory.mindfulness, MeditationCategory.compassion],
    };
    
    final relevantCategories = motiveMapping[motive] ?? [];
    if (relevantCategories.isEmpty) return defaults;
    
    // Get meditations matching the motive's categories
    final matched = defaults.where((m) => relevantCategories.contains(m.category)).toList();
    
    // Add others at the end
    final others = defaults.where((m) => !relevantCategories.contains(m.category)).toList();
    
    return [...matched, ...others];
  }

  // Check if meditation is relevant for a specific motive
  static bool isRelevantForMotive(GuidedMeditation meditation, String? motive) {
    if (motive == null) return true;
    
    final Map<String, List<MeditationCategory>> motiveMapping = {
      'Sleep': [MeditationCategory.sleep, MeditationCategory.stress],
      'Stress': [MeditationCategory.stress, MeditationCategory.mindfulness, MeditationCategory.compassion],
      'Anxiety': [MeditationCategory.anxiety, MeditationCategory.mindfulness, MeditationCategory.stress],
      'Focus': [MeditationCategory.focus, MeditationCategory.mindfulness],
      'Habit Building': [MeditationCategory.mindfulness, MeditationCategory.compassion],
    };
    
    final relevantCategories = motiveMapping[motive] ?? [];
    return relevantCategories.contains(meditation.category);
  }
}
