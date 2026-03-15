import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'error_recovery_service.dart';
import '../../../services/audio_playback_service.dart';

/// Robust audio service with comprehensive error handling and recovery
class RobustAudioService {
  final AudioPlaybackService _audioService;
  final ErrorRecoveryService _errorRecovery;
  final Map<String, AudioPlayer> _players = {};
  final Map<String, String> _cachedAudioPaths = {};

  // Circuit breakers for different audio operations
  static const String _downloadCircuit = 'audio_download';

  RobustAudioService(this._audioService)
    : _errorRecovery = ErrorRecoveryService();

  /// Plays a sound with comprehensive error handling
  Future<bool> playSound(String soundId, double volume) async {
    try {
      return await _errorRecovery.withRetry(
        () async {
          // Validate audio file before playback
          final isValid = await _validateAudioFile(soundId);
          if (!isValid) {
            throw AudioPlaybackException(
              'Audio file validation failed',
              soundId,
            );
          }

          await _audioService.playSound(soundId, volume);
          return true;
        },
        maxRetries: 3,
        operationName: 'playSound($soundId)',
      );
    } on AudioPlaybackException {
      // Try fallback audio or silent mode
      return await _handleAudioPlaybackFailure(soundId, volume);
    } catch (e) {
      developer.log(
        'Failed to play sound $soundId: $e',
        name: 'RobustAudioService',
        error: e,
      );
      return false;
    }
  }

  /// Stops a sound with error handling
  Future<bool> stopSound(String soundId) async {
    try {
      await _audioService.stopSound(soundId);
      return true;
    } catch (e) {
      developer.log(
        'Failed to stop sound $soundId: $e',
        name: 'RobustAudioService',
        error: e,
      );
      // Force cleanup of player if it exists
      _players[soundId]?.dispose();
      _players.remove(soundId);
      return false;
    }
  }

  /// Sets volume with validation and error handling
  Future<bool> setVolume(String soundId, double volume) async {
    // Validate volume range
    if (volume < 0.0 || volume > 1.0) {
      developer.log(
        'Invalid volume value: $volume. Must be between 0.0 and 1.0',
        name: 'RobustAudioService',
      );
      return false;
    }

    try {
      await _audioService.setVolume(soundId, volume);
      return true;
    } catch (e) {
      developer.log(
        'Failed to set volume for $soundId: $e',
        name: 'RobustAudioService',
        error: e,
      );
      return false;
    }
  }

  /// Starts timer with fade-out and error handling
  Future<bool> startTimer(int minutes) async {
    if (minutes <= 0) {
      developer.log(
        'Invalid timer duration: $minutes. Must be positive',
        name: 'RobustAudioService',
      );
      return false;
    }

    try {
      await _audioService.startTimer(minutes);
      return true;
    } catch (e) {
      developer.log(
        'Failed to start timer: $e',
        name: 'RobustAudioService',
        error: e,
      );
      return false;
    }
  }

  /// Validates audio file integrity and format
  Future<bool> _validateAudioFile(String soundId) async {
    try {
      // Check if file exists in assets
      final assetPath = 'assets/audio/$soundId.mp3';

      try {
        await rootBundle.load(assetPath);
        return true;
      } on FlutterError {
        // Asset not found, check cached files
        return await _validateCachedAudioFile(soundId);
      }
    } catch (e) {
      developer.log(
        'Audio file validation failed for $soundId: $e',
        name: 'RobustAudioService',
        error: e,
      );
      return false;
    }
  }

  /// Validates cached audio files
  Future<bool> _validateCachedAudioFile(String soundId) async {
    try {
      final cachedPath = _cachedAudioPaths[soundId];
      if (cachedPath == null) return false;

      final file = File(cachedPath);
      if (!await file.exists()) return false;

      // Check file size (should be > 0)
      final stat = await file.stat();
      if (stat.size == 0) {
        await file.delete();
        _cachedAudioPaths.remove(soundId);
        return false;
      }

      return true;
    } catch (e) {
      developer.log(
        'Cached audio validation failed for $soundId: $e',
        name: 'RobustAudioService',
        error: e,
      );
      return false;
    }
  }

