enum SoundCategory { nature, urban, noise, traditional }

class AmbientSound {
  final String id;
  final String name;
  final String emoji;
  final SoundCategory category;
  final String description;

  const AmbientSound({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.description,
  });

  // Predefined ambient sounds library
  static const List<AmbientSound> defaults = [
    AmbientSound(
      id: 'violin',
      name: 'Violin',
      emoji: '🎻',
      category: SoundCategory.nature,
      description: 'Calming violin strings',
    ),
    AmbientSound(
      id: 'piano',
      name: 'Piano',
      emoji: '🎹',
      category: SoundCategory.nature,
      description: 'Gentle piano melody',
    ),
    AmbientSound(
      id: 'forest',
      name: 'Deep Forest',
      emoji: '🌲',
      category: SoundCategory.nature,
      description: 'Birds and rustling leaves',
    ),
  ];

  // Helper methods
  static List<AmbientSound> getByCategory(SoundCategory category) {
    return defaults.where((s) => s.category == category).toList();
  }
}
