import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'error_recovery_service.dart';
import '../models/mood_session.dart';
import '../models/sound_preset.dart';

/// Service for ensuring data integrity and providing recovery mechanisms
class DataIntegrityService {
  final ErrorRecoveryService _errorRecovery;
  static const String _backupPrefix = 'calm_backup_';
  static const String _checksumPrefix = 'calm_checksum_';

  DataIntegrityService({ErrorRecoveryService? errorRecovery})
    : _errorRecovery = errorRecovery ?? ErrorRecoveryService();

  /// Validates and stores data with integrity protection
  Future<bool> storeWithIntegrity<T>(
    String key,
    T data,
    Map<String, dynamic> Function(T) serializer,
  ) async {
    try {
      return await _errorRecovery.withRetry(() async {
        final prefs = await SharedPreferences.getInstance();

        // Serialize data
        final serializedData = serializer(data);
        final jsonString = jsonEncode(serializedData);

        // Generate checksum
        final checksum = _generateChecksum(jsonString);

        // Create backup of existing data
        await _createBackup(key, prefs);

        // Store data and checksum atomically
        final success =
            await prefs.setString(key, jsonString) &&
            await prefs.setString('$_checksumPrefix$key', checksum);

        if (!success) {
          throw DataIntegrityException('Failed to store data atomically', key);
        }

        developer.log(
          'Data stored with integrity protection: $key',
          name: 'DataIntegrityService',
        );

        return true;
      }, operationName: 'storeWithIntegrity($key)');
    } catch (e) {
      developer.log(
        'Failed to store data with integrity: $key, error: $e',
        name: 'DataIntegrityService',
        error: e,
      );
      return false;
    }
  }

