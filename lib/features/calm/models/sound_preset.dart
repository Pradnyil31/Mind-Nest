/// Model for ambient sound presets that can be saved and recalled
class SoundPreset {
  final String id;
  final String name;
  final String motive;
  final Set<String> soundIds;
  final Map<String, double> volumes;
  final double masterVolume;
  final DateTime createdAt;
  final bool isDefault;

  const SoundPreset({
    required this.id,
    required this.name,
    required this.motive,
    required this.soundIds,
    required this.volumes,
    required this.masterVolume,
    required this.createdAt,
    this.isDefault = false,
  });

  /// Create a copy with updated values
  SoundPreset copyWith({
    String? id,
    String? name,
    String? motive,
    Set<String>? soundIds,
    Map<String, double>? volumes,
    double? masterVolume,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return SoundPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      motive: motive ?? this.motive,
      soundIds: soundIds ?? this.soundIds,
      volumes: volumes ?? this.volumes,
      masterVolume: masterVolume ?? this.masterVolume,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'motive': motive,
      'soundIds': soundIds.toList(),
      'volumes': volumes,
      'masterVolume': masterVolume,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  /// Create from JSON
  factory SoundPreset.fromJson(Map<String, dynamic> json) {
    return SoundPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      motive: json['motive'] as String,
      soundIds: Set<String>.from(json['soundIds'] as List),
      volumes: Map<String, double>.from(json['volumes'] as Map),
      masterVolume: (json['masterVolume'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Get default presets for each motive
  static List<SoundPreset> getDefaultPresets() {
    final now = DateTime.now();

    return [
      // Sleep presets
      SoundPreset(
        id: 'sleep-default-1',
        name: 'Peaceful Night',
        motive: 'Sleep',
        soundIds: {'rain', 'fireplace'},
        volumes: {'rain': 0.8, 'fireplace': 0.6},
        masterVolume: 0.7,
        createdAt: now,
        isDefault: true,
      ),
      SoundPreset(
        id: 'sleep-default-2',
        name: 'Deep Rest',
        motive: 'Sleep',
        soundIds: {'brown-noise', 'piano'},
        volumes: {'brown-noise': 0.7, 'piano': 0.5},
        masterVolume: 0.6,
        createdAt: now,
        isDefault: true,
      ),

      // Stress presets
      SoundPreset(
        id: 'stress-default-1',
        name: 'Ocean Calm',
        motive: 'Stress',
        soundIds: {'ocean', 'singing-bowls'},
        volumes: {'ocean': 0.8, 'singing-bowls': 0.4},
        masterVolume: 0.7,
        createdAt: now,
        isDefault: true,
      ),
      SoundPreset(
        id: 'stress-default-2',
        name: 'Forest Retreat',
        motive: 'Stress',
        soundIds: {'forest', 'birds'},
        volumes: {'forest': 0.7, 'birds': 0.5},
        masterVolume: 0.8,
        createdAt: now,
        isDefault: true,
      ),

      // Anxiety presets
      SoundPreset(
        id: 'anxiety-default-1',
        name: 'Gentle Rain',
        motive: 'Anxiety',
        soundIds: {'rain'},
        volumes: {'rain': 0.8},
        masterVolume: 0.7,
        createdAt: now,
        isDefault: true,
      ),
      SoundPreset(
        id: 'anxiety-default-2',
        name: 'Warm Fireplace',
        motive: 'Anxiety',
        soundIds: {'fireplace', 'brown-noise'},
        volumes: {'fireplace': 0.7, 'brown-noise': 0.4},
        masterVolume: 0.6,
        createdAt: now,
        isDefault: true,
      ),

      // Focus presets
      SoundPreset(
        id: 'focus-default-1',
        name: 'Study Session',
        motive: 'Focus',
        soundIds: {'white-noise', 'library'},
        volumes: {'white-noise': 0.6, 'library': 0.4},
        masterVolume: 0.5,
        createdAt: now,
        isDefault: true,
      ),
      SoundPreset(
        id: 'focus-default-2',
        name: 'Concentration',
        motive: 'Focus',
        soundIds: {'brown-noise'},
        volumes: {'brown-noise': 0.7},
        masterVolume: 0.6,
        createdAt: now,
        isDefault: true,
      ),

      // Habit Building presets
      SoundPreset(
        id: 'habit-default-1',
        name: 'Motivation Mix',
        motive: 'Habit Building',
        soundIds: {'singing-bowls', 'library'},
        volumes: {'singing-bowls': 0.6, 'library': 0.5},
        masterVolume: 0.7,
        createdAt: now,
        isDefault: true,
      ),
      SoundPreset(
        id: 'habit-default-2',
        name: 'Growth Sounds',
        motive: 'Habit Building',
        soundIds: {'cafe', 'birds'},
        volumes: {'cafe': 0.6, 'birds': 0.4},
        masterVolume: 0.8,
        createdAt: now,
        isDefault: true,
      ),
    ];
  }

  /// Get presets for a specific motive
  static List<SoundPreset> getPresetsForMotive(String motive) {
    return getDefaultPresets()
        .where((preset) => preset.motive.toLowerCase() == motive.toLowerCase())
        .toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoundPreset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SoundPreset(id: $id, name: $name, motive: $motive, sounds: ${soundIds.length})';
  }
}
