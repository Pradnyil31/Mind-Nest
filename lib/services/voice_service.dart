import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared voice assistant service for all guided exercises.
///
/// Usage:
///   final voice = VoiceService();
///   await voice.init();
///   voice.speak('Close your eyes and breathe slowly.');
///   voice.dispose(); // call in dispose()
class VoiceService {
  static const String _prefKey = 'voice_assistant_enabled';

  final FlutterTts _tts = FlutterTts();
  bool _isEnabled = true;
  bool _initialized = false;

  bool get isEnabled => _isEnabled;

  /// Initialise the TTS engine and load user preference.
  /// Must be awaited before calling speak().
  Future<void> init() async {
    if (_initialized) return;

    // Load persisted preference
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_prefKey) ?? true;

    // Configure engine — use device defaults for language/locale
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45); // Calm, slightly slower than default
    await _tts.setPitch(1.0);       // Natural pitch

    _initialized = true;
  }

  /// Speak [text]. Cancels any ongoing speech first.
  /// Silent no-op if voice assistant is disabled or text is empty.
  Future<void> speak(String text) async {
    if (!_isEnabled || text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Stop any currently playing speech immediately.
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Toggle and persist.
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) await _tts.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  /// Read the saved preference without instantiating the full service.
  static Future<bool> getSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  /// Call in screen dispose().
  Future<void> dispose() async {
    await _tts.stop();
  }
}
