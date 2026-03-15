class BreathingTechnique {
  final String title;
  final String description;
  final List<int> pattern; // [inhale, hold, exhale, hold] in seconds
  final String id;

  const BreathingTechnique({
    required this.id,
    required this.title,
    required this.description,
    required this.pattern,
  });

  // Pre-defined techniques - expanded library
  static const List<BreathingTechnique> defaults = [
    BreathingTechnique(
      id: '4-7-8',
      title: '4-7-8 Relax',
      description: 'A classic technique for deep relaxation and sleep.',
      pattern: [4, 7, 8, 0], // Inhale 4, Hold 7, Exhale 8, No hold
    ),
    BreathingTechnique(
      id: 'box',
      title: 'Box Breathing',
      description: 'Used by Navy SEALs for focus and calm under pressure.',
      pattern: [4, 4, 4, 4], // Inhale 4, Hold 4, Exhale 4, Hold 4
    ),
    BreathingTechnique(
      id: 'coherent',
      title: 'Coherent Breathing',
      description: 'Balances the autonomic nervous system.',
      pattern: [6, 0, 6, 0], // Inhale 6, No hold, Exhale 6, No hold
    ),
    BreathingTechnique(
      id: '3-3-3',
      title: 'Simple 3-3-3',
      description: 'Easy breathing pattern for beginners.',
      pattern: [3, 0, 3, 0], // Inhale 3, No hold, Exhale 3, No hold
    ),
    BreathingTechnique(
      id: '5-5',
      title: 'Equal Breathing',
      description: 'Balanced inhale and exhale for steady calm.',
      pattern: [5, 0, 5, 0], // Inhale 5, No hold, Exhale 5, No hold
    ),
    BreathingTechnique(
      id: '4-4-6',
      title: 'Calming 4-4-6',
      description: 'Longer exhale to activate relaxation response.',
      pattern: [4, 4, 6, 0], // Inhale 4, Hold 4, Exhale 6, No hold
    ),
    BreathingTechnique(
      id: '7-7',
      title: 'Deep 7-7',
      description: 'Deeper breathing for advanced practitioners.',
      pattern: [7, 0, 7, 0], // Inhale 7, No hold, Exhale 7, No hold
    ),
    BreathingTechnique(
      id: '2-1-4',
      title: 'Quick Calm',
      description: 'Fast technique for immediate stress relief.',
      pattern: [2, 1, 4, 0], // Inhale 2, Hold 1, Exhale 4, No hold
    ),
    BreathingTechnique(
      id: '6-2-6-2',
      title: 'Rhythmic Box',
      description: 'Longer box breathing for deeper relaxation.',
      pattern: [6, 2, 6, 2], // Inhale 6, Hold 2, Exhale 6, Hold 2
    ),
  ];
}
