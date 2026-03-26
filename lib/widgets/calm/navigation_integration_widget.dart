import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/calm/application/navigation_integration_service.dart';
import '../../features/calm/application/responsive_layout_service.dart';
import '../../features/calm/application/accessibility_service.dart';
import '../../providers/app_providers.dart';

/// Widget that provides seamless navigation to existing breathing and meditation features
class NavigationIntegrationWidget extends ConsumerStatefulWidget {
  final String? userMotive;
  final Color primaryColor;

  const NavigationIntegrationWidget({
    super.key,
    this.userMotive,
    required this.primaryColor,
  });

  @override
  ConsumerState<NavigationIntegrationWidget> createState() =>
      _NavigationIntegrationWidgetState();
}

class _NavigationIntegrationWidgetState
    extends ConsumerState<NavigationIntegrationWidget> {
  NavigationIntegrationService get _navigationService =>
      ref.read(navigationIntegrationServiceProvider);
  Map<String, bool> _todayUsage = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayUsage();
  }

  Future<void> _loadTodayUsage() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        final usage = await _navigationService.getTodayUsageStatus(user.uid);
        if (mounted) {
          setState(() {
            _todayUsage = usage;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilitySettings = AccessibilityService.instance.settings;
    final fontSizes = ResponsiveLayoutService.getFontSizes(context);
    final spacing = ResponsiveLayoutService.getSpacing(context);
    final suggestions = _navigationService.getNavigationSuggestions(
      widget.userMotive,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: ResponsiveLayoutService.getResponsivePadding(context),
          child: _buildSectionHeader(accessibilitySettings, fontSizes, spacing),
        ),

        SizedBox(height: spacing.md),

        // Navigation Cards
        Padding(
          padding: ResponsiveLayoutService.getResponsivePadding(context),
          child: _isLoading
              ? _buildLoadingState(accessibilitySettings, spacing)
              : _buildNavigationCards(
                  suggestions,
                  accessibilitySettings,
                  fontSizes,
                  spacing,
                ),
        ),

        SizedBox(height: spacing.md),

        // Feature Boundaries Help
        Padding(
          padding: ResponsiveLayoutService.getResponsivePadding(context),
          child: _buildFeatureBoundariesHelp(
            accessibilitySettings,
            fontSizes,
            spacing,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    AccessibilitySettings accessibilitySettings,
    ResponsiveFontSizes fontSizes,
    ResponsiveSpacing spacing,
  ) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibilityService.instance.createAccessibleText(
            text: 'Explore More Practices',
            style: GoogleFonts.lato(
              fontSize: fontSizes.title,
              fontWeight: FontWeight.bold,
              color: accessibilitySettings.highContrast
                  ? Colors.black
                  : const Color(0xFF2D2D2D),
            ),
          ),
          SizedBox(height: spacing.xs),
          AccessibilityService.instance.createAccessibleText(
            text: 'Discover breathing exercises and guided meditations',
            style: GoogleFonts.lato(
              fontSize: fontSizes.body,
              color: accessibilitySettings.highContrast
                  ? Colors.black87
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(
    AccessibilitySettings accessibilitySettings,
    ResponsiveSpacing spacing,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            accessibilitySettings.highContrast
                ? Colors.black
                : widget.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCards(
    List<NavigationSuggestion> suggestions,
    AccessibilitySettings accessibilitySettings,
    ResponsiveFontSizes fontSizes,
    ResponsiveSpacing spacing,
  ) {
    return ResponsiveLayoutService.createResponsiveGrid(
      context: context,
      spacing: spacing.md,
      runSpacing: spacing.md,
      children: suggestions
          .map(
            (suggestion) => _buildNavigationCard(
              suggestion,
              accessibilitySettings,
              fontSizes,
              spacing,
            ),
          )
          .toList(),
    );
  }

  Widget _buildNavigationCard(
    NavigationSuggestion suggestion,
    AccessibilitySettings accessibilitySettings,
    ResponsiveFontSizes fontSizes,
    ResponsiveSpacing spacing,
  ) {
    final hasUsedToday = _todayUsage[suggestion.category] ?? false;
    final cardColor = accessibilitySettings.highContrast
        ? Colors.white
        : Colors.white;
    final borderColor = accessibilitySettings.highContrast
        ? Colors.black
        : Colors.grey.shade200;

    return AccessibilityService.instance.createAccessibleButton(
      semanticLabel:
          '${suggestion.title}. ${suggestion.description}. ${suggestion.estimatedDuration}. ${hasUsedToday ? 'Completed today.' : 'Not completed today.'}',
      semanticHint: 'Navigate to ${suggestion.category} section',
      onPressed: () => _handleNavigation(suggestion),
      child: Container(
        padding: EdgeInsets.all(spacing.lg),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: accessibilitySettings.highContrast ? 2 : 1,
          ),
          boxShadow: accessibilitySettings.highContrast
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.sm),
                  decoration: BoxDecoration(
                    color: accessibilitySettings.highContrast
                        ? Colors.grey.shade200
                        : widget.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: accessibilitySettings.highContrast
                        ? Border.all(color: Colors.black, width: 1)
                        : null,
                  ),
                  child: Icon(
                    suggestion.icon,
                    color: accessibilitySettings.highContrast
                        ? Colors.black
                        : widget.primaryColor,
                    size: ResponsiveLayoutService.getIconSizes(context).medium,
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibilityService.instance.createAccessibleText(
                        text: suggestion.title,
                        style: GoogleFonts.lato(
                          fontSize: fontSizes.subtitle,
                          fontWeight: FontWeight.bold,
                          color: accessibilitySettings.highContrast
                              ? Colors.black
                              : const Color(0xFF2D2D2D),
                        ),
                      ),
                      if (hasUsedToday)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: ResponsiveLayoutService.getIconSizes(
                                context,
                              ).small,
                              color: accessibilitySettings.highContrast
                                  ? Colors.black
                                  : Colors.green,
                            ),
                            SizedBox(width: spacing.xs),
                            AccessibilityService.instance.createAccessibleText(
                              text: 'Completed today',
                              style: GoogleFonts.lato(
                                fontSize: fontSizes.caption,
                                color: accessibilitySettings.highContrast
                                    ? Colors.black
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            AccessibilityService.instance.createAccessibleText(
              text: suggestion.description,
              style: GoogleFonts.lato(
                fontSize: fontSizes.body,
                color: accessibilitySettings.highContrast
                    ? Colors.black87
                    : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            SizedBox(height: spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: ResponsiveLayoutService.getIconSizes(context).small,
                      color: accessibilitySettings.highContrast
                          ? Colors.black
                          : widget.primaryColor,
                    ),
                    SizedBox(width: spacing.xs),
                    AccessibilityService.instance.createAccessibleText(
                      text: suggestion.estimatedDuration,
                      style: GoogleFonts.lato(
                        fontSize: fontSizes.caption,
                        color: accessibilitySettings.highContrast
                            ? Colors.black
                            : widget.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: ResponsiveLayoutService.getIconSizes(context).small,
                  color: accessibilitySettings.highContrast
                      ? Colors.black
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBoundariesHelp(
    AccessibilitySettings accessibilitySettings,
    ResponsiveFontSizes fontSizes,
    ResponsiveSpacing spacing,
  ) {
    final boundaries = _navigationService.getFeatureBoundaries();

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: accessibilitySettings.highContrast
            ? Colors.grey.shade100
            : widget.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: accessibilitySettings.highContrast
            ? Border.all(color: Colors.black, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: ResponsiveLayoutService.getIconSizes(context).small,
                color: accessibilitySettings.highContrast
                    ? Colors.black
                    : widget.primaryColor,
              ),
              SizedBox(width: spacing.xs),
              AccessibilityService.instance.createAccessibleText(
                text: 'Feature Guide',
                style: GoogleFonts.lato(
                  fontSize: fontSizes.body,
                  fontWeight: FontWeight.w600,
                  color: accessibilitySettings.highContrast
                      ? Colors.black
                      : widget.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          ...boundaries.entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: EdgeInsets.only(top: spacing.xs, right: spacing.xs),
                    decoration: BoxDecoration(
                      color: accessibilitySettings.highContrast
                          ? Colors.black
                          : widget.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.lato(
                          fontSize: fontSizes.caption,
                          color: accessibilitySettings.highContrast
                              ? Colors.black87
                              : Colors.grey.shade700,
                        ),
                        children: [
                          TextSpan(
                            text: '${entry.key.toUpperCase()}: ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: entry.value),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(NavigationSuggestion suggestion) {
    // Provide haptic feedback
    AccessibilityService.instance.provideHapticFeedback(
      type: HapticFeedbackType.selection,
    );

    switch (suggestion.category) {
      case 'breathing':
        _navigationService.navigateToBreathing(context);
        break;
      case 'meditation':
        _navigationService.navigateToMeditation(
          context,
          category: _getMeditationCategory(),
        );
        break;
    }
  }

  String? _getMeditationCategory() {
    // Map motive to meditation category for better targeting
    switch (widget.userMotive) {
      case 'Sleep':
        return 'sleep';
      case 'Stress':
        return 'stress';
      case 'Anxiety':
        return 'anxiety';
      case 'Focus':
        return 'focus';
      default:
        return null;
    }
  }
}
