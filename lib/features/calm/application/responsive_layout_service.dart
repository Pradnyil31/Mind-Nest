import 'package:flutter/material.dart';

/// Service for managing responsive layouts across different screen sizes
/// Implements requirement 1.5 for responsive layout adaptation
class ResponsiveLayoutService {
  /// Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  static const double desktopBreakpoint = 1600;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return DeviceType.desktop;
    } else if (width >= tabletBreakpoint) {
      return DeviceType.largeTablet;
    } else if (width >= mobileBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }

  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
      case DeviceType.largeTablet:
        return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  /// Get responsive grid columns for technique cards
  static int getGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 3;
      case DeviceType.largeTablet:
        return 3;
      case DeviceType.tablet:
        return 2;
      case DeviceType.mobile:
        return 1;
    }
  }

  /// Get responsive font sizes
  static ResponsiveFontSizes getFontSizes(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return const ResponsiveFontSizes(
          headline: 32,
          title: 24,
          subtitle: 18,
          body: 16,
          caption: 14,
        );
      case DeviceType.largeTablet:
        return const ResponsiveFontSizes(
          headline: 28,
          title: 22,
          subtitle: 16,
          body: 15,
          caption: 13,
        );
      case DeviceType.tablet:
        return const ResponsiveFontSizes(
          headline: 26,
          title: 20,
          subtitle: 16,
          body: 14,
          caption: 12,
        );
      case DeviceType.mobile:
        return const ResponsiveFontSizes(
          headline: 24,
          title: 18,
          subtitle: 14,
          body: 13,
          caption: 11,
        );
    }
  }

  /// Get responsive spacing values
  static ResponsiveSpacing getSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return const ResponsiveSpacing(xs: 8, sm: 16, md: 24, lg: 32, xl: 48);
      case DeviceType.largeTablet:
        return const ResponsiveSpacing(xs: 6, sm: 12, md: 20, lg: 28, xl: 40);
      case DeviceType.tablet:
        return const ResponsiveSpacing(xs: 6, sm: 12, md: 18, lg: 24, xl: 32);
      case DeviceType.mobile:
        return const ResponsiveSpacing(xs: 4, sm: 8, md: 16, lg: 20, xl: 24);
    }
  }

  /// Create responsive container with adaptive sizing
  static Widget createResponsiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    double? maxWidth,
  }) {
    final deviceType = getDeviceType(context);
    final responsivePadding = padding ?? getResponsivePadding(context);

    double? containerMaxWidth;
    if (maxWidth != null) {
      containerMaxWidth = maxWidth;
    } else {
      switch (deviceType) {
        case DeviceType.desktop:
          containerMaxWidth = 1200;
          break;
        case DeviceType.largeTablet:
          containerMaxWidth = 900;
          break;
        case DeviceType.tablet:
        case DeviceType.mobile:
          containerMaxWidth = null; // Full width
          break;
      }
    }

    Widget content = Container(padding: responsivePadding, child: child);

    if (containerMaxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: containerMaxWidth),
          child: content,
        ),
      );
    }

    return content;
  }

  /// Create responsive grid layout
  static Widget createResponsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    int? forceColumns,
    double spacing = 12,
    double runSpacing = 12,
  }) {
    final columns = forceColumns ?? getGridColumns(context);

    if (columns == 1) {
      // Single column layout for mobile
      return Column(
        children: children.map((child) {
          return Padding(
            padding: EdgeInsets.only(bottom: runSpacing),
            child: child,
          );
        }).toList(),
      );
    }

    // Multi-column layout for tablet and desktop
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }

  /// Create responsive technique card sizing
  static BoxConstraints getTechniqueCardConstraints(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return const BoxConstraints(minHeight: 120);
      case DeviceType.largeTablet:
        return const BoxConstraints(minHeight: 110);
      case DeviceType.tablet:
        return const BoxConstraints(minHeight: 100);
      case DeviceType.mobile:
        return const BoxConstraints(minHeight: 90);
    }
  }

  /// Get responsive icon sizes
  static ResponsiveIconSizes getIconSizes(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return const ResponsiveIconSizes(
          small: 20,
          medium: 28,
          large: 36,
          extraLarge: 48,
        );
      case DeviceType.largeTablet:
        return const ResponsiveIconSizes(
          small: 18,
          medium: 26,
          large: 34,
          extraLarge: 44,
        );
      case DeviceType.tablet:
        return const ResponsiveIconSizes(
          small: 16,
          medium: 24,
          large: 32,
          extraLarge: 40,
        );
      case DeviceType.mobile:
        return const ResponsiveIconSizes(
          small: 14,
          medium: 22,
          large: 28,
          extraLarge: 36,
        );
    }
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Create responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.desktop:
        return 64;
      case DeviceType.largeTablet:
        return 60;
      case DeviceType.tablet:
        return 56;
      case DeviceType.mobile:
        return 56;
    }
  }
}

/// Device type enumeration
enum DeviceType { mobile, tablet, largeTablet, desktop }

/// Responsive font sizes model
class ResponsiveFontSizes {
  final double headline;
  final double title;
  final double subtitle;
  final double body;
  final double caption;

  const ResponsiveFontSizes({
    required this.headline,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.caption,
  });
}

/// Responsive spacing model
class ResponsiveSpacing {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const ResponsiveSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });
}

/// Responsive icon sizes model
class ResponsiveIconSizes {
  final double small;
  final double medium;
  final double large;
  final double extraLarge;

  const ResponsiveIconSizes({
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
  });
}

/// Extension for responsive widgets
extension ResponsiveExtensions on Widget {
  /// Add responsive padding
  Widget withResponsivePadding(BuildContext context) {
    return ResponsiveLayoutService.createResponsiveContainer(
      context: context,
      child: this,
    );
  }

  /// Add responsive constraints
  Widget withResponsiveConstraints(BuildContext context) {
    final constraints = ResponsiveLayoutService.getTechniqueCardConstraints(
      context,
    );
    return ConstrainedBox(constraints: constraints, child: this);
  }
}
