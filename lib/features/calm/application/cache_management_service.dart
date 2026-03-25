import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'error_recovery_service.dart';
import 'data_integrity_service.dart';

/// Service for managing cache, offline data, and synchronization
class CacheManagementService {
  final ErrorRecoveryService _errorRecovery;
  final DataIntegrityService _dataIntegrity;

  static const String _cacheVersionKey = 'calm_cache_version';
  static const String _lastSyncKey = 'calm_last_sync';
  static const String _syncQueueKey = 'calm_sync_queue';
  static const int _currentCacheVersion = 1;

  // Cache size limits (in bytes)
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxAudioCacheSize = 50 * 1024 * 1024; // 50MB

  CacheManagementService({
    ErrorRecoveryService? errorRecovery,
    DataIntegrityService? dataIntegrity,
  }) : _errorRecovery = errorRecovery ?? ErrorRecoveryService(),
       _dataIntegrity = dataIntegrity ?? DataIntegrityService();

  /// Initializes cache management system
  Future<bool> initialize() async {
    try {
      return await _errorRecovery.withRetry(() async {
        await _checkCacheVersion();
        await _createCacheDirectories();
        await _cleanupExpiredCache();
        await _initializeSyncQueue();

        developer.log(
          'Cache management initialized successfully',
          name: 'CacheManagementService',
        );

        return true;
      }, operationName: 'initialize cache management');
    } catch (e) {
      developer.log(
        'Failed to initialize cache management: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return false;
    }
  }

  /// Caches essential data for offline use
  Future<bool> cacheEssentialData(Map<String, dynamic> data) async {
    try {
      return await _dataIntegrity.storeWithIntegrity(
        'calm_essential_data',
        data,
        (data) => data,
      );
    } catch (e) {
      developer.log(
        'Failed to cache essential data: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return false;
    }
  }

  /// Retrieves cached essential data
  Future<Map<String, dynamic>?> getCachedEssentialData() async {
    try {
      return await _dataIntegrity.retrieveWithIntegrity(
        'calm_essential_data',
        (data) => data,
      );
    } catch (e) {
      developer.log(
        'Failed to retrieve cached essential data: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return null;
    }
  }

  /// Caches audio file for offline playback
  Future<bool> cacheAudioFile(String soundId, List<int> audioData) async {
    try {
      final cacheDir = await _getAudioCacheDirectory();
      final file = File('${cacheDir.path}/$soundId.mp3');

      // Check cache size limits
      final currentSize = await _getAudioCacheSize();
      if (currentSize + audioData.length > _maxAudioCacheSize) {
        await _cleanupAudioCache();
      }

      await file.writeAsBytes(audioData);

      // Update cache metadata
      await _updateAudioCacheMetadata(soundId, audioData.length);

      developer.log(
        'Cached audio file: $soundId (${audioData.length} bytes)',
        name: 'CacheManagementService',
      );

      return true;
    } catch (e) {
      developer.log(
        'Failed to cache audio file $soundId: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return false;
    }
  }

  /// Retrieves cached audio file
  Future<File?> getCachedAudioFile(String soundId) async {
    try {
      final cacheDir = await _getAudioCacheDirectory();
      final file = File('${cacheDir.path}/$soundId.mp3');

      if (await file.exists()) {
        // Update access time for LRU cache management
        await _updateAudioAccessTime(soundId);
        return file;
      }

      return null;
    } catch (e) {
      developer.log(
        'Failed to retrieve cached audio file $soundId: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return null;
    }
  }

  /// Adds data to synchronization queue
  Future<bool> queueForSync(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(
        (jsonDecode(queueJson) as List).cast<Map<String, dynamic>>(),
      );

      // Add timestamp and unique ID
      data['_queuedAt'] = DateTime.now().toIso8601String();
      data['_queueId'] = _generateQueueId();

      queue.add(data);

      return await _dataIntegrity.storeWithIntegrity(
        _syncQueueKey,
        queue,
        (queue) => {'items': queue},
      );
    } catch (e) {
      developer.log(
        'Failed to queue data for sync: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return false;
    }
  }

  /// Processes synchronization queue when online
  Future<bool> processSyncQueue() async {
    if (!await _isOnline()) {
      developer.log(
        'Skipping sync queue processing - offline',
        name: 'CacheManagementService',
      );
      return false;
    }

    try {
      final queueData = await _dataIntegrity.retrieveWithIntegrity(
        _syncQueueKey,
        (data) => data,
      );

      if (queueData == null || queueData['items'] == null) {
        return true; // Empty queue is success
      }

      final queue = List<Map<String, dynamic>>.from(queueData['items']);
      final processedItems = <String>[];

      for (final item in queue) {
        try {
          final success = await _syncItem(item);
          if (success) {
            processedItems.add(item['_queueId'] as String);
          }
        } catch (e) {
          developer.log(
            'Failed to sync item ${item['_queueId']}: $e',
            name: 'CacheManagementService',
            error: e,
          );
        }
      }

      // Remove successfully processed items
      if (processedItems.isNotEmpty) {
        final remainingQueue = queue
            .where((item) => !processedItems.contains(item['_queueId']))
            .toList();

        await _dataIntegrity.storeWithIntegrity(
          _syncQueueKey,
          remainingQueue,
          (queue) => {'items': queue},
        );
      }

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      developer.log(
        'Processed ${processedItems.length} items from sync queue',
        name: 'CacheManagementService',
      );

      return true;
    } catch (e) {
      developer.log(
        'Failed to process sync queue: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return false;
    }
  }

  /// Clears all cache data (user-initiated recovery)
  Future<bool> clearAllCache() async {
    try {
      // Clear audio cache
      final audioCacheDir = await _getAudioCacheDirectory();
      if (await audioCacheDir.exists()) {
        await audioCacheDir.delete(recursive: true);
      }

      // Clear data cache
      final dataCacheDir = await _getDataCacheDirectory();
      if (await dataCacheDir.exists()) {
        await dataCacheDir.delete(recursive: true);
      }

      // Clear preferences cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = prefs.getKeys().where(
        (key) => key.startsWith('calm_cache_'),
      );
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }

      // Reinitialize
      await initialize();

      developer.log(
        'All cache cleared successfully',
        name: 'CacheManagementService',
      );

      return true;
    } catch (e) {
      developer.log(
        'Failed to clear all cache: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return false;
    }
  }

  /// Gets cache statistics and health information
  Future<Map<String, dynamic>> getCacheHealth() async {
    try {
      final audioCacheSize = await _getAudioCacheSize();
      final dataCacheSize = await _getDataCacheSize();
      final totalCacheSize = audioCacheSize + dataCacheSize;

      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);
      final queueData = await _dataIntegrity.retrieveWithIntegrity(
        _syncQueueKey,
        (data) => data,
      );
      final queueSize = queueData?['items']?.length ?? 0;

      return {
        'totalCacheSize': totalCacheSize,
        'audioCacheSize': audioCacheSize,
        'dataCacheSize': dataCacheSize,
        'maxCacheSize': _maxCacheSize,
        'cacheUsagePercent': (totalCacheSize / _maxCacheSize * 100).round(),
        'lastSync': lastSync,
        'syncQueueSize': queueSize,
        'isOnline': await _isOnline(),
        'cacheVersion': _currentCacheVersion,
      };
    } catch (e) {
      developer.log(
        'Failed to get cache health: $e',
        name: 'CacheManagementService',
        error: e,
      );
      return {'error': e.toString()};
    }
  }

  // Private helper methods

  Future<void> _checkCacheVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_cacheVersionKey) ?? 0;

    if (storedVersion < _currentCacheVersion) {
      developer.log(
        'Cache version upgrade: $storedVersion -> $_currentCacheVersion',
        name: 'CacheManagementService',
      );

      // Clear old cache on version upgrade
      await clearAllCache();
      await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
    }
  }

  Future<void> _createCacheDirectories() async {
    final audioCacheDir = await _getAudioCacheDirectory();
    final dataCacheDir = await _getDataCacheDirectory();

    if (!await audioCacheDir.exists()) {
      await audioCacheDir.create(recursive: true);
    }

    if (!await dataCacheDir.exists()) {
      await dataCacheDir.create(recursive: true);
    }
  }

  Future<Directory> _getAudioCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/calm_audio_cache');
  }

  Future<Directory> _getDataCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/calm_data_cache');
  }

