import 'package:flutter_tts/flutter_tts.dart';

/// Shared voice assistant service for all guided exercises.
class VoiceService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  // ── init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  // ── speak ──────────────────────────────────────────────────────────────────
  /// Stops any current speech and speaks [text] from the beginning.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
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

  // ── dispose ────────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await _tts.stop();
  }
}
