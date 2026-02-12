enum TechniqueType { grounding, affirmation, breathing, visualization }

class CalmTechnique {
  final String id;
  final String title;
  final String description;
  final String icon;
  final TechniqueType type;
  final int durationMinutes;
  final List<String>? steps; // For step-by-step techniques
  final List<String>? content; // For affirmations, quotes, etc.

  const CalmTechnique({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    this.durationMinutes = 5,
    this.steps,
    this.content,
  });

  // Predefined calm techniques
  static const List<CalmTechnique> defaults = [
    CalmTechnique(
      id: '5-4-3-2-1',
      title: '5-4-3-2-1 Grounding',
      description: 'Use your senses to calm anxiety',
      icon: '🧘',
      type: TechniqueType.grounding,
      durationMinutes: 3,
      steps: [
        'Take a deep breath and look around you.',
        'Name 5 things you can see around you.',
        'Name 4 things you can physically feel (texture of clothes, ground beneath feet, etc.).',
        'Name 3 things you can hear right now.',
        'Name 2 things you can smell (or 2 scents you like).',
        'Name 1 thing you can taste (or your favorite food).',
        'Take three deep breaths. You are present and safe.',
      ],
    ),
    CalmTechnique(
      id: 'positive-affirmations',
      title: 'Calming Affirmations',
      description: 'Positive self-talk for peace',
      icon: '💬',
      type: TechniqueType.affirmation,
      durationMinutes: 2,
      content: [
        'I am safe. I am calm. I am at peace.',
        'This feeling is temporary. It will pass.',
        'I trust myself to handle whatever comes.',
        'I release what I cannot control.',
        'I breathe in peace, I breathe out tension.',
        'I am doing the best I can, and that is enough.',
        'I deserve rest and relaxation.',
        'One step at a time, one breath at a time.',
        'I am stronger than my anxiety.',
        'I choose peace over worry.',
        'My mind is calm, my body is relaxed.',
        'I am grounded in the present moment.',
        'I let go of what no longer serves me.',
        'I am worthy of love and kindness.',
        'Everything I need is within me.',
      ],
    ),
    CalmTechnique(
      id: 'worry-banking',
      title: 'Worry Banking',
      description: 'Set aside worries for later',
      icon: '📝',
      type: TechniqueType.grounding,
      durationMinutes: 5,
      steps: [
        'When worries arise, acknowledge them without judgment.',
        'Write down each worry briefly in your worry bank.',
        'Set a specific "worry time" later today (e.g., 7 PM for 10 minutes).',
        'Tell yourself: "I will think about this during worry time, not now."',
        'Return your focus to the present moment.',
        'During worry time, review your list and address what you can.',
        'Let go of what you cannot control.',
      ],
    ),
    CalmTechnique(
      id: 'cold-water-visualization',
      title: 'Cold Water Reset',
      description: 'Visualize calming cold sensation',
      icon: '❄️',
      type: TechniqueType.visualization,
      durationMinutes: 2,
      steps: [
        'Close your eyes and take a deep breath.',
        'Imagine plunging your hands into ice-cold water.',
        'Feel the shocking cold sensation spreading through your fingers.',
        'Notice how it captures all your attention.',
        'The cold pulls you into the present moment.',
        'Now imagine the cold water washing away your anxiety.',
        'Take three deep breaths and open your eyes.',
        'You are calm, present, and refreshed.',
      ],
    ),
  ];

  // Get techniques by type
  static List<CalmTechnique> getByType(TechniqueType type) {
    return defaults.where((t) => t.type == type).toList();
  }
}