  Future<int> _getAudioCacheSize() async {
    try {
      final cacheDir = await _getAudioCacheDirectory();
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getDataCacheSize() async {
    try {
      final cacheDir = await _getDataCacheDirectory();
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _cleanupExpiredCache() async {
    // Clean up audio cache based on LRU
    await _cleanupAudioCache();

    // Clean up old data cache files
    await _cleanupDataCache();
  }

  Future<void> _cleanupAudioCache() async {
    try {
      final cacheDir = await _getAudioCacheDirectory();
      if (!await cacheDir.exists()) return;

      final files = <File>[];
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          files.add(entity);
        }
      }

      // Sort by last access time (oldest first)
      files.sort((a, b) {
        final aTime = _getAudioLastAccessTime(a.path);
        final bTime = _getAudioLastAccessTime(b.path);
        return aTime.compareTo(bTime);
      });

      // Remove oldest files if cache is too large
      int currentSize = await _getAudioCacheSize();
      for (final file in files) {
        if (currentSize <= _maxAudioCacheSize) break;

        final stat = await file.stat();
        await file.delete();
        currentSize -= stat.size;

        developer.log(
          'Removed cached audio file: ${file.path}',
          name: 'CacheManagementService',
        );
      }
    } catch (e) {
      developer.log(
        'Failed to cleanup audio cache: $e',
        name: 'CacheManagementService',
        error: e,
      );
    }
  }

  Future<void> _cleanupDataCache() async {
    // Implementation for data cache cleanup
    // This would remove old cached technique data, user preferences, etc.
  }

  Future<void> _initializeSyncQueue() async {
    final queueData = await _dataIntegrity.retrieveWithIntegrity(
      _syncQueueKey,
      (data) => data,
    );

    if (queueData == null) {
      await _dataIntegrity.storeWithIntegrity(
        _syncQueueKey,
        <Map<String, dynamic>>[],
        (queue) => {'items': queue},
      );
    }
  }

  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _syncItem(Map<String, dynamic> item) async {
    // This would integrate with your backend API to sync the data
    // For now, simulate success after a delay
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  String _generateQueueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _updateAudioCacheMetadata(String soundId, int size) async {
    final prefs = await SharedPreferences.getInstance();
    final metadata = {
      'size': size,
      'cachedAt': DateTime.now().toIso8601String(),
      'lastAccess': DateTime.now().toIso8601String(),
    };

    await prefs.setString('calm_audio_meta_$soundId', jsonEncode(metadata));
  }

  Future<void> _updateAudioAccessTime(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString('calm_audio_meta_$soundId');

    if (metadataJson != null) {
      final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
      metadata['lastAccess'] = DateTime.now().toIso8601String();
      await prefs.setString('calm_audio_meta_$soundId', jsonEncode(metadata));
    }
  }

  DateTime _getAudioLastAccessTime(String filePath) {
    // Extract sound ID from file path and get last access time
    // This is a simplified implementation
    return DateTime.now().subtract(const Duration(days: 1));
  }
}
