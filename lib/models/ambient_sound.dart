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
    // Nature Sounds
    AmbientSound(
      id: 'rain',
      name: 'Rain',
      emoji: '🌧️',
      category: SoundCategory.nature,
      description: 'Gentle rainfall',
    ),
    AmbientSound(
      id: 'ocean',
      name: 'Ocean Waves',
      emoji: '🌊',
      category: SoundCategory.nature,
      description: 'Peaceful ocean waves',
    ),
    AmbientSound(
      id: 'forest',
      name: 'Forest',
      emoji: '🌲',
      category: SoundCategory.nature,
      description: 'Birds and rustling leaves',
    ),
    AmbientSound(
      id: 'thunderstorm',
      name: 'Thunderstorm',
      emoji: '⛈️',
      category: SoundCategory.nature,
      description: 'Rain with distant thunder',
    ),
    AmbientSound(
      id: 'birds',
      name: 'Morning Birds',
      emoji: '🐦',
      category: SoundCategory.nature,
      description: 'Cheerful bird songs',
    ),
    AmbientSound(
      id: 'crickets',
      name: 'Night Crickets',
      emoji: '🦗',
      category: SoundCategory.nature,
      description: 'Peaceful evening crickets',
    ),
    
    // Urban Calm
    AmbientSound(
      id: 'cafe',
      name: 'Coffee Shop',
      emoji: '☕',
      category: SoundCategory.urban,
      description: 'Cozy cafe ambience',
    ),
    AmbientSound(
      id: 'library',
      name: 'Library',
      emoji: '📚',
      category: SoundCategory.urban,
      description: 'Quiet study atmosphere',
    ),
    AmbientSound(
      id: 'train',
      name: 'Train Journey',
      emoji: '🚂',
      category: SoundCategory.urban,
      description: 'Rhythmic train sounds',
    ),
    
    // Noise
    AmbientSound(
      id: 'white-noise',
      name: 'White Noise',
      emoji: '🔊',
      category: SoundCategory.noise,
      description: 'Pure white noise',
    ),
    AmbientSound(
      id: 'brown-noise',
      name: 'Brown Noise',
      emoji: '🎧',
      category: SoundCategory.noise,
      description: 'Deep, calming tone',
    ),
    AmbientSound(
      id: 'pink-noise',
      name: 'Pink Noise',
      emoji: '💤',
      category: SoundCategory.noise,
      description: 'Perfect for sleep',
    ),
    
    // Traditional
    AmbientSound(
      id: 'fireplace',
      name: 'Fireplace',
      emoji: '🔥',
      category: SoundCategory.traditional,
      description: 'Crackling fire',
    ),
    AmbientSound(
      id: 'singing-bowls',
      name: 'Singing Bowls',
      emoji: '🔔',
      category: SoundCategory.traditional,
      description: 'Tibetan bowls',
    ),
    AmbientSound(
      id: 'piano',
      name: 'Soft Piano',
      emoji: '🎹',
      category: SoundCategory.traditional,
      description: 'Gentle piano melody',
    ),
  ];

  // Helper methods
  static List<AmbientSound> getByCategory(SoundCategory category) {
    return defaults.where((s) => s.category == category).toList();
  }
}
