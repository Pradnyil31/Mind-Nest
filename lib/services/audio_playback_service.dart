import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

/// Service for managing ambient sound playback with multi-track mixing
class AudioPlaybackService {
  static final AudioPlaybackService _instance =
      AudioPlaybackService._internal();
  factory AudioPlaybackService() => _instance;
  AudioPlaybackService._internal();

  final Logger _logger = Logger();
  final Map<String, AudioPlayer> _players = {};
  final Map<String, double> _volumes = {};
  double _masterVolume = 0.7;
  Timer? _fadeTimer;
  bool _isDisposed = false;

  /// Stream of currently active sound IDs
  final StreamController<Set<String>> _activeSoundsController =
      StreamController<Set<String>>.broadcast();

  Stream<Set<String>> get activeSounds => _activeSoundsController.stream;

  /// Initialize the audio service
  Future<void> initialize() async {
    try {
      // Configure audio session for background playback
      await _configureAudioSession();
      _logger.i('AudioPlaybackService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize AudioPlaybackService: $e');
      rethrow;
    }
  }

  /// Configure audio session for background playback and interruption handling
  Future<void> _configureAudioSession() async {
    try {
      // This will be handled by just_audio's built-in session management
      // Additional platform-specific configuration can be added here if needed
    } catch (e) {
      _logger.w('Audio session configuration failed: $e');
    }
  }

