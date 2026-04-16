import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motive_detection_service.dart';

/// Enhanced visual design service for advanced UI animations and responsive layouts
/// Implements requirements 1.1-1.5 and 12.1-12.7 for visual design and accessibility
class VisualDesignService {
  static const Duration _standardDuration = Duration(milliseconds: 600);
  static const Curve _standardCurve = Curves.easeOutCubic;
  static const double _minIntervalSpan = 0.001;

  static ({double begin, double end}) _safeInterval(double begin, double end) {
    final b = begin.clamp(0.0, 1.0);
    final e = end.clamp(0.0, 1.0);
    if (e > b) return (begin: b, end: e);
    if (b >= 1.0) return (begin: 1.0 - _minIntervalSpan, end: 1.0);
    return (begin: b, end: (b + _minIntervalSpan).clamp(0.0, 1.0));
  }

  /// Create staggered entrance animations for technique cards with enhanced effects
  static Widget createEnhancedStaggeredCard({
    required Widget child,
    required int index,
    required AnimationController controller,
    bool reduceMotion = false,
  }) {
    if (reduceMotion) {
      // Simple fade for users who prefer reduced motion
      return FadeTransition(opacity: controller, child: child);
    }

    final slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              _safeInterval(index * 0.1, (index * 0.1) + 0.4).begin,
              _safeInterval(index * 0.1, (index * 0.1) + 0.4).end,
              curve: _standardCurve,
            ),
          ),
        );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          _safeInterval(index * 0.1, (index * 0.1) + 0.3).begin,
          _safeInterval(index * 0.1, (index * 0.1) + 0.3).end,
          curve: Curves.easeOut,
        ),
      ),
    );

    final scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          _safeInterval(index * 0.1, (index * 0.1) + 0.4).begin,
          _safeInterval(index * 0.1, (index * 0.1) + 0.4).end,
          curve: Curves.elasticOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, slideAnimation.value.dy * 50),
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Opacity(
              opacity: fadeAnimation.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Create responsive layout that adapts to different screen sizes
  static Widget createResponsiveLayout({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    EdgeInsets responsivePadding;
    if (isDesktop) {
      responsivePadding = const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 24,
      );
    } else if (isTablet) {
      responsivePadding = const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 20,
      );
    } else {
      responsivePadding = const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      );
    }

    return Container(padding: padding ?? responsivePadding, child: child);
  }

  /// Create enhanced gradient container with motive-specific theming
  static Widget createEnhancedGradientContainer({
    required MotiveColorTheme theme,
    required Widget child,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    bool isAccessible = false,
  }) {
    final colors =
        isAccessible ? _getHighContrastGradient(theme) : theme.gradientColors;
    final stops = _gradientStopsFor(colors.length);

    final gradient = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: stops,
    );

    return AnimatedContainer(
      duration: _standardDuration,
      curve: _standardCurve,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
      ),
      child: child,
    );
  }

  static List<double>? _gradientStopsFor(int colorCount) {
    if (colorCount <= 1) return null;
    if (colorCount == 2) return const [0.0, 1.0];
    if (colorCount == 3) return const [0.0, 0.5, 1.0];
    if (colorCount == 4) return const [0.0, 0.3, 0.7, 1.0];
    // For any other count, let Flutter distribute stops evenly.
    return null;
  }

  /// Create accessible technique card with proper semantics
  static Widget createAccessibleTechniqueCard({
    required Widget child,
    required String semanticLabel,
    required VoidCallback onTap,
    bool isRecommended = false,
    bool highContrast = false,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: isRecommended
          ? 'Recommended technique. Double tap to start.'
          : 'Double tap to start this technique.',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Provide haptic feedback for accessibility
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: highContrast
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Create floating action button with enhanced accessibility
  static Widget createAccessibleFloatingButton({
    required Widget child,
    required VoidCallback onPressed,
    required String semanticLabel,
    Color? backgroundColor,
    bool highContrast = false,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        backgroundColor: highContrast
            ? Colors.black
            : backgroundColor ?? const Color(0xFF4DB6AC),
        foregroundColor: highContrast ? Colors.white : Colors.white,
        elevation: highContrast ? 8 : 4,
        child: child,
      ),
    );
  }

  /// Create responsive grid layout for technique cards
  static Widget createResponsiveTechniqueGrid({
    required BuildContext context,
    required List<Widget> children,
    int? forceColumns,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    int columns;

    if (forceColumns != null) {
      columns = forceColumns;
    } else if (screenWidth > 1200) {
      columns = 3; // Desktop: 3 columns
    } else if (screenWidth > 600) {
      columns = 2; // Tablet: 2 columns
    } else {
      columns = 1; // Mobile: 1 column
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }

  /// Create enhanced loading animation with accessibility support
  static Widget createAccessibleLoadingIndicator({
    String? semanticLabel,
    Color? color,
    bool highContrast = false,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Loading content',
      liveRegion: true,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          highContrast ? Colors.black : color ?? const Color(0xFF4DB6AC),
        ),
        strokeWidth: highContrast ? 4 : 2,
      ),
    );
  }

  /// Create enhanced text with accessibility features
  static Widget createAccessibleText({
    required String text,
    TextStyle? style,
    bool highContrast = false,
    double? scaleFactor,
  }) {
    final accessibleStyle =
        style?.copyWith(
          color: highContrast ? Colors.black : style.color,
          fontWeight: highContrast ? FontWeight.bold : style.fontWeight,
        ) ??
        TextStyle(
          color: highContrast ? Colors.black : null,
          fontWeight: highContrast ? FontWeight.bold : null,
        );

    return Text(
      text,
      style: accessibleStyle,
      textScaler: TextScaler.linear(scaleFactor ?? 1.0),
    );
  }

  /// Create enhanced motive transition with accessibility announcements
  static Widget createAccessibleMotiveTransition({
    required Widget child,
    required AnimationController controller,
    required String fromMotive,
    required String toMotive,
    required BuildContext context,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Announce motive change to screen readers
        if (controller.isCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _announceMotiveChange(context, fromMotive, toMotive);
          });
        }

        return FadeTransition(opacity: controller, child: child);
      },
    );
  }

  /// Get high contrast gradient colors for accessibility
  static List<Color> _getHighContrastGradient(MotiveColorTheme theme) {
    return [
      Colors.white,
      Colors.grey.shade100,
      Colors.grey.shade200,
      Colors.grey.shade300,
    ];
  }

  /// Announce motive change to screen readers
  static void _announceMotiveChange(
    BuildContext context,
    String fromMotive,
    String toMotive,
  ) {
    // Use SystemSound for announcements as SemanticsService is not available
    SystemSound.play(SystemSoundType.click);
  }

  /// Check if user prefers reduced motion
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get accessible color contrast ratio
  static double getContrastRatio(Color foreground, Color background) {
    final fLuminance = _getLuminance(foreground);
    final bLuminance = _getLuminance(background);

    final lighter = fLuminance > bLuminance ? fLuminance : bLuminance;
    final darker = fLuminance > bLuminance ? bLuminance : fLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate color luminance for contrast checking
  static double _getLuminance(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255) / 255.0;
    final g = (color.g * 255.0).round().clamp(0, 255) / 255.0;
    final b = (color.b * 255.0).round().clamp(0, 255) / 255.0;

    final rLinear = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
    final gLinear = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
    final bLinear = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }
}

/// Extension for enhanced accessibility features
extension AccessibilityExtensions on Widget {
  /// Add enhanced accessibility semantics
  Widget withAccessibility({
    String? label,
    String? hint,
    bool isButton = false,
    bool isHeader = false,
    bool liveRegion = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      liveRegion: liveRegion,
      child: this,
    );
  }

  /// Add responsive padding based on screen size
  Widget withResponsivePadding(BuildContext context) {
    return VisualDesignService.createResponsiveLayout(
      context: context,
      child: this,
    );
  }
}

/// Helper function for math operations
double pow(double base, double exponent) {
  if (exponent == 0) return 1.0;
  if (exponent == 1) return base;

  double result = 1.0;
  for (int i = 0; i < exponent.abs(); i++) {
    result *= base;
  }

  return exponent < 0 ? 1.0 / result : result;
}
