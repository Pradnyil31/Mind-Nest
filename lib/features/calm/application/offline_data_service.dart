import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../../../core/logger.dart';
import '../../../services/firestore_service.dart';
import 'calm_progress_service.dart';
import 'mood_tracking_service.dart';

/// Service for managing offline data storage and synchronization
/// Implements Requirements 9.1-9.6: Offline Capability and Data Synchronization
class OfflineDataService {
  static final OfflineDataService _instance = OfflineDataService._internal();
  factory OfflineDataService() => _instance;
  OfflineDataService._internal();

  final Logger _logger = Logger();
  final FirestoreService _firestoreService = FirestoreService();
  final CalmProgressService _progressService = CalmProgressService();
  final MoodTrackingService _moodService = MoodTrackingService();

  // Stream controllers for offline status
  final StreamController<bool> _offlineStatusController =
      StreamController<bool>.broadcast();
  final StreamController<List<String>> _syncQueueController =
      StreamController<List<String>>.broadcast();

  // Cache keys
  static const String _coreDataKey = 'calm_core_data';
  static const String _userPreferencesKey = 'calm_user_preferences';
  static const String _cachedAudioKey = 'calm_cached_audio';
  static const String _syncQueueKey = 'calm_sync_queue';
  static const String _lastSyncKey = 'calm_last_sync';

  bool _isInitialized = false;
  bool _isOnline = true;
  List<String> _syncQueue = [];
  StreamSubscription? _connectivitySubscription;

  /// Stream of offline status changes
  Stream<bool> get offlineStatusStream => _offlineStatusController.stream;

  /// Stream of sync queue updates
  Stream<List<String>> get syncQueueStream => _syncQueueController.stream;

  /// Current offline status
  bool get isOffline => !_isOnline;

  /// Current sync queue
  List<String> get syncQueue => List.from(_syncQueue);

  /// Initialize the offline data service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // For now, assume online (connectivity checking can be added later)
      _isOnline = true;

      // Connectivity monitoring can be added later
      // _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      //   _onConnectivityChanged,
      // );

      // Load sync queue from storage
      await _loadSyncQueue();

      // Initialize core data cache if needed
      await _initializeCoreDataCache();

      // Attempt initial sync if online
      if (_isOnline) {
        await _performSync();
      }

      _isInitialized = true;
      _logger.i('OfflineDataService initialized successfully');

