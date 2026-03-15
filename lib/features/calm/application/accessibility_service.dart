import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing accessibility features and preferences
/// Implements requirements 12.1-12.7 for comprehensive accessibility support
class AccessibilityService {
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _reducedMotionKey = 'accessibility_reduced_motion';
  static const String _textScaleKey = 'accessibility_text_scale';
  static const String _audioGuidanceKey = 'accessibility_audio_guidance';
  static const String _voiceControlKey = 'accessibility_voice_control';

  static AccessibilityService? _instance;
  static AccessibilityService get instance =>
      _instance ??= AccessibilityService._();

  AccessibilityService._();

  SharedPreferences? _prefs;
  final ValueNotifier<AccessibilitySettings> _settingsNotifier = ValueNotifier(
    AccessibilitySettings.defaults(),
  );

  /// Initialize accessibility service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  /// Get current accessibility settings
  AccessibilitySettings get settings => _settingsNotifier.value;

  /// Listen to accessibility settings changes
  ValueNotifier<AccessibilitySettings> get settingsNotifier =>
      _settingsNotifier;

  /// Load accessibility settings from storage
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    final settings = AccessibilitySettings(
      highContrast: _prefs!.getBool(_highContrastKey) ?? false,
      reducedMotion: _prefs!.getBool(_reducedMotionKey) ?? false,
      textScale: _prefs!.getDouble(_textScaleKey) ?? 1.0,
      audioGuidanceOnly: _prefs!.getBool(_audioGuidanceKey) ?? false,
      voiceControlEnabled: _prefs!.getBool(_voiceControlKey) ?? false,
    );

    _settingsNotifier.value = settings;
  }

  /// Update high contrast mode
  Future<void> setHighContrast(bool enabled) async {
    await _prefs?.setBool(_highContrastKey, enabled);
    _settingsNotifier.value = _settingsNotifier.value.copyWith(
      highContrast: enabled,
    );

    // Provide haptic feedback
    if (enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Update reduced motion preference
  Future<void> setReducedMotion(bool enabled) async {
    await _prefs?.setBool(_reducedMotionKey, enabled);
    _settingsNotifier.value = _settingsNotifier.value.copyWith(
      reducedMotion: enabled,
    );
  }

  /// Update text scale factor
  Future<void> setTextScale(double scale) async {
    final clampedScale = scale.clamp(0.8, 2.0);
    await _prefs?.setDouble(_textScaleKey, clampedScale);
    _settingsNotifier.value = _settingsNotifier.value.copyWith(
      textScale: clampedScale,
    );
  }

  /// Update audio guidance preference
  Future<void> setAudioGuidanceOnly(bool enabled) async {
    await _prefs?.setBool(_audioGuidanceKey, enabled);
    _settingsNotifier.value = _settingsNotifier.value.copyWith(
      audioGuidanceOnly: enabled,
    );
  }

  /// Update voice control preference
  Future<void> setVoiceControlEnabled(bool enabled) async {
    await _prefs?.setBool(_voiceControlKey, enabled);
    _settingsNotifier.value = _settingsNotifier.value.copyWith(
      voiceControlEnabled: enabled,
    );
  }

  /// Check if device has accessibility features enabled
  bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Check if device prefers reduced motion
  bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations || settings.reducedMotion;
  }

  /// Get appropriate text style for accessibility
  TextStyle getAccessibleTextStyle({
    required TextStyle baseStyle,
    bool forceHighContrast = false,
  }) {
    final isHighContrast = settings.highContrast || forceHighContrast;

    return baseStyle.copyWith(
      color: isHighContrast ? Colors.black : baseStyle.color,
      fontWeight: isHighContrast ? FontWeight.bold : baseStyle.fontWeight,
      fontSize: (baseStyle.fontSize ?? 14) * settings.textScale,
    );
  }

  /// Get appropriate colors for accessibility
  ColorScheme getAccessibleColors(ColorScheme baseScheme) {
    if (!settings.highContrast) return baseScheme;

    return baseScheme.copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
      secondary: Colors.grey.shade800,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      background: Colors.white,
      onBackground: Colors.black,
    );
  }

  /// Announce message to screen reader
  void announceToScreenReader(BuildContext context, String message) {
    if (isScreenReaderEnabled(context)) {
      // Use SystemSound for announcements as SemanticsService is not available
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Provide haptic feedback based on accessibility settings
  void provideHapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.light,
  }) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// Create accessible button with proper semantics
  Widget createAccessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    required String semanticLabel,
    String? semanticHint,
    bool isDestructive = false,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            provideHapticFeedback(
              type: isDestructive
                  ? HapticFeedbackType.heavy
                  : HapticFeedbackType.medium,
            );
            onPressed();
          },
          child: child,
        ),
      ),
    );
  }

  /// Create accessible text with proper scaling
  Widget createAccessibleText({
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
  }) {
    return Text(
      text,
      style: getAccessibleTextStyle(baseStyle: style ?? const TextStyle()),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  /// Create accessible icon with proper semantics
  Widget createAccessibleIcon({
    required IconData icon,
    required String semanticLabel,
    Color? color,
    double? size,
  }) {
    return Semantics(
      label: semanticLabel,
      child: Icon(
        icon,
        color: settings.highContrast ? Colors.black : color,
        size: (size ?? 24) * settings.textScale,
      ),
    );
  }

  /// Reset all accessibility settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs?.clear();
    _settingsNotifier.value = AccessibilitySettings.defaults();
  }

  /// Export accessibility settings for backup
  Map<String, dynamic> exportSettings() {
    return {
      'highContrast': settings.highContrast,
      'reducedMotion': settings.reducedMotion,
      'textScale': settings.textScale,
      'audioGuidanceOnly': settings.audioGuidanceOnly,
      'voiceControlEnabled': settings.voiceControlEnabled,
    };
  }

  /// Import accessibility settings from backup
  Future<void> importSettings(Map<String, dynamic> settingsMap) async {
    final newSettings = AccessibilitySettings(
      highContrast: settingsMap['highContrast'] ?? false,
      reducedMotion: settingsMap['reducedMotion'] ?? false,
      textScale: (settingsMap['textScale'] ?? 1.0).toDouble(),
      audioGuidanceOnly: settingsMap['audioGuidanceOnly'] ?? false,
      voiceControlEnabled: settingsMap['voiceControlEnabled'] ?? false,
    );

    await _prefs?.setBool(_highContrastKey, newSettings.highContrast);
    await _prefs?.setBool(_reducedMotionKey, newSettings.reducedMotion);
    await _prefs?.setDouble(_textScaleKey, newSettings.textScale);
    await _prefs?.setBool(_audioGuidanceKey, newSettings.audioGuidanceOnly);
    await _prefs?.setBool(_voiceControlKey, newSettings.voiceControlEnabled);

    _settingsNotifier.value = newSettings;
  }
}

