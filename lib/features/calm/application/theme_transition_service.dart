import 'package:flutter/material.dart';
import 'motive_detection_service.dart';

/// Service for managing smooth visual theme transitions between motives
/// Provides animated transitions for colors, gradients, and visual elements
class ThemeTransitionService {
  static const Duration _transitionDuration = Duration(milliseconds: 800);
  static const Curve _transitionCurve = Curves.easeInOutCubic;
  static const double _minIntervalSpan = 0.001;

  static ({double begin, double end}) _safeInterval(double begin, double end) {
    final b = begin.clamp(0.0, 1.0);
    final e = end.clamp(0.0, 1.0);
    if (e > b) return (begin: b, end: e);
    // Ensure begin < end to satisfy Interval assertions.
    if (b >= 1.0) return (begin: 1.0 - _minIntervalSpan, end: 1.0);
    return (begin: b, end: (b + _minIntervalSpan).clamp(0.0, 1.0));
  }

  /// Create animated color transition between motive themes
  static AnimatedContainer createAnimatedBackground({
    required MotiveColorTheme theme,
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedContainer(
      duration: duration ?? _transitionDuration,
      curve: curve ?? _transitionCurve,
      decoration: BoxDecoration(color: theme.backgroundColor),
      child: child,
    );
  }

  /// Create animated gradient transition
  static AnimatedContainer createAnimatedGradientContainer({
    required MotiveColorTheme theme,
    required Widget child,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedContainer(
      duration: duration ?? _transitionDuration,
      curve: curve ?? _transitionCurve,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }

  /// Create animated color transition for individual elements
  static TweenAnimationBuilder<Color?> createColorTransition({
    required Color targetColor,
    required Widget Function(Color color) builder,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: targetColor),
      duration: duration ?? _transitionDuration,
      curve: curve ?? _transitionCurve,
      builder: (context, color, child) {
        return builder(color ?? targetColor);
      },
    );
  }

  /// Create staggered entrance animation for technique cards
  static Widget createStaggeredTechniqueCard({
    required Widget child,
    required int index,
    required AnimationController controller,
  }) {
    final interval = _safeInterval(index * 0.1, (index * 0.1) + 0.3);
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          interval.begin,
          interval.end,
          curve: Curves
              .easeOutCubic, // Changed from easeOutBack to prevent values > 1.0
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Clamp opacity to valid range to prevent assertion errors
        final clampedOpacity = animation.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(opacity: clampedOpacity, child: child),
        );
      },
    );
  }

  /// Create smooth scale transition for quick access buttons
  static Widget createScaleTransition({
    required Widget child,
    required AnimationController controller,
    double delay = 0.0,
  }) {
    final interval = _safeInterval(delay, delay + 0.4);
    final animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          interval.begin,
          interval.end,
          curve: Curves.elasticOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.scale(scale: animation.value, child: child);
      },
    );
  }

  /// Create fade transition for welcome messages
  static Widget createFadeTransition({
    required Widget child,
    required AnimationController controller,
    double delay = 0.0,
  }) {
    final interval = _safeInterval(delay, delay + 0.6);
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          interval.begin,
          interval.end,
          curve: Curves.easeInOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(opacity: animation.value, child: child);
      },
    );
  }

  /// Create slide transition for motive change notifications
  static Widget createSlideTransition({
    required Widget child,
    required AnimationController controller,
    Offset beginOffset = const Offset(0, -1),
    Offset endOffset = Offset.zero,
  }) {
    final animation = Tween<Offset>(
      begin: beginOffset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    return SlideTransition(position: animation, child: child);
  }

  /// Create morphing container for smooth shape transitions
  static AnimatedContainer createMorphingContainer({
    required Widget child,
    required BorderRadius borderRadius,
    required EdgeInsets padding,
    required MotiveColorTheme theme,
    Duration? duration,
    Curve? curve,
  }) {
    return AnimatedContainer(
      duration: duration ?? _transitionDuration,
      curve: curve ?? _transitionCurve,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Create ripple effect for motive change indication
  static Widget createRippleEffect({
    required Widget child,
    required AnimationController controller,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RipplePainter(animation: controller, color: color),
          child: child,
        );
      },
    );
  }

  /// Get transition duration based on change type
  static Duration getTransitionDuration(MotiveChangeType changeType) {
    switch (changeType) {
      case MotiveChangeType.initial:
        return const Duration(milliseconds: 600);
      case MotiveChangeType.userInitiated:
        return const Duration(milliseconds: 800);
      case MotiveChangeType.automatic:
        return const Duration(milliseconds: 1000);
    }
  }
}

/// Custom painter for ripple effect
class _RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _RipplePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.5 * animation.value;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3 * (1 - animation.value))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Types of motive changes for different transition styles
enum MotiveChangeType { initial, userInitiated, automatic }

/// Mixin for widgets that need theme transitions
mixin ThemeTransitionMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late AnimationController _themeTransitionController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _themeTransitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _themeTransitionController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  /// Start theme transition animation
  void startThemeTransition() {
    _themeTransitionController.forward(from: 0.0);
  }

  /// Start entrance animation
  void startEntranceAnimation() {
    _entranceController.forward(from: 0.0);
  }

  /// Get theme transition controller
  AnimationController get themeTransitionController =>
      _themeTransitionController;

  /// Get entrance animation controller
  AnimationController get entranceController => _entranceController;
}