  /// Handles audio playback failures with fallback strategies
  Future<bool> _handleAudioPlaybackFailure(
    String soundId,
    double volume,
  ) async {
    developer.log(
      'Handling audio playback failure for $soundId',
      name: 'RobustAudioService',
    );

    // Strategy 1: Try alternative audio format
    final alternativeFormats = ['mp3', 'aac', 'ogg'];
    for (final format in alternativeFormats) {
      try {
        final alternativePath = 'assets/audio/$soundId.$format';
        await rootBundle.load(alternativePath);

        // Try playing with alternative format
        await _audioService.playSound('$soundId.$format', volume);
        return true;
      } catch (e) {
        continue;
      }
    }

    // Strategy 2: Try downloading from network if available
    if (await _isNetworkAvailable()) {
      final downloaded = await _downloadAudioFile(soundId);
      if (downloaded) {
        try {
          await _audioService.playSound(soundId, volume);
          return true;
        } catch (e) {
          developer.log(
            'Failed to play downloaded audio for $soundId: $e',
            name: 'RobustAudioService',
            error: e,
          );
        }
      }
    }

    // Strategy 3: Provide silent fallback with user notification
    developer.log(
      'All audio fallback strategies failed for $soundId, using silent mode',
      name: 'RobustAudioService',
    );

    return false;
  }

  /// Downloads audio file with error handling
  Future<bool> _downloadAudioFile(String soundId) async {
    return await _errorRecovery.withCircuitBreaker(
          () async {
            // This would integrate with your audio CDN/server
            // For now, return false as we don't have a download source
            throw UnimplementedError('Audio download not implemented');
          },
          circuitName: _downloadCircuit,
          failureThreshold: 3,
          resetTimeout: const Duration(minutes: 5),
        ) ??
        false;
  }

  /// Checks network availability
  Future<bool> _isNetworkAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      developer.log(
        'Failed to check network connectivity: $e',
        name: 'RobustAudioService',
        error: e,
      );
      return false;
    }
  }

  /// Handles audio interruptions (calls, notifications)
  void handleAudioInterruption() {
    developer.log(
      'Audio interruption detected, pausing all sounds',
      name: 'RobustAudioService',
    );

    // Pause all active players
    for (final player in _players.values) {
      try {
        player.pause();
      } catch (e) {
        developer.log(
          'Failed to pause player during interruption: $e',
          name: 'RobustAudioService',
          error: e,
        );
      }
    }
  }

  /// Resumes audio after interruption
  void resumeAfterInterruption() {
    developer.log(
      'Resuming audio after interruption',
      name: 'RobustAudioService',
    );

    // Resume all previously active players
    for (final player in _players.values) {
      try {
        if (player.processingState == ProcessingState.ready) {
          player.play();
        }
      } catch (e) {
        developer.log(
          'Failed to resume player after interruption: $e',
          name: 'RobustAudioService',
          error: e,
        );
      }
    }
  }

  /// Cleans up resources and handles disposal errors
  Future<void> dispose() async {
    developer.log('Disposing RobustAudioService', name: 'RobustAudioService');

    final disposalFutures = _players.values.map((player) async {
      try {
        await player.dispose();
      } catch (e) {
        developer.log(
          'Error disposing audio player: $e',
          name: 'RobustAudioService',
          error: e,
        );
      }
    });

    await Future.wait(disposalFutures);
    _players.clear();
    _cachedAudioPaths.clear();
  }

  /// Gets current audio system health status
  Map<String, dynamic> getSystemHealth() {
    return {
      'activePlayers': _players.length,
      'cachedFiles': _cachedAudioPaths.length,
      'memoryUsage': _estimateMemoryUsage(),
      'lastError': _getLastError(),
    };
  }

  int _estimateMemoryUsage() {
    // Rough estimate: each player uses ~1MB, cached files vary
    return _players.length * 1024 * 1024;
  }

  String? _getLastError() {
    // This would track the most recent error for diagnostics
    // Implementation depends on your logging strategy
    return null;
  }
}

/// Extension for audio format validation
extension AudioFormatValidator on String {
  bool get isValidAudioFormat {
    final supportedFormats = ['mp3', 'aac', 'ogg', 'wav', 'm4a'];
    final extension = split('.').last.toLowerCase();
    return supportedFormats.contains(extension);
  }
}
