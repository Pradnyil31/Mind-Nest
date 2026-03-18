import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared voice assistant service for all guided exercises.
class VoiceService {
  static const String _prefKey = 'voice_assistant_enabled';

  // ── Singleton ──────────────────────────────────────────────────────────────
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isEnabled = true;
  bool _initialized = false;

  bool get isEnabled => _isEnabled;

  // ── init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_prefKey) ?? true;

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  // ── speak ──────────────────────────────────────────────────────────────────
  /// Stops any current speech and speaks [text] from the beginning.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (!_isEnabled) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Registers a one-time completion callback fired when TTS finishes
  /// the current utterance.
  void onComplete(void Function() callback) {
    _tts.setCompletionHandler(callback);
  }

  /// Clears any previously registered completion callback.
  void clearCompletionHandler() {
    _tts.setCompletionHandler(() {});
  }

  // ── stop ───────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Cancels any pending completion handler to unblock suspended callers.
  void cancelPendingResume() {
    _tts.setCompletionHandler(() {});
  }

  // ── setEnabled ─────────────────────────────────────────────────────────────
  /// Mute or unmute the voice assistant.
  /// When muting: stops any current speech immediately.
  /// When unmuting: re-enables voice for future speak() calls — does NOT
  /// replay old speech (to avoid confusing repeats mid-exercise).
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    if (!enabled) {
      // Clear any pending completion handler so suspended awaits unblock.
      _tts.setCompletionHandler(() {});
      cancelPendingResume();
      await _tts.stop();
    }
    // On unmute: simply re-enable — the next speak() call will pick up
    // naturally when the exercise advances to its next step.
  }

  // ── preference helper ──────────────────────────────────────────────────────
  static Future<bool> getSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  // ── dispose ────────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await _tts.stop();
  }
}