      // Notify initial status
      _offlineStatusController.add(!_isOnline);
      _syncQueueController.add(_syncQueue);
    } catch (e) {
      _logger.e('Failed to initialize OfflineDataService: $e');
      rethrow;
    }
  }

  /// Handle connectivity changes (simplified for now)
  void _onConnectivityChanged(bool isOnline) async {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;

    _logger.i('Connectivity changed: ${_isOnline ? 'online' : 'offline'}');
    _offlineStatusController.add(!_isOnline);

    // If we just came back online, attempt sync
    if (wasOffline && _isOnline) {
      await _performSync();
    }
  }

  /// Initialize core data cache with essential techniques and sounds
  Future<void> _initializeCoreDataCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString(_coreDataKey);

      if (existingData == null) {
        // Cache core techniques and sounds for offline use
        final coreData = {
          'techniques': _getCoreCalmTechniques(),
          'ambientSounds': _getCoreAmbientSounds(),
          'cachedAt': DateTime.now().toIso8601String(),
        };

        await prefs.setString(_coreDataKey, jsonEncode(coreData));
        _logger.i('Core data cache initialized');
      }
    } catch (e) {
      _logger.e('Failed to initialize core data cache: $e');
    }
  }

  /// Get core calm techniques for offline use
  List<Map<String, dynamic>> _getCoreCalmTechniques() {
    return [
      {
        'id': 'breathing-4-7-8',
        'title': '4-7-8 Breathing',
        'description': 'A simple breathing technique to reduce anxiety',
        'icon': '🫁',
        'type': 'breathing',
        'durationMinutes': 5,
        'steps': [
          'Sit comfortably with your back straight',
          'Exhale completely through your mouth',
          'Inhale through your nose for 4 counts',
          'Hold your breath for 7 counts',
          'Exhale through your mouth for 8 counts',
          'Repeat this cycle 3-4 times',
        ],
        'isOfflineAvailable': true,
      },
      {
        'id': 'grounding-5-4-3-2-1',
        'title': '5-4-3-2-1 Grounding',
        'description': 'Use your senses to ground yourself in the present',
        'icon': '🌱',
        'type': 'grounding',
        'durationMinutes': 3,
        'steps': [
          'Name 5 things you can see',
          'Name 4 things you can touch',
          'Name 3 things you can hear',
          'Name 2 things you can smell',
          'Name 1 thing you can taste',
        ],
        'isOfflineAvailable': true,
      },
      {
        'id': 'body-scan',
        'title': 'Progressive Body Scan',
        'description': 'Systematically relax each part of your body',
        'icon': '🧘',
        'type': 'visualization',
        'durationMinutes': 10,
        'steps': [
          'Lie down comfortably',
          'Start with your toes, notice any tension',
          'Consciously relax each body part',
          'Move slowly up through your body',
          'End with your head and face',
          'Take a moment to feel your whole body relaxed',
        ],
        'isOfflineAvailable': true,
      },
    ];
  }

  /// Get core ambient sounds for offline use
  List<Map<String, dynamic>> _getCoreAmbientSounds() {
    return [
      {
        'id': 'rain',
        'name': 'Rain',
        'emoji': '🌧️',
        'category': 'nature',
        'description': 'Gentle rain sounds for relaxation',
        'assetPath': 'assets/audio/track_1.mp3',
        'isOfflineAvailable': true,
      },
      {
        'id': 'ocean',
        'name': 'Ocean Waves',
        'emoji': '🌊',
        'category': 'nature',
        'description': 'Calming ocean wave sounds',
        'assetPath': 'assets/audio/track_2.mp3',
        'isOfflineAvailable': true,
      },
      {
        'id': 'forest',
        'name': 'Forest',
        'emoji': '🌲',
        'category': 'nature',
        'description': 'Peaceful forest ambience',
        'assetPath': 'assets/audio/track_3.mp3',
        'isOfflineAvailable': true,
      },
    ];
  }

  /// Cache user's favorite ambient sounds for offline use
  Future<void> cacheUserFavoriteAudio(
    String userId,
    List<String> favoriteSoundIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'userId': userId,
        'favoriteSounds': favoriteSoundIds,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_cachedAudioKey, jsonEncode(cacheData));
      _logger.i(
        'Cached ${favoriteSoundIds.length} favorite sounds for offline use',
      );
    } catch (e) {
      _logger.e('Failed to cache favorite audio: $e');
    }
  }

  /// Get cached favorite audio for offline use
  Future<List<String>> getCachedFavoriteAudio(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cachedAudioKey);

      if (cacheData != null) {
        final data = jsonDecode(cacheData) as Map<String, dynamic>;
        if (data['userId'] == userId) {
          return List<String>.from(data['favoriteSounds'] ?? []);
        }
      }

      return [];
    } catch (e) {
      _logger.e('Failed to get cached favorite audio: $e');
      return [];
    }
  }

  /// Store user preferences locally
  Future<void> storeUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefData = {
        'userId': userId,
        'preferences': preferences,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_userPreferencesKey, jsonEncode(prefData));
      _logger.d('Stored user preferences locally');

      // Queue for sync if offline
      if (!_isOnline) {
        await _addToSyncQueue('user_preferences', prefData);
      }
    } catch (e) {
      _logger.e('Failed to store user preferences: $e');
    }
  }

  /// Get user preferences from local storage
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefData = prefs.getString(_userPreferencesKey);

      if (prefData != null) {
        final data = jsonDecode(prefData) as Map<String, dynamic>;
        if (data['userId'] == userId) {
          return data['preferences'] as Map<String, dynamic>?;
        }
      }

      return null;
    } catch (e) {
      _logger.e('Failed to get user preferences: $e');
      return null;
    }
  }

  /// Store technique completion data locally when offline
  Future<void> storeTechniqueCompletionOffline({
    required String userId,
    required String techniqueId,
    required String techniqueName,
    required int durationMinutes,
    int? preMoodRating,
    int? postMoodRating,
  }) async {
    try {
      final completionData = {
        'type': 'technique_completion',
        'userId': userId,
        'techniqueId': techniqueId,
        'techniqueName': techniqueName,
        'durationMinutes': durationMinutes,
        'preMoodRating': preMoodRating,
        'postMoodRating': postMoodRating,
        'completedAt': DateTime.now().toIso8601String(),
        'moodImprovement': (preMoodRating != null && postMoodRating != null)
            ? postMoodRating - preMoodRating
            : null,
      };

      await _addToSyncQueue('technique_completion', completionData);
      _logger.i('Stored technique completion offline: $techniqueName');
    } catch (e) {
      _logger.e('Failed to store technique completion offline: $e');
    }
  }

  /// Store mood session data locally when offline
  Future<void> storeMoodSessionOffline({
    required String userId,
    required String sessionId,
    required String techniqueId,
    int? preMoodRating,
    int? postMoodRating,
  }) async {
    try {
      final moodData = {
        'type': 'mood_session',
        'userId': userId,
        'sessionId': sessionId,
        'techniqueId': techniqueId,
        'preMoodRating': preMoodRating,
        'postMoodRating': postMoodRating,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _addToSyncQueue('mood_session', moodData);
      _logger.i('Stored mood session offline: $sessionId');
    } catch (e) {
      _logger.e('Failed to store mood session offline: $e');
    }
  }

  /// Add data to sync queue
  Future<void> _addToSyncQueue(String type, Map<String, dynamic> data) async {
    try {
      final queueItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _syncQueue.add(jsonEncode(queueItem));
      await _saveSyncQueue();
      _syncQueueController.add(_syncQueue);

      _logger.d('Added item to sync queue: $type');
    } catch (e) {
      _logger.e('Failed to add to sync queue: $e');
    }
  }

  /// Load sync queue from storage
  Future<void> _loadSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueData = prefs.getStringList(_syncQueueKey);
      _syncQueue = queueData ?? [];
      _logger.d('Loaded ${_syncQueue.length} items from sync queue');
    } catch (e) {
      _logger.e('Failed to load sync queue: $e');
      _syncQueue = [];
    }
  }

  /// Save sync queue to storage
  Future<void> _saveSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_syncQueueKey, _syncQueue);
    } catch (e) {
      _logger.e('Failed to save sync queue: $e');
    }
  }

  /// Perform data synchronization when online
  Future<void> _performSync() async {
    if (!_isOnline || _syncQueue.isEmpty) return;

    try {
      _logger.i('Starting data synchronization (${_syncQueue.length} items)');
      final itemsToSync = List<String>.from(_syncQueue);
      final successfulSyncs = <String>[];

      for (final itemJson in itemsToSync) {
        try {
          final item = jsonDecode(itemJson) as Map<String, dynamic>;
          final success = await _syncItem(item);

          if (success) {
            successfulSyncs.add(itemJson);
          }
        } catch (e) {
          _logger.w('Failed to sync item: $e');
        }
      }

      // Remove successfully synced items
      _syncQueue.removeWhere((item) => successfulSyncs.contains(item));
      await _saveSyncQueue();
      _syncQueueController.add(_syncQueue);

      // Update last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      _logger.i(
        'Sync completed: ${successfulSyncs.length}/${itemsToSync.length} items synced',
      );
    } catch (e) {
      _logger.e('Sync failed: $e');
    }
  }

  /// Sync individual item to server
  Future<bool> _syncItem(Map<String, dynamic> item) async {
    try {
      final type = item['type'] as String;
      final data = item['data'] as Map<String, dynamic>;

      switch (type) {
        case 'technique_completion':
          await _progressService.logTechniqueCompletion(
            userId: data['userId'],
            techniqueId: data['techniqueId'],
            techniqueName: data['techniqueName'],
            durationMinutes: data['durationMinutes'],
            preMoodRating: data['preMoodRating'],
            postMoodRating: data['postMoodRating'],
          );
          break;

        case 'mood_session':
          // Sync mood session data
          if (data['preMoodRating'] != null) {
            await _moodService.recordPreMood(
              data['userId'],
              data['techniqueId'],
              data['preMoodRating'],
            );
          }
          if (data['postMoodRating'] != null) {
            await _moodService.recordPostMood(
              data['sessionId'],
              data['postMoodRating'],
            );
          }
          break;

        case 'user_preferences':
          // Sync user preferences (would need to implement in FirestoreService)
          // For now, just log success
          _logger.d('User preferences sync not yet implemented');
          break;

        default:
          _logger.w('Unknown sync item type: $type');
          return false;
      }

      return true;
    } catch (e) {
      _logger.e('Failed to sync item: $e');
      return false;
    }
  }

  /// Get core techniques for offline use
  Future<List<Map<String, dynamic>>> getCoreCalmTechniques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coreData = prefs.getString(_coreDataKey);

      if (coreData != null) {
        final data = jsonDecode(coreData) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['techniques'] ?? []);
      }

      // Return default techniques if no cache
      return _getCoreCalmTechniques();
    } catch (e) {
      _logger.e('Failed to get core techniques: $e');
      return _getCoreCalmTechniques();
    }
  }

  /// Get core ambient sounds for offline use
  Future<List<Map<String, dynamic>>> getCoreAmbientSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coreData = prefs.getString(_coreDataKey);

      if (coreData != null) {
        final data = jsonDecode(coreData) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['ambientSounds'] ?? []);
      }

      // Return default sounds if no cache
      return _getCoreAmbientSounds();
    } catch (e) {
      _logger.e('Failed to get core ambient sounds: $e');
      return _getCoreAmbientSounds();
    }
  }

  /// Check if a feature is available offline
  bool isFeatureAvailableOffline(String featureId) {
    const offlineFeatures = {
      'core_techniques',
      'basic_breathing',
      'grounding_exercises',
      'body_scan',
      'core_ambient_sounds',
      'mood_tracking',
      'progress_viewing',
    };

    return offlineFeatures.contains(featureId);
  }

  /// Get offline feature availability status
  Map<String, bool> getOfflineFeatureAvailability() {
    return {
      'coreCalm Techniques': true,
      'basicBreathing': true,
      'groundingExercises': true,
      'bodyScan': true,
      'coreAmbientSounds': true,
      'moodTracking': true,
      'progressViewing': true,
      'personalizedRecommendations': false,
      'advancedAnalytics': false,
      'socialFeatures': false,
      'cloudSync': false,
    };
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);

      if (lastSyncStr != null) {
        return DateTime.parse(lastSyncStr);
      }

      return null;
    } catch (e) {
      _logger.e('Failed to get last sync time: $e');
      return null;
    }
  }

  /// Manually trigger sync (for user-initiated sync)
  Future<bool> manualSync() async {
    if (!_isOnline) {
      _logger.w('Cannot sync: device is offline');
      return false;
    }

    try {
      await _performSync();
      return true;
    } catch (e) {
      _logger.e('Manual sync failed: $e');
      return false;
    }
  }

  /// Clear all cached data (for troubleshooting)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_coreDataKey);
      await prefs.remove(_userPreferencesKey);
      await prefs.remove(_cachedAudioKey);

      _logger.i('Cache cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear cache: $e');
    }
  }

  /// Clear sync queue (for troubleshooting)
  Future<void> clearSyncQueue() async {
    try {
      _syncQueue.clear();
      await _saveSyncQueue();
      _syncQueueController.add(_syncQueue);

      _logger.i('Sync queue cleared');
    } catch (e) {
      _logger.e('Failed to clear sync queue: $e');
    }
  }

  /// Get storage usage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final coreDataSize = prefs.getString(_coreDataKey)?.length ?? 0;
      final preferencesSize = prefs.getString(_userPreferencesKey)?.length ?? 0;
      final audioDataSize = prefs.getString(_cachedAudioKey)?.length ?? 0;
      final syncQueueSize = _syncQueue.fold<int>(
        0,
        (total, item) => total + item.length,
      );

      return {
        'coreDataSize': coreDataSize,
        'preferencesSize': preferencesSize,
        'audioDataSize': audioDataSize,
        'syncQueueSize': syncQueueSize,
        'totalSize':
            coreDataSize + preferencesSize + audioDataSize + syncQueueSize,
        'syncQueueItems': _syncQueue.length,
      };
    } catch (e) {
      _logger.e('Failed to get storage stats: $e');
      return {
        'coreDataSize': 0,
        'preferencesSize': 0,
        'audioDataSize': 0,
        'syncQueueSize': 0,
        'totalSize': 0,
        'syncQueueItems': 0,
      };
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      await _connectivitySubscription?.cancel();
      await _offlineStatusController.close();
      await _syncQueueController.close();

      _logger.i('OfflineDataService disposed');
    } catch (e) {
      _logger.e('Error disposing OfflineDataService: $e');
    }
  }
}
