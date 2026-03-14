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

  // ── Smart resume tracking ──────────────────────────────────────────────────
  /// The full text of the most recently started utterance.
  String _fullText = '';
  /// When speak() was last called (i.e., when TTS actually started).
  DateTime? _speechStartTime;
  /// When the user pressed mute.
  DateTime? _muteTimestamp;

  /// Approximate words-per-second at speech rate 0.45.
  /// 0.45 rate ≈ 80 wpm ≈ 1.33 words/second.
  static const double _wordsPerSecond = 1.33;

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
    _fullText = text;
    if (!_isEnabled) return;
    await _tts.stop();
    _speechStartTime = DateTime.now();
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

  // ── setEnabled (smart resume) ──────────────────────────────────────────────
  /// On mute  → immediately stop TTS, record timestamp.
  /// On unmute → estimate which word was being spoken, resume from there.
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    if (!enabled) {
      // MUTING: record when we muted
      _muteTimestamp = DateTime.now();
      await _tts.stop();
    } else {
      // UNMUTING: resume from estimated word position
      if (_fullText.isNotEmpty &&
          _speechStartTime != null &&
          _muteTimestamp != null) {
        final elapsedMs =
            _muteTimestamp!.difference(_speechStartTime!).inMilliseconds;
        final secondsSpoken = elapsedMs / 1000.0;
        final wordsSpoken = (secondsSpoken * _wordsPerSecond).floor();

        final words = _fullText.split(' ');
        final remaining = (wordsSpoken < words.length)
            ? words.sublist(wordsSpoken).join(' ')
            : '';

        if (remaining.trim().isNotEmpty) {
          _speechStartTime = DateTime.now();
          _muteTimestamp = null;
          await _tts.speak(remaining);
        }
      }
    }
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
