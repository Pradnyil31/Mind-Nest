import 'dart:async';
import 'package:logger/logger.dart';
import '../../../services/firestore_service.dart';
import '../models/sound_preset.dart';
import '../../../models/ambient_sound.dart';

/// Service for managing sound presets including saving, loading, and recommendations
class SoundPresetService {
  final Logger _logger = Logger();
  final FirestoreService _firestoreService;

  SoundPresetService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  static const String _collectionName = 'sound_presets';

  /// Save a sound preset for a user
  Future<void> savePreset({
    required String userId,
    required String name,
    required String motive,
    required Set<String> soundIds,
    required Map<String, double> volumes,
    required double masterVolume,
  }) async {
    try {
      final presetId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      final preset = SoundPreset(
        id: presetId,
        name: name,
        motive: motive,
        soundIds: soundIds,
        volumes: volumes,
        masterVolume: masterVolume,
        createdAt: DateTime.now(),
        isDefault: false,
      );

      await _firestoreService.setDocument(
        collection: _collectionName,
        docId: presetId,
        data: {...preset.toJson(), 'userId': userId},
      );

      _logger.i('Saved sound preset: $name for user: $userId');
    } catch (e) {
      _logger.e('Failed to save sound preset: $e');
      rethrow;
    }
  }

  /// Load all presets for a user
  Future<List<SoundPreset>> loadUserPresets(String userId) async {
    try {
      final querySnapshot = await _firestoreService.getDocumentsWhere(
        collection: _collectionName,
        field: 'userId',
        value: userId,
      );

      final presets = querySnapshot.docs
          .map(
            (doc) => SoundPreset.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      // Sort by creation date, newest first
      presets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _logger.i('Loaded ${presets.length} presets for user: $userId');
      return presets;
    } catch (e) {
      _logger.e('Failed to load user presets: $e');
      return [];
    }
  }

  /// Delete a preset
  Future<void> deletePreset(String presetId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: _collectionName,
        docId: presetId,
      );

      _logger.i('Deleted preset: $presetId');
    } catch (e) {
      _logger.e('Failed to delete preset: $e');
      rethrow;
    }
  }

  /// Get motive-specific preset recommendations
  List<SoundPreset> getMotiveRecommendations(String motive) {
    try {
      final recommendations = SoundPreset.getPresetsForMotive(motive);
      _logger.i(
        'Generated ${recommendations.length} recommendations for motive: $motive',
      );
      return recommendations;
    } catch (e) {
      _logger.e('Failed to get motive recommendations: $e');
      return [];
    }
  }

  /// Get all available sounds for preset creation
  List<AmbientSound> getAvailableSounds() {
    return AmbientSound.defaults;
  }

  /// Get recommended sounds for a specific motive
  List<AmbientSound> getRecommendedSoundsForMotive(String motive) {
    final allSounds = AmbientSound.defaults;

    switch (motive.toLowerCase()) {
      case 'sleep':
        return allSounds
            .where(
              (s) =>
                  s.category == SoundCategory.nature ||
                  s.category == SoundCategory.noise ||
                  s.id == 'piano' ||
                  s.id == 'fireplace',
            )
            .toList();

      case 'focus':
        return allSounds
            .where(
              (s) =>
                  s.category == SoundCategory.noise ||
                  s.id == 'library' ||
                  s.id == 'cafe' ||
                  s.id == 'white-noise' ||
                  s.id == 'brown-noise',
            )
            .toList();

      case 'anxiety':
      case 'stress':
        return allSounds
            .where(
              (s) =>
                  s.id == 'rain' ||
                  s.id == 'ocean' ||
                  s.id == 'fireplace' ||
                  s.id == 'brown-noise' ||
                  s.id == 'singing-bowls',
            )
            .toList();

      case 'habit building':
        return allSounds
            .where(
              (s) =>
                  s.category == SoundCategory.traditional ||
                  s.id == 'library' ||
                  s.id == 'cafe',
            )
            .toList();

      default:
        return allSounds.take(8).toList();
    }
  }

  /// Create a preset from current ambient sound state
  SoundPreset createPresetFromState({
    required String name,
    required String motive,
    required Set<String> activeSounds,
    required Map<String, double> individualVolumes,
    required double masterVolume,
  }) {
    final presetId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    return SoundPreset(
      id: presetId,
      name: name,
      motive: motive,
      soundIds: activeSounds,
      volumes: Map<String, double>.from(individualVolumes)
        ..removeWhere((key, value) => !activeSounds.contains(key)),
      masterVolume: masterVolume,
      createdAt: DateTime.now(),
      isDefault: false,
    );
  }

  /// Apply a preset to get the configuration
  Map<String, dynamic> applyPreset(SoundPreset preset) {
    return {
      'soundIds': preset.soundIds,
      'volumes': preset.volumes,
      'masterVolume': preset.masterVolume,
    };
  }

  /// Get quick access presets for a motive (top 3 most used or recommended)
  List<SoundPreset> getQuickAccessPresets(
    String motive,
    List<SoundPreset> userPresets,
  ) {
    // Combine user presets and default recommendations
    final motiveUserPresets = userPresets
        .where((p) => p.motive.toLowerCase() == motive.toLowerCase())
        .take(2)
        .toList();

    final recommendations = getMotiveRecommendations(motive).take(1).toList();

    final quickAccess = <SoundPreset>[];
    quickAccess.addAll(motiveUserPresets);
    quickAccess.addAll(recommendations);

    return quickAccess.take(3).toList();
  }

  /// Validate preset data before saving
  bool validatePreset({
    required String name,
    required Set<String> soundIds,
    required Map<String, double> volumes,
    required double masterVolume,
  }) {
    if (name.trim().isEmpty) return false;
    if (soundIds.isEmpty) return false;
    if (masterVolume < 0.0 || masterVolume > 1.0) return false;

    for (final volume in volumes.values) {
      if (volume < 0.0 || volume > 1.0) return false;
    }

    return true;
  }
}
