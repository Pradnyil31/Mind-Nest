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

  // Pre-defined techniques
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
  ];
}