  /// Retrieves and validates data integrity
  Future<T?> retrieveWithIntegrity<T>(
    String key,
    T Function(Map<String, dynamic>) deserializer,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;

      final storedChecksum = prefs.getString('$_checksumPrefix$key');
      if (storedChecksum == null) {
        developer.log(
          'Missing checksum for data: $key',
          name: 'DataIntegrityService',
        );
        return await _attemptDataRecovery<T>(key, deserializer, prefs);
      }

      // Verify data integrity
      final currentChecksum = _generateChecksum(jsonString);
      if (currentChecksum != storedChecksum) {
        developer.log(
          'Data integrity check failed for: $key',
          name: 'DataIntegrityService',
        );
        return await _attemptDataRecovery<T>(key, deserializer, prefs);
      }

      // Deserialize data
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return deserializer(data);
    } catch (e) {
      developer.log(
        'Failed to retrieve data with integrity: $key, error: $e',
        name: 'DataIntegrityService',
        error: e,
      );
      return null;
    }
  }

  /// Creates a backup of existing data before modification
  Future<void> _createBackup(String key, SharedPreferences prefs) async {
    try {
      final existingData = prefs.getString(key);
      if (existingData != null) {
        final backupKey = '$_backupPrefix$key';
        await prefs.setString(backupKey, existingData);

        // Also backup the checksum
        final existingChecksum = prefs.getString('$_checksumPrefix$key');
        if (existingChecksum != null) {
          await prefs.setString('$_checksumPrefix$backupKey', existingChecksum);
        }
      }
    } catch (e) {
      developer.log(
        'Failed to create backup for: $key, error: $e',
        name: 'DataIntegrityService',
        error: e,
      );
    }
  }

  /// Attempts to recover data from backup or provide safe defaults
  Future<T?> _attemptDataRecovery<T>(
    String key,
    T Function(Map<String, dynamic>) deserializer,
    SharedPreferences prefs,
  ) async {
    developer.log(
      'Attempting data recovery for: $key',
      name: 'DataIntegrityService',
    );

    // Try to recover from backup
    final backupKey = '$_backupPrefix$key';
    final backupData = prefs.getString(backupKey);

    if (backupData != null) {
      try {
        // Verify backup integrity if checksum exists
        final backupChecksum = prefs.getString('$_checksumPrefix$backupKey');
        if (backupChecksum != null) {
          final currentChecksum = _generateChecksum(backupData);
          if (currentChecksum != backupChecksum) {
            developer.log(
              'Backup data also corrupted for: $key',
              name: 'DataIntegrityService',
            );
            return null;
          }
        }

        // Restore from backup
        final data = jsonDecode(backupData) as Map<String, dynamic>;
        final recovered = deserializer(data);

        // Restore the main data with the backup
        await prefs.setString(key, backupData);
        if (backupChecksum != null) {
          await prefs.setString('$_checksumPrefix$key', backupChecksum);
        }

        developer.log(
          'Successfully recovered data from backup: $key',
          name: 'DataIntegrityService',
        );

        return recovered;
      } catch (e) {
        developer.log(
          'Failed to recover from backup: $key, error: $e',
          name: 'DataIntegrityService',
          error: e,
        );
      }
    }

    // No recovery possible
    developer.log(
      'No recovery possible for: $key',
      name: 'DataIntegrityService',
    );
    return null;
  }

  /// Generates SHA-256 checksum for data integrity verification
  String _generateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validates mood session data integrity
  bool validateMoodSession(MoodSession session) {
    return _errorRecovery.validateDataIntegrity(session, (session) {
      // Validate required fields
      if (session.id.isEmpty ||
          session.userId.isEmpty ||
          session.techniqueId.isEmpty) {
        return false;
      }

      // Validate mood ratings if present
      if (session.preMoodRating != null) {
        if (session.preMoodRating! < 1 || session.preMoodRating! > 10) {
          return false;
        }
      }

      if (session.postMoodRating != null) {
        if (session.postMoodRating! < 1 || session.postMoodRating! > 10) {
          return false;
        }
      }

      // Validate timestamps
      if (session.endTime != null &&
          session.endTime!.isBefore(session.startTime)) {
        return false;
      }

      // Validate mood improvement calculation
      if (session.moodImprovement != null &&
          (session.preMoodRating == null || session.postMoodRating == null)) {
        return false;
      }

      return true;
    });
  }

  /// Validates sound preset data integrity
  bool validateSoundPreset(SoundPreset preset) {
    return _errorRecovery.validateDataIntegrity(preset, (preset) {
      // Validate required fields
      if (preset.id.isEmpty || preset.name.isEmpty || preset.motive.isEmpty) {
        return false;
      }

      // Validate sound IDs are not empty
      if (preset.soundIds.isEmpty || preset.soundIds.any((id) => id.isEmpty)) {
        return false;
      }

      // Validate volume ranges
      if (preset.masterVolume < 0.0 || preset.masterVolume > 1.0) {
        return false;
      }

      for (final volume in preset.volumes.values) {
        if (volume < 0.0 || volume > 1.0) {
          return false;
        }
      }

      // Validate that all sound IDs have corresponding volumes
      for (final soundId in preset.soundIds) {
        if (!preset.volumes.containsKey(soundId)) {
          return false;
        }
      }

      return true;
    });
  }

  /// Performs data integrity check on all stored calm data
  Future<Map<String, bool>> performIntegrityCheck() async {
    final results = <String, bool>{};

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) =>
            key.startsWith('calm_') &&
            !key.startsWith(_backupPrefix) &&
            !key.startsWith(_checksumPrefix),
      );

      for (final key in keys) {
        try {
          final jsonString = prefs.getString(key);
          if (jsonString == null) {
            results[key] = false;
            continue;
          }

          final storedChecksum = prefs.getString('$_checksumPrefix$key');
          if (storedChecksum == null) {
            results[key] = false;
            continue;
          }

          final currentChecksum = _generateChecksum(jsonString);
          results[key] = currentChecksum == storedChecksum;
        } catch (e) {
          results[key] = false;
          developer.log(
            'Integrity check failed for $key: $e',
            name: 'DataIntegrityService',
            error: e,
          );
        }
      }
    } catch (e) {
      developer.log(
        'Failed to perform integrity check: $e',
        name: 'DataIntegrityService',
        error: e,
      );
    }

    return results;
  }

  /// Clears corrupted data and backups
  Future<bool> clearCorruptedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(key);
      await prefs.remove('$_checksumPrefix$key');
      await prefs.remove('$_backupPrefix$key');
      await prefs.remove('$_checksumPrefix$_backupPrefix$key');

      developer.log(
        'Cleared corrupted data for: $key',
        name: 'DataIntegrityService',
      );

      return true;
    } catch (e) {
      developer.log(
        'Failed to clear corrupted data for $key: $e',
        name: 'DataIntegrityService',
        error: e,
      );
      return false;
    }
  }

  /// Gets storage health statistics
  Future<Map<String, dynamic>> getStorageHealth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      final calmKeys = allKeys.where((key) => key.startsWith('calm_')).toList();
      final backupKeys = allKeys
          .where((key) => key.startsWith(_backupPrefix))
          .toList();
      final checksumKeys = allKeys
          .where((key) => key.startsWith(_checksumPrefix))
          .toList();

      final integrityResults = await performIntegrityCheck();
      final corruptedCount = integrityResults.values
          .where((valid) => !valid)
          .length;

      return {
        'totalCalmKeys': calmKeys.length,
        'backupKeys': backupKeys.length,
        'checksumKeys': checksumKeys.length,
        'integrityChecked': integrityResults.length,
        'corruptedData': corruptedCount,
        'healthScore': integrityResults.isEmpty
            ? 1.0
            : (integrityResults.length - corruptedCount) /
                  integrityResults.length,
      };
    } catch (e) {
      developer.log(
        'Failed to get storage health: $e',
        name: 'DataIntegrityService',
        error: e,
      );
      return {'error': e.toString()};
    }
  }
}
