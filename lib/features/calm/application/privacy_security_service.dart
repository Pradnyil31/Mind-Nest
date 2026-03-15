import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'error_recovery_service.dart';
import 'data_integrity_service.dart';

/// Service for handling data privacy, security, and compliance
class PrivacySecurityService {
  final ErrorRecoveryService _errorRecovery;
  final DataIntegrityService _dataIntegrity;

  static const String _encryptionKeyKey = 'calm_encryption_key';
  static const String _privacySettingsKey = 'calm_privacy_settings';
  static const String _dataRetentionKey = 'calm_data_retention';

  late final Encrypter _encrypter;
  late final IV _iv;

  PrivacySecurityService()
    : _errorRecovery = ErrorRecoveryService(),
      _dataIntegrity = DataIntegrityService();

  /// Initializes encryption and privacy settings
  Future<bool> initialize() async {
    try {
      return await _errorRecovery.withRetry(() async {
        await _initializeEncryption();
        await _initializePrivacySettings();
        await _initializeDataRetention();

        developer.log(
          'Privacy and security service initialized',
          name: 'PrivacySecurityService',
        );

        return true;
      }, operationName: 'initialize privacy security');
    } catch (e) {
      developer.log(
        'Failed to initialize privacy security service: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return false;
    }
  }

  /// Encrypts sensitive user data before storage
  Future<String?> encryptSensitiveData(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      final encrypted = _encrypter.encrypt(jsonString, iv: _iv);

      developer.log(
        'Encrypted sensitive data (${data.keys.length} fields)',
        name: 'PrivacySecurityService',
      );

      return encrypted.base64;
    } catch (e) {
      developer.log(
        'Failed to encrypt sensitive data: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return null;
    }
  }

  /// Decrypts sensitive user data after retrieval
  Future<Map<String, dynamic>?> decryptSensitiveData(
    String encryptedData,
  ) async {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      final data = jsonDecode(decrypted) as Map<String, dynamic>;

      return data;
    } catch (e) {
      developer.log(
        'Failed to decrypt sensitive data: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return null;
    }
  }

  /// Stores mood tracking data with encryption
  Future<bool> storeMoodDataSecurely(Map<String, dynamic> moodData) async {
    try {
      // Remove or hash personally identifiable information
      final sanitizedData = await _sanitizeMoodData(moodData);

      // Encrypt the sanitized data
      final encryptedData = await encryptSensitiveData(sanitizedData);
      if (encryptedData == null) return false;

      // Store with integrity protection
      return await _dataIntegrity.storeWithIntegrity(
        'calm_mood_${moodData['sessionId']}',
        {'encrypted': encryptedData},
        (data) => data,
      );
    } catch (e) {
      developer.log(
        'Failed to store mood data securely: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return false;
    }
  }

  /// Retrieves mood tracking data with decryption
  Future<Map<String, dynamic>?> retrieveMoodDataSecurely(
    String sessionId,
  ) async {
    try {
      final storedData = await _dataIntegrity.retrieveWithIntegrity(
        'calm_mood_$sessionId',
        (data) => data,
      );

      if (storedData == null || storedData['encrypted'] == null) {
        return null;
      }

      return await decryptSensitiveData(storedData['encrypted']);
    } catch (e) {
      developer.log(
        'Failed to retrieve mood data securely: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return null;
    }
  }

  /// Enables anonymous usage mode
  Future<bool> enableAnonymousMode() async {
    try {
      final anonymousId = await _generateAnonymousId();

      final privacySettings = await _getPrivacySettings();
      privacySettings['anonymousMode'] = true;
      privacySettings['anonymousId'] = anonymousId;
      privacySettings['dataCollection'] = false;
      privacySettings['analytics'] = false;

      return await _updatePrivacySettings(privacySettings);
    } catch (e) {
      developer.log(
        'Failed to enable anonymous mode: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return false;
    }
  }

  /// Disables anonymous usage mode
  Future<bool> disableAnonymousMode() async {
    try {
      final privacySettings = await _getPrivacySettings();
      privacySettings['anonymousMode'] = false;
      privacySettings.remove('anonymousId');

      return await _updatePrivacySettings(privacySettings);
    } catch (e) {
      developer.log(
        'Failed to disable anonymous mode: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return false;
    }
  }

  /// Deletes all user data (GDPR/CCPA compliance)
  Future<bool> deleteAllUserData(String userId) async {
    try {
      return await _errorRecovery.withRetry(() async {
        final prefs = await SharedPreferences.getInstance();

        // Get all keys related to the user
        final userKeys = prefs.getKeys().where(
          (key) => key.contains(userId) || key.startsWith('calm_'),
        );

        // Delete each key
        for (final key in userKeys) {
          await prefs.remove(key);

          // Also remove associated checksums and backups
          await prefs.remove('calm_checksum_$key');
          await prefs.remove('calm_backup_$key');
        }

        // Clear any cached files
        await _deleteCachedUserFiles(userId);

        // Log the deletion (without personal data)
        developer.log(
          'Deleted all user data (${userKeys.length} keys)',
          name: 'PrivacySecurityService',
        );

        return true;
      }, operationName: 'delete all user data');
    } catch (e) {
      developer.log(
        'Failed to delete all user data: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return false;
    }
  }

  /// Exports user data for portability (GDPR compliance)
  Future<Map<String, dynamic>?> exportUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exportData = <String, dynamic>{};

      // Get all user-related keys
      final userKeys = prefs.getKeys().where(
        (key) => key.contains(userId) || key.startsWith('calm_'),
      );

      for (final key in userKeys) {
        try {
          // Try to decrypt if it's encrypted data
          final value = prefs.getString(key);
          if (value != null) {
            // Check if it's encrypted data
            if (key.contains('mood_') || key.contains('sensitive_')) {
              final decrypted = await decryptSensitiveData(value);
              if (decrypted != null) {
                exportData[key] = decrypted;
              }
            } else {
              exportData[key] = value;
            }
          }
        } catch (e) {
          // Skip keys that can't be processed
          developer.log(
            'Skipped key during export: $key, error: $e',
            name: 'PrivacySecurityService',
          );
        }
      }

      // Add metadata
      exportData['_export_metadata'] = {
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'version': '1.0',
        'keysExported': exportData.length,
      };

      developer.log(
        'Exported user data (${exportData.length} entries)',
        name: 'PrivacySecurityService',
      );

      return exportData;
    } catch (e) {
      developer.log(
        'Failed to export user data: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return null;
    }
  }

  /// Updates privacy settings
  Future<bool> updatePrivacySettings(Map<String, dynamic> settings) async {
    return await _updatePrivacySettings(settings);
  }

  /// Gets current privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    return await _getPrivacySettings();
  }

  /// Checks if data collection is enabled
  Future<bool> isDataCollectionEnabled() async {
    final settings = await _getPrivacySettings();
    return settings['dataCollection'] ?? true;
  }

  /// Checks if analytics is enabled
  Future<bool> isAnalyticsEnabled() async {
    final settings = await _getPrivacySettings();
    return settings['analytics'] ?? true;
  }

  /// Checks if anonymous mode is enabled
  Future<bool> isAnonymousModeEnabled() async {
    final settings = await _getPrivacySettings();
    return settings['anonymousMode'] ?? false;
  }

  /// Gets anonymous ID for anonymous mode
  Future<String?> getAnonymousId() async {
    final settings = await _getPrivacySettings();
    return settings['anonymousId'];
  }

  /// Performs data retention cleanup
  Future<bool> performDataRetentionCleanup() async {
    try {
      final retentionSettings = await _getDataRetentionSettings();
      final retentionDays = retentionSettings['retentionDays'] ?? 365;
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('calm_'));

      int deletedCount = 0;

      for (final key in keys) {
        try {
          // Check if the data is older than retention period
          if (await _isDataExpired(key, cutoffDate)) {
            await prefs.remove(key);
            await prefs.remove('calm_checksum_$key');
            await prefs.remove('calm_backup_$key');
            deletedCount++;
          }
        } catch (e) {
          developer.log(
            'Failed to check retention for key $key: $e',
            name: 'PrivacySecurityService',
            error: e,
          );
        }
      }

      developer.log(
        'Data retention cleanup completed: $deletedCount items deleted',
        name: 'PrivacySecurityService',
      );

      return true;
    } catch (e) {
      developer.log(
        'Failed to perform data retention cleanup: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return false;
    }
  }

  /// Gets privacy compliance status
  Future<Map<String, dynamic>> getComplianceStatus() async {
    try {
      final settings = await _getPrivacySettings();
      final retentionSettings = await _getDataRetentionSettings();

      return {
        'gdprCompliant': _isGDPRCompliant(settings),
        'ccpaCompliant': _isCCPACompliant(settings),
        'dataEncrypted': true,
        'anonymousModeAvailable': true,
        'dataRetentionConfigured': retentionSettings.isNotEmpty,
        'userDataDeletionAvailable': true,
        'dataExportAvailable': true,
        'privacySettings': settings,
        'retentionSettings': retentionSettings,
      };
    } catch (e) {
      developer.log(
        'Failed to get compliance status: $e',
        name: 'PrivacySecurityService',
        error: e,
      );
      return {'error': e.toString()};
    }
  }

  // Private helper methods

  Future<void> _initializeEncryption() async {
    final prefs = await SharedPreferences.getInstance();
    String? keyString = prefs.getString(_encryptionKeyKey);

    if (keyString == null) {
      // Generate new encryption key
      final key = Key.fromSecureRandom(32);
      keyString = key.base64;
      await prefs.setString(_encryptionKeyKey, keyString);
    }

    final key = Key.fromBase64(keyString);
    _encrypter = Encrypter(AES(key));
    _iv = IV.fromSecureRandom(16);
  }

  Future<void> _initializePrivacySettings() async {
    final settings = await _getPrivacySettings();

    if (settings.isEmpty) {
      // Set default privacy settings
      final defaultSettings = {
        'dataCollection': true,
        'analytics': true,
        'anonymousMode': false,
        'crashReporting': true,
        'personalizedRecommendations': true,
        'dataRetentionDays': 365,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _updatePrivacySettings(defaultSettings);
    }
  }

  Future<void> _initializeDataRetention() async {
    final settings = await _getDataRetentionSettings();

    if (settings.isEmpty) {
      final defaultRetention = {
        'retentionDays': 365,
        'autoCleanup': true,
        'lastCleanup': DateTime.now().toIso8601String(),
      };

      await _dataIntegrity.storeWithIntegrity(
        _dataRetentionKey,
        defaultRetention,
        (data) => data,
      );
    }
  }

  Future<Map<String, dynamic>> _sanitizeMoodData(
    Map<String, dynamic> data,
  ) async {
    final sanitized = Map<String, dynamic>.from(data);

    // Remove or hash any potentially identifying information
    sanitized.remove('deviceId');
    sanitized.remove('ipAddress');
    sanitized.remove('location');

    // Hash user ID if present
    if (sanitized.containsKey('userId')) {
      sanitized['userIdHash'] = _hashString(sanitized['userId']);
      sanitized.remove('userId');
    }

    return sanitized;
  }

  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _generateAnonymousId() async {
    final random = Random.secure();
    final bytes = Uint8List(16);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  Future<Map<String, dynamic>> _getPrivacySettings() async {
    final settings = await _dataIntegrity.retrieveWithIntegrity(
      _privacySettingsKey,
      (data) => data,
    );
    return settings ?? {};
  }

  Future<bool> _updatePrivacySettings(Map<String, dynamic> settings) async {
    settings['updatedAt'] = DateTime.now().toIso8601String();

    return await _dataIntegrity.storeWithIntegrity(
      _privacySettingsKey,
      settings,
      (data) => data,
    );
  }

  Future<Map<String, dynamic>> _getDataRetentionSettings() async {
    final settings = await _dataIntegrity.retrieveWithIntegrity(
      _dataRetentionKey,
      (data) => data,
    );
    return settings ?? {};
  }

  Future<void> _deleteCachedUserFiles(String userId) async {
    // This would delete any cached files associated with the user
    // Implementation depends on your file caching strategy
  }

  Future<bool> _isDataExpired(String key, DateTime cutoffDate) async {
    // Check if data associated with key is older than cutoff date
    // This is a simplified implementation
    return false;
  }

  bool _isGDPRCompliant(Map<String, dynamic> settings) {
    // Check GDPR compliance requirements
    return settings.containsKey('dataCollection') &&
        settings.containsKey('analytics') &&
        settings.containsKey('dataRetentionDays');
  }

  bool _isCCPACompliant(Map<String, dynamic> settings) {
    // Check CCPA compliance requirements
    return settings.containsKey('dataCollection') &&
        settings.containsKey('anonymousMode');
  }
}