  /// Play an ambient sound with specified volume
  Future<void> playSound(String soundId, double volume) async {
    if (_isDisposed) return;

    try {
      // Stop existing player for this sound if any
      await stopSound(soundId);

      // Create new audio player
      final player = AudioPlayer();
      _players[soundId] = player;
      _volumes[soundId] = volume;

      // Configure player for looping
      await player.setLoopMode(LoopMode.one);

      // Set volume (combine individual and master volume)
      await player.setVolume(volume * _masterVolume);

      // Load audio asset
      final audioAsset = _getAudioAssetPath(soundId);
      await player.setAsset(audioAsset);

      // Handle player state changes
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _logger.w('Audio completed unexpectedly for sound: $soundId');
        }
      });

      // Handle audio interruptions
      player.playbackEventStream.listen((event) {
        // Handle interruptions and errors
        if (event.processingState == ProcessingState.idle) {
          _logger.i('Audio interrupted for sound: $soundId');
        }
      });

      // Start playback
      await player.play();

      _logger.i('Started playing sound: $soundId with volume: $volume');
      _notifyActiveSoundsChanged();
    } catch (e) {
      _logger.e('Failed to play sound $soundId: $e');
      // Clean up on error
      await _cleanupPlayer(soundId);
      rethrow;
    }
  }

  /// Stop a specific ambient sound
  Future<void> stopSound(String soundId) async {
    try {
      await _cleanupPlayer(soundId);
      _logger.i('Stopped sound: $soundId');
      _notifyActiveSoundsChanged();
    } catch (e) {
      _logger.e('Failed to stop sound $soundId: $e');
    }
  }

  /// Set volume for a specific sound
  Future<void> setVolume(String soundId, double volume) async {
    if (_isDisposed) return;

    try {
      _volumes[soundId] = volume;
      final player = _players[soundId];
      if (player != null) {
        await player.setVolume(volume * _masterVolume);
        _logger.d('Set volume for $soundId: $volume');
      }
    } catch (e) {
      _logger.e('Failed to set volume for $soundId: $e');
    }
  }

  /// Set master volume for all sounds
  Future<void> setMasterVolume(double volume) async {
    if (_isDisposed) return;

    try {
      _masterVolume = volume;

      // Update all active players
      for (final entry in _players.entries) {
        final soundId = entry.key;
        final player = entry.value;
        final individualVolume = _volumes[soundId] ?? 1.0;
        await player.setVolume(individualVolume * _masterVolume);
      }

      _logger.d('Set master volume: $volume');
    } catch (e) {
      _logger.e('Failed to set master volume: $e');
    }
  }

  /// Start timer with fade-out after specified minutes
  Future<void> startTimer(int minutes) async {
    if (_isDisposed) return;

    // Cancel existing timer
    _fadeTimer?.cancel();

    final duration = Duration(minutes: minutes);
    _logger.i('Starting timer for $minutes minutes');

    _fadeTimer = Timer(duration, () async {
      await _fadeOutAndStop();
    });
  }

  /// Cancel the current timer
  void cancelTimer() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _logger.i('Timer cancelled');
  }

  /// Stop all sounds immediately
  Future<void> stopAllSounds() async {
    try {
      _fadeTimer?.cancel();

      final soundIds = List<String>.from(_players.keys);
      for (final soundId in soundIds) {
        await _cleanupPlayer(soundId);
      }

      _logger.i('Stopped all sounds');
      _notifyActiveSoundsChanged();
    } catch (e) {
      _logger.e('Failed to stop all sounds: $e');
    }
  }

  /// Get currently active sound IDs
  Set<String> getActiveSoundIds() {
    return _players.keys.toSet();
  }

  /// Get master volume
  double get masterVolume => _masterVolume;

  /// Get volume for specific sound
  double getVolume(String soundId) {
    return _volumes[soundId] ?? 1.0;
  }

  /// Validate audio file format
  bool isValidAudioFormat(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return ['mp3', 'aac', 'ogg', 'm4a', 'wav'].contains(extension);
  }

  /// Parse audio metadata (placeholder for future implementation)
  Future<Map<String, dynamic>?> parseAudioMetadata(String filePath) async {
    try {
      if (!isValidAudioFormat(filePath)) {
        throw FormatException('Unsupported audio format: $filePath');
      }

      // For now, return basic metadata
      // In the future, this could use a metadata parsing library
      return {
        'title': _getSoundNameFromId(filePath),
        'duration': null, // Would be populated by actual metadata parsing
        'format': filePath.split('.').last.toUpperCase(),
      };
    } catch (e) {
      _logger.e('Failed to parse audio metadata for $filePath: $e');
      return null;
    }
  }

  /// Fade out all sounds over 10 seconds and stop
  Future<void> _fadeOutAndStop() async {
    if (_isDisposed || _players.isEmpty) return;

    _logger.i('Starting fade-out for all sounds');

    const fadeDuration = Duration(seconds: 10);
    const fadeSteps = 20;
    final stepDuration = Duration(
      milliseconds: fadeDuration.inMilliseconds ~/ fadeSteps,
    );

    try {
      for (int step = fadeSteps; step >= 0; step--) {
        if (_isDisposed) break;

        final fadeVolume = (step / fadeSteps) * _masterVolume;

        for (final entry in _players.entries) {
          final soundId = entry.key;
          final player = entry.value;
          final individualVolume = _volumes[soundId] ?? 1.0;
          await player.setVolume(individualVolume * fadeVolume);
        }

        if (step > 0) {
          await Future.delayed(stepDuration);
        }
      }

      // Stop all sounds after fade
      await stopAllSounds();
      _logger.i('Fade-out completed');
    } catch (e) {
      _logger.e('Error during fade-out: $e');
      await stopAllSounds();
    }
  }

  /// Clean up a specific audio player
  Future<void> _cleanupPlayer(String soundId) async {
    final player = _players[soundId];
    if (player != null) {
      try {
        await player.stop();
        await player.dispose();
      } catch (e) {
        _logger.w('Error disposing player for $soundId: $e');
      }
      _players.remove(soundId);
      _volumes.remove(soundId);
    }
  }

  /// Get audio asset path for sound ID
  String _getAudioAssetPath(String soundId) {
    // For now, using the existing audio files as placeholders
    // In production, each sound would have its own dedicated audio file
    const soundAssets = {
      'rain': 'assets/audio/track_1.mp3',
      'ocean': 'assets/audio/track_2.mp3',
      'forest': 'assets/audio/track_3.mp3',
      'thunderstorm': 'assets/audio/track_1.mp3',
      'birds': 'assets/audio/track_2.mp3',
      'crickets': 'assets/audio/track_3.mp3',
      'cafe': 'assets/audio/track_1.mp3',
      'library': 'assets/audio/track_2.mp3',
      'train': 'assets/audio/track_3.mp3',
      'white-noise': 'assets/audio/track_1.mp3',
      'brown-noise': 'assets/audio/track_2.mp3',
      'pink-noise': 'assets/audio/track_3.mp3',
      'fireplace': 'assets/audio/track_1.mp3',
      'singing-bowls': 'assets/audio/track_2.mp3',
      'piano': 'assets/audio/track_3.mp3',
    };

    return soundAssets[soundId] ?? 'assets/audio/track_1.mp3';
  }

  /// Get display name for sound ID
  String _getSoundNameFromId(String soundId) {
    const soundNames = {
      'rain': 'Rain',
      'ocean': 'Ocean Waves',
      'forest': 'Forest',
      'thunderstorm': 'Thunderstorm',
      'birds': 'Morning Birds',
      'crickets': 'Night Crickets',
      'cafe': 'Coffee Shop',
      'library': 'Library',
      'train': 'Train Journey',
      'white-noise': 'White Noise',
      'brown-noise': 'Brown Noise',
      'pink-noise': 'Pink Noise',
      'fireplace': 'Fireplace',
      'singing-bowls': 'Singing Bowls',
      'piano': 'Soft Piano',
    };

    return soundNames[soundId] ?? soundId;
  }

  /// Notify listeners of active sounds changes
  void _notifyActiveSoundsChanged() {
    if (!_activeSoundsController.isClosed) {
      _activeSoundsController.add(getActiveSoundIds());
    }
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    _fadeTimer?.cancel();

    try {
      await stopAllSounds();
      await _activeSoundsController.close();
      _logger.i('AudioPlaybackService disposed');
    } catch (e) {
      _logger.e('Error disposing AudioPlaybackService: $e');
    }
  }
}