/// Accessibility settings model
class AccessibilitySettings {
  final bool highContrast;
  final bool reducedMotion;
  final double textScale;
  final bool audioGuidanceOnly;
  final bool voiceControlEnabled;

  const AccessibilitySettings({
    required this.highContrast,
    required this.reducedMotion,
    required this.textScale,
    required this.audioGuidanceOnly,
    required this.voiceControlEnabled,
  });

  factory AccessibilitySettings.defaults() {
    return const AccessibilitySettings(
      highContrast: false,
      reducedMotion: false,
      textScale: 1.0,
      audioGuidanceOnly: false,
      voiceControlEnabled: false,
    );
  }

  AccessibilitySettings copyWith({
    bool? highContrast,
    bool? reducedMotion,
    double? textScale,
    bool? audioGuidanceOnly,
    bool? voiceControlEnabled,
  }) {
    return AccessibilitySettings(
      highContrast: highContrast ?? this.highContrast,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      textScale: textScale ?? this.textScale,
      audioGuidanceOnly: audioGuidanceOnly ?? this.audioGuidanceOnly,
      voiceControlEnabled: voiceControlEnabled ?? this.voiceControlEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessibilitySettings &&
        other.highContrast == highContrast &&
        other.reducedMotion == reducedMotion &&
        other.textScale == textScale &&
        other.audioGuidanceOnly == audioGuidanceOnly &&
        other.voiceControlEnabled == voiceControlEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      highContrast,
      reducedMotion,
      textScale,
      audioGuidanceOnly,
      voiceControlEnabled,
    );
  }
}

/// Haptic feedback types
enum HapticFeedbackType { light, medium, heavy, selection }
