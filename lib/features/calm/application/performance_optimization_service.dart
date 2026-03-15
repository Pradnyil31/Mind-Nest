import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../../core/logger.dart';
import '../../../services/audio_playback_service.dart';

/// Service for performance optimization and resource management
/// Implements Requirements 13.1-13.6: Performance and Resource Management
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance =
      PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  final Logger _logger = Logger();
  final AudioPlaybackService _audioService = AudioPlaybackService();

  // Performance monitoring
  Timer? _memoryMonitorTimer;
  Timer? _batteryOptimizationTimer;
  bool _lowPowerModeEnabled = false;
  bool _isMonitoring = false;

  // Resource management
  final Map<String, DateTime> _assetCacheTimestamps = {};
  final Set<String> _activeResources = {};

  // Performance thresholds
  static const int _maxMemoryUsageMB = 100;
  static const int _maxConcurrentSounds = 5;
  static const Duration _cacheExpiryDuration = Duration(hours: 24);
  static const Duration _memoryCheckInterval = Duration(minutes: 5);
  static const Duration _batteryOptimizationInterval = Duration(minutes: 10);

  /// Initialize performance monitoring
  Future<void> initialize() async {
    try {
      await _startPerformanceMonitoring();
      await _initializeAssetCache();

      _logger.i('PerformanceOptimizationService initialized');
    } catch (e) {
      _logger.e('Failed to initialize PerformanceOptimizationService: $e');
      rethrow;
    }
  }

  /// Start performance monitoring
  Future<void> _startPerformanceMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Memory monitoring
    _memoryMonitorTimer = Timer.periodic(_memoryCheckInterval, (_) {
      _checkMemoryUsage();
    });

    // Battery optimization
    _batteryOptimizationTimer = Timer.periodic(_batteryOptimizationInterval, (
      _,
    ) {
      _optimizeBatteryUsage();
    });

    _logger.d('Performance monitoring started');
  }

  /// Check and optimize memory usage
  void _checkMemoryUsage() {
    try {
      // In a real implementation, you would use platform-specific APIs
      // to get actual memory usage. For now, we'll simulate based on active resources.
      final estimatedMemoryUsage = _estimateMemoryUsage();

      if (estimatedMemoryUsage > _maxMemoryUsageMB) {
        _logger.w('High memory usage detected: ${estimatedMemoryUsage}MB');
        _performMemoryOptimization();
      }
    } catch (e) {
      _logger.e('Error checking memory usage: $e');
    }
  }

  /// Estimate memory usage based on active resources
  int _estimateMemoryUsage() {
    // Rough estimation: each active sound = ~10MB, each cached asset = ~2MB
    final activeSounds = _audioService.getActiveSoundIds().length;
    final cachedAssets = _assetCacheTimestamps.length;

    return (activeSounds * 10) + (cachedAssets * 2);
  }

  /// Perform memory optimization
  Future<void> _performMemoryOptimization() async {
    try {
      _logger.i('Performing memory optimization');

      // Clean expired cache entries
      await _cleanExpiredCache();

      // Limit concurrent audio streams
      await _limitConcurrentAudio();

      // Enable low power mode if not already enabled
      if (!_lowPowerModeEnabled) {
        await enableLowPowerMode();
      }

      _logger.i('Memory optimization completed');
    } catch (e) {
      _logger.e('Error during memory optimization: $e');
    }
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];

      _assetCacheTimestamps.forEach((key, timestamp) {
        if (now.difference(timestamp) > _cacheExpiryDuration) {
          expiredKeys.add(key);
        }
      });

      for (final key in expiredKeys) {
        _assetCacheTimestamps.remove(key);
        _activeResources.remove(key);
      }

      if (expiredKeys.isNotEmpty) {
        _logger.d('Cleaned ${expiredKeys.length} expired cache entries');
      }
    } catch (e) {
      _logger.e('Error cleaning expired cache: $e');
    }
  }

  /// Limit concurrent audio streams for performance
  Future<void> _limitConcurrentAudio() async {
    try {
      final activeSounds = _audioService.getActiveSoundIds();

      if (activeSounds.length > _maxConcurrentSounds) {
        _logger.w('Too many concurrent sounds: ${activeSounds.length}');

        // Stop oldest sounds (this is a simplified approach)
        final soundsToStop = activeSounds.take(
          activeSounds.length - _maxConcurrentSounds,
        );

        for (final soundId in soundsToStop) {
          await _audioService.stopSound(soundId);
        }

        _logger.i(
          'Stopped ${soundsToStop.length} sounds to optimize performance',
        );
      }
    } catch (e) {
      _logger.e('Error limiting concurrent audio: $e');
    }
  }

  /// Optimize battery usage
  void _optimizeBatteryUsage() {
    try {
      // Check if device is on battery power (platform-specific implementation needed)
      // For now, we'll use a heuristic based on active resources

      final activeSounds = _audioService.getActiveSoundIds().length;
      final shouldOptimize = activeSounds > 2 || _activeResources.length > 10;

      if (shouldOptimize && !_lowPowerModeEnabled) {
        _logger.d('Enabling battery optimization');
        enableLowPowerMode();
      } else if (!shouldOptimize && _lowPowerModeEnabled) {
        _logger.d('Disabling battery optimization');
        disableLowPowerMode();
      }
    } catch (e) {
      _logger.e('Error optimizing battery usage: $e');
    }
  }

  /// Enable low power mode
  Future<void> enableLowPowerMode() async {
    try {
      if (_lowPowerModeEnabled) return;

      _lowPowerModeEnabled = true;

      // Reduce audio quality/processing
      await _audioService.setMasterVolume(_audioService.masterVolume * 0.8);

      // Reduce monitoring frequency
      _memoryMonitorTimer?.cancel();
      _memoryMonitorTimer = Timer.periodic(
        _memoryCheckInterval * 2, // Double the interval
        (_) => _checkMemoryUsage(),
      );

      _logger.i('Low power mode enabled');
    } catch (e) {
      _logger.e('Error enabling low power mode: $e');
    }
  }

  /// Disable low power mode
  Future<void> disableLowPowerMode() async {
    try {
      if (!_lowPowerModeEnabled) return;

      _lowPowerModeEnabled = false;

      // Restore normal monitoring frequency
      _memoryMonitorTimer?.cancel();
      _memoryMonitorTimer = Timer.periodic(
        _memoryCheckInterval,
        (_) => _checkMemoryUsage(),
      );

      _logger.i('Low power mode disabled');
    } catch (e) {
      _logger.e('Error disabling low power mode: $e');
    }
  }

  /// Initialize asset cache management
  Future<void> _initializeAssetCache() async {
    try {
      // Mark core assets as cached
      final coreAssets = [
        'assets/audio/track_1.mp3',
        'assets/audio/track_2.mp3',
        'assets/audio/track_3.mp3',
      ];

      final now = DateTime.now();
      for (final asset in coreAssets) {
        _assetCacheTimestamps[asset] = now;
        _activeResources.add(asset);
      }

      _logger.d(
        'Asset cache initialized with ${coreAssets.length} core assets',
      );
    } catch (e) {
      _logger.e('Error initializing asset cache: $e');
    }
  }

  /// Cache an asset for efficient access
  Future<void> cacheAsset(String assetPath) async {
    try {
      if (_assetCacheTimestamps.containsKey(assetPath)) {
        // Update timestamp for existing cache entry
        _assetCacheTimestamps[assetPath] = DateTime.now();
        return;
      }

      // Add new cache entry
      _assetCacheTimestamps[assetPath] = DateTime.now();
      _activeResources.add(assetPath);

      _logger.d('Cached asset: $assetPath');
    } catch (e) {
      _logger.e('Error caching asset: $e');
    }
  }

  /// Remove asset from cache
  Future<void> uncacheAsset(String assetPath) async {
    try {
      _assetCacheTimestamps.remove(assetPath);
      _activeResources.remove(assetPath);

      _logger.d('Uncached asset: $assetPath');
    } catch (e) {
      _logger.e('Error uncaching asset: $e');
    }
  }

  /// Preload frequently used assets
  Future<void> preloadAssets(List<String> assetPaths) async {
    try {
      for (final assetPath in assetPaths) {
        await cacheAsset(assetPath);

        // Add small delay to prevent blocking
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _logger.i('Preloaded ${assetPaths.length} assets');
    } catch (e) {
      _logger.e('Error preloading assets: $e');
    }
  }

  /// Clean up resources when navigating away
  Future<void> cleanupOnNavigation() async {
    try {
      // Stop all audio playback
      await _audioService.stopAllSounds();

      // Clear non-essential cached assets
      final now = DateTime.now();
      final assetsToRemove = <String>[];

      _assetCacheTimestamps.forEach((key, timestamp) {
        // Keep core assets, remove others older than 1 hour
        if (!key.contains('track_') &&
            now.difference(timestamp) > const Duration(hours: 1)) {
          assetsToRemove.add(key);
        }
      });

      for (final asset in assetsToRemove) {
        await uncacheAsset(asset);
      }

      _logger.i('Navigation cleanup completed');
    } catch (e) {
      _logger.e('Error during navigation cleanup: $e');
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    try {
      final activeSounds = _audioService.getActiveSoundIds().length;
      final cachedAssets = _assetCacheTimestamps.length;
      final estimatedMemory = _estimateMemoryUsage();

      return {
        'activeSounds': activeSounds,
        'cachedAssets': cachedAssets,
        'estimatedMemoryUsageMB': estimatedMemory,
        'lowPowerModeEnabled': _lowPowerModeEnabled,
        'isMonitoring': _isMonitoring,
        'activeResources': _activeResources.length,
        'memoryOptimizationNeeded': estimatedMemory > _maxMemoryUsageMB,
        'audioOptimizationNeeded': activeSounds > _maxConcurrentSounds,
      };
    } catch (e) {
      _logger.e('Error getting performance stats: $e');
      return {
        'activeSounds': 0,
        'cachedAssets': 0,
        'estimatedMemoryUsageMB': 0,
        'lowPowerModeEnabled': false,
        'isMonitoring': false,
        'activeResources': 0,
        'memoryOptimizationNeeded': false,
        'audioOptimizationNeeded': false,
      };
    }
  }

  /// Check if low power mode is enabled
  bool get isLowPowerModeEnabled => _lowPowerModeEnabled;

  /// Check if performance monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Get cached asset count
  int get cachedAssetCount => _assetCacheTimestamps.length;

  /// Get active resource count
  int get activeResourceCount => _activeResources.length;

  /// Force memory cleanup (for manual optimization)
  Future<void> forceMemoryCleanup() async {
    try {
      _logger.i('Forcing memory cleanup');

      await _cleanExpiredCache();
      await _limitConcurrentAudio();

      // Clear all non-essential resources
      final essentialAssets = _assetCacheTimestamps.keys
          .where((key) => key.contains('track_'))
          .toList();

      _assetCacheTimestamps.clear();
      _activeResources.clear();

      // Restore essential assets
      final now = DateTime.now();
      for (final asset in essentialAssets) {
        _assetCacheTimestamps[asset] = now;
        _activeResources.add(asset);
      }

      _logger.i('Force memory cleanup completed');
    } catch (e) {
      _logger.e('Error during force memory cleanup: $e');
    }
  }

  /// Stop performance monitoring
  Future<void> stopMonitoring() async {
    try {
      _isMonitoring = false;

      _memoryMonitorTimer?.cancel();
      _batteryOptimizationTimer?.cancel();

      _logger.i('Performance monitoring stopped');
    } catch (e) {
      _logger.e('Error stopping performance monitoring: $e');
    }
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    try {
      await stopMonitoring();
      await cleanupOnNavigation();

      _assetCacheTimestamps.clear();
      _activeResources.clear();

      _logger.i('PerformanceOptimizationService disposed');
    } catch (e) {
      _logger.e('Error disposing PerformanceOptimizationService: $e');
    }
  }
}
