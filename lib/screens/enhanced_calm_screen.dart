import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/motive_config.dart';
import '../models/calm_technique.dart';
import '../services/auth_service.dart';
import '../widgets/calm/interactive_soundscape_widget.dart';
import '../widgets/calm/mini_audio_player.dart';
import '../widgets/calm/quick_access_panel.dart';
import '../widgets/calm/navigation_integration_widget.dart';
import '../features/calm/application/motive_detection_service.dart';
import '../features/calm/application/theme_transition_service.dart';
import '../features/calm/application/calm_recommendation_service.dart';
import '../features/calm/application/technique_library_service.dart';
import '../features/calm/application/visual_design_service.dart';

import '../features/calm/application/responsive_layout_service.dart';
import 'grounding_exercise_screen.dart';
import 'affirmations_screen.dart';
import 'calm_technique_screen.dart';

class EnhancedCalmScreen extends ConsumerStatefulWidget {
  const EnhancedCalmScreen({super.key});

  @override
  ConsumerState<EnhancedCalmScreen> createState() => _EnhancedCalmScreenState();
}

class _EnhancedCalmScreenState extends ConsumerState<EnhancedCalmScreen>
    with TickerProviderStateMixin, ThemeTransitionMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final CalmRecommendationService _recommendationService =
      CalmRecommendationService();
  List<CalmTechnique> _personalizedTechniques = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Initialize accessibility service
    _initializeAccessibility();

    // Start entrance animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startEntranceAnimation();
      _fadeController.forward();
    });
  }

  /// Initialize components
  Future<void> _initializeAccessibility() async {
    // Accessibility service removed based on user request
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Load personalized recommendations based on current motive
  Future<void> _loadPersonalizedRecommendations(String? motive) async {
    if (!mounted) return;

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final recommendations = await _recommendationService
            .getPersonalizedRecommendations(user.uid, motive);

        if (mounted) {
          setState(() {
            _personalizedTechniques = recommendations;
            _isLoadingRecommendations = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _personalizedTechniques = _getPrioritizedTechniques(motive);
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final motiveState = ref.watch(motiveDetectionProvider);
    final currentMotive = motiveState.currentMotive;
    final colorTheme = MotiveColorTheme.fromMotive(currentMotive);

    // Get preferences
    final reduceMotion = VisualDesignService.shouldReduceMotion(context);

    // Handle motive changes and interface refresh with comprehensive adaptation
    ref.listen<MotiveDetectionState>(motiveDetectionProvider, (
      previous,
      current,
    ) {
      if (current.shouldRefreshInterface && mounted) {
        // Trigger smooth theme transition
        startThemeTransition();

        // Load new recommendations for the changed motive
        _loadPersonalizedRecommendations(current.currentMotive);

        // Refresh technique library for new motive
        ref.read(techniqueLibraryProvider.notifier).refreshLibrary();

        // Mark interface as refreshed
        ref.read(motiveDetectionProvider.notifier).markInterfaceRefreshed();

        // Show motive change notification with comprehensive adaptation info
        if (current.motiveChangeDetected && current.previousMotive != null) {
          _showMotiveChangeNotification(
            current.previousMotive,
            current.currentMotive,
          );
        }
      }

      // Show adaptation progress if in progress
      if (current.adaptationInProgress &&
          previous?.adaptationInProgress != true) {
        _showAdaptationProgress(current.currentMotive);
      }
    });

    // Load recommendations on first build
    if (_personalizedTechniques.isEmpty && !_isLoadingRecommendations) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPersonalizedRecommendations(currentMotive);
      });
    }

    if (motiveState.isLoading) {
      return Scaffold(
        backgroundColor: colorTheme.backgroundColor,
        body: Center(
          child: VisualDesignService.createAccessibleLoadingIndicator(
            semanticLabel: 'Loading calm interface',
            color: colorTheme.primaryColor,
            highContrast: false,
          ),
        ),
      );
    }

    return ThemeTransitionService.createAnimatedBackground(
      theme: colorTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(currentMotive, colorTheme),
        body: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  ResponsiveLayoutService.getSpacing(context).md,
                  0,
                  100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Motive-specific welcome header with smooth transitions
                    _buildMotiveWelcomeHeader(currentMotive, colorTheme),
                    SizedBox(
                      height: ResponsiveLayoutService.getSpacing(context).lg,
                    ),

                    // Enhanced Quick Access Emergency Panel
                    _buildEnhancedQuickAccessPanel(currentMotive, colorTheme),
                    SizedBox(
                      height: ResponsiveLayoutService.getSpacing(context).xl,
                    ),

                    // Personalized Techniques Section with staggered animations
                    _buildPersonalizedTechniquesSection(
                      currentMotive,
                      colorTheme,
                      reduceMotion,
                    ),
                    SizedBox(
                      height: ResponsiveLayoutService.getSpacing(context).xl,
                    ),

                    // Ambient Soundscapes Section
                    _buildAmbientSoundscapesSection(currentMotive, colorTheme),
                    SizedBox(
                      height: ResponsiveLayoutService.getSpacing(context).xl,
                    ),

                    // Navigation Integration Section
                    _buildNavigationIntegrationSection(
                      currentMotive,
                      colorTheme,
                    ),
                  ],
                ),
              ),
            ),
            // Mini Audio Player
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniAudioPlayer(primaryColor: colorTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    final profile = MotiveConfig.getProfile(motive);
    final emoji = profile?.emoji ?? '🧘';
    final fontSizes = ResponsiveLayoutService.getFontSizes(context);

    return AppBar(
      title: ThemeTransitionService.createFadeTransition(
        controller: entranceController,
        delay: 0.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: '${profile?.displayName ?? 'Calm'} mode indicator',
              child: Text(emoji, style: TextStyle(fontSize: fontSizes.title)),
            ),
            SizedBox(width: ResponsiveLayoutService.getSpacing(context).sm),
            Text(
              'Calm',
              style: GoogleFonts.lato(
                color: const Color(0xFF2D2D2D),
                fontWeight: FontWeight.bold,
                fontSize: fontSizes.title,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      actions: const [],
    );
  }

  Widget _buildMotiveWelcomeHeader(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    final profile = MotiveConfig.getProfile(motive);
    final displayName = profile?.displayName ?? 'Wellness';
    final emoji = profile?.emoji ?? '🧘';
    final motiveDetection = ref.read(motiveDetectionProvider.notifier);
    final welcomeMessage = motiveDetection.getMotiveWelcomeMessage(motive);
    final encouragementMessage = motiveDetection.getMotiveEncouragementMessage(
      motive,
    );
    final fontSizes = ResponsiveLayoutService.getFontSizes(context);
    final spacing = ResponsiveLayoutService.getSpacing(context);

    return Padding(
      padding: ResponsiveLayoutService.getResponsivePadding(context),
      child: VisualDesignService.createEnhancedGradientContainer(
        theme: colorTheme,
        borderRadius: BorderRadius.circular(20),
        isAccessible: false,
        boxShadow: [
          BoxShadow(
            color: colorTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: ThemeTransitionService.createFadeTransition(
            controller: entranceController,
            delay: 0.4,
            child: Semantics(
              label: 'Welcome to your $displayName journey',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: '$displayName mode',
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: fontSizes.headline),
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your $displayName Journey',
                              style: GoogleFonts.lato(
                                fontSize: fontSizes.subtitle,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: spacing.xs),
                            Text(
                              welcomeMessage,
                              style: GoogleFonts.lato(
                                fontSize: fontSizes.body,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  // Motive-specific encouragement
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      encouragementMessage,
                      style: GoogleFonts.lato(
                        fontSize: fontSizes.caption,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedQuickAccessPanel(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    return Padding(
      padding: ResponsiveLayoutService.getResponsivePadding(context),
      child: ThemeTransitionService.createScaleTransition(
        controller: entranceController,
        delay: 0.6,
        child: QuickAccessPanel(
          userMotive: motive,
          primaryColor: colorTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildPersonalizedTechniquesSection(
    String? motive,
    MotiveColorTheme colorTheme,
    bool reduceMotion,
  ) {
    final spacing = ResponsiveLayoutService.getSpacing(context);

    return Padding(
      padding: ResponsiveLayoutService.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemeTransitionService.createFadeTransition(
            controller: entranceController,
            delay: 0.8,
            child: _buildSectionHeader(
              'More Techniques',
              'Additional ${MotiveConfig.getProfile(motive)?.displayName ?? 'wellness'} practices to explore',
            ),
          ),
          SizedBox(height: spacing.lg),
          _buildPersonalizedTechniquesList(motive, colorTheme, reduceMotion),
        ],
      ),
    );
  }

  Widget _buildPersonalizedTechniquesList(
    String? motive,
    MotiveColorTheme colorTheme,
    bool reduceMotion,
  ) {
    final techniqueLibraryState = ref.watch(techniqueLibraryProvider);

    if (_isLoadingRecommendations || techniqueLibraryState.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveLayoutService.getSpacing(context).lg,
          ),
          child: VisualDesignService.createAccessibleLoadingIndicator(
            semanticLabel: 'Loading personalized techniques',
            color: colorTheme.primaryColor,
            highContrast: false,
          ),
        ),
      );
    }

    // Get techniques from library service, excluding quick access techniques
    final quickAccessIds = _getQuickAccessTechniqueIds(motive);
    final displayTechniques = techniqueLibraryState.allTechniques
        .where((technique) => !quickAccessIds.contains(technique.id))
        .toList();

    return ResponsiveLayoutService.createResponsiveGrid(
      context: context,
      spacing: ResponsiveLayoutService.getSpacing(context).md,
      runSpacing: ResponsiveLayoutService.getSpacing(context).md,
      children: displayTechniques.asMap().entries.map((entry) {
        final index = entry.key;
        final technique = entry.value;
        final techniqueInfo = ref
            .read(techniqueLibraryProvider.notifier)
            .getTechniqueWithMotiveInfo(technique.id);

        return VisualDesignService.createEnhancedStaggeredCard(
          index: index,
          controller: entranceController,
          reduceMotion: reduceMotion,
          child: _buildEnhancedTechniqueCard(
            technique,
            techniqueInfo,
            colorTheme,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmbientSoundscapesSection(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    return Padding(
      padding: ResponsiveLayoutService.getResponsivePadding(context),
      child: ThemeTransitionService.createFadeTransition(
        controller: entranceController,
        delay: 1.0,
        child: InteractiveSoundscapeWidget(
          userMotive: motive,
          primaryColor: colorTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildNavigationIntegrationSection(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    return ThemeTransitionService.createFadeTransition(
      controller: entranceController,
      delay: 1.0,
      child: NavigationIntegrationWidget(
        userMotive: motive,
        primaryColor: colorTheme.primaryColor,
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    final fontSizes = ResponsiveLayoutService.getFontSizes(context);
    final spacing = ResponsiveLayoutService.getSpacing(context);

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: fontSizes.title,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            subtitle,
            style: GoogleFonts.lato(
              fontSize: fontSizes.body,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTechniqueCard(
    CalmTechnique technique,
    TechniqueWithMotiveInfo techniqueInfo,
    MotiveColorTheme colorTheme,
  ) {
    final techniqueColor = _getTechniqueColor(technique.type);
    final fontSizes = ResponsiveLayoutService.getFontSizes(context);
    final spacing = ResponsiveLayoutService.getSpacing(context);
    final iconSizes = ResponsiveLayoutService.getIconSizes(context);

    final semanticLabel =
        '${technique.title}, ${technique.durationMinutes} minutes. '
        '${techniqueInfo.motiveDescription}. '
        '${techniqueInfo.isPrimary ? 'Recommended for your current motive.' : ''}';

    return VisualDesignService.createAccessibleTechniqueCard(
      semanticLabel: semanticLabel,
      onTap: () => _handleTechniqueNavigation(technique),
      isRecommended: techniqueInfo.isPrimary,
      highContrast: false,
      child: Container(
        constraints: ResponsiveLayoutService.getTechniqueCardConstraints(
          context,
        ),
        child: ThemeTransitionService.createMorphingContainer(
          theme: colorTheme,
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.all(spacing.lg),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.md),
                decoration: BoxDecoration(
                  color: techniqueColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  technique.icon,
                  style: TextStyle(fontSize: iconSizes.large),
                ),
              ),
              SizedBox(width: spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            technique.title,
                            style: GoogleFonts.lato(
                              fontSize: fontSizes.subtitle,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        if (techniqueInfo.isPrimary)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.sm,
                              vertical: spacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Recommended',
                              style: GoogleFonts.lato(
                                fontSize: fontSizes.caption,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      techniqueInfo.motiveDescription,
                      style: GoogleFonts.lato(
                        fontSize: fontSizes.body,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (techniqueInfo.motiveBenefits.isNotEmpty) ...[
                      SizedBox(height: spacing.xs),
                      Wrap(
                        spacing: spacing.xs,
                        runSpacing: spacing.xs / 2,
                        children: techniqueInfo.motiveBenefits.take(2).map((
                          benefit,
                        ) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.xs,
                              vertical: spacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorTheme.accentColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              benefit,
                              style: GoogleFonts.lato(
                                fontSize: fontSizes.caption,
                                color: colorTheme.accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: spacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: techniqueColor,
                          size: iconSizes.small,
                        ),
                        SizedBox(width: spacing.xs),
                        Text(
                          '${technique.durationMinutes} min',
                          style: GoogleFonts.lato(
                            fontSize: fontSizes.caption,
                            color: techniqueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Priority: ${techniqueInfo.priorityScore}/3',
                          style: GoogleFonts.lato(
                            fontSize: fontSizes.caption,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: iconSizes.small,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show notification when motive changes with comprehensive adaptation info
  void _showMotiveChangeNotification(String? fromMotive, String? toMotive) {
    final fromProfile = MotiveConfig.getProfile(fromMotive);
    final toProfile = MotiveConfig.getProfile(toMotive);

    if (fromProfile != null && toProfile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(toProfile.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Switched to ${toProfile.displayName} journey',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Techniques, sounds, and quick access adapted',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: MotiveColorTheme.fromMotive(toMotive).primaryColor,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Show adaptation progress indicator
  void _showAdaptationProgress(String? motive) {
    final profile = MotiveConfig.getProfile(motive);
    if (profile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Adapting to ${profile.displayName} preferences...',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          backgroundColor: MotiveColorTheme.fromMotive(motive).primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Helper methods for motive-based personalization
  List<CalmTechnique> _getPrioritizedTechniques(String? motive) {
    final allTechniques = CalmTechnique.defaults;

    // Sort techniques by priority
    final prioritized = <CalmTechnique>[];
    final others = <CalmTechnique>[];

    for (final technique in allTechniques) {
      if (_isTechniquePrioritized(technique, motive)) {
        prioritized.add(technique);
      } else {
        others.add(technique);
      }
    }

    return [...prioritized, ...others];
  }

  /// Get technique IDs that are shown in Quick Access Panel to avoid duplication
  Set<String> _getQuickAccessTechniqueIds(String? motive) {
    // These are the techniques typically shown in Quick Access Panel
    // based on motive and effectiveness (≤2 minutes duration)
    final quickTechniques = CalmTechnique.defaults
        .where((t) => t.durationMinutes <= 2)
        .map((t) => t.id)
        .toSet();

    // Add motive-specific emergency techniques
    switch (motive) {
      case 'Sleep':
        quickTechniques.add('body-scan');
        break;
      case 'Stress':
        quickTechniques.add('deep-breathing');
        break;
      case 'Anxiety':
        quickTechniques.add('5-4-3-2-1');
        break;
      case 'Focus':
        quickTechniques.add('mindful-observation');
        break;
      case 'Habit Building':
        quickTechniques.add('positive-affirmations');
        break;
    }

    return quickTechniques;
  }

  bool _isTechniquePrioritized(CalmTechnique technique, String? motive) {
    return MotiveConfig.isTechniquePrioritized(motive, technique.type.name);
  }

  Color _getTechniqueColor(TechniqueType type) {
    switch (type) {
      case TechniqueType.grounding:
        return const Color(0xFF81C784);
      case TechniqueType.affirmation:
        return const Color(0xFF9575CD);
      case TechniqueType.breathing:
        return const Color(0xFF64B5F6);
      case TechniqueType.visualization:
        return const Color(0xFF4DB6AC);
    }
  }

  void _handleTechniqueNavigation(CalmTechnique technique) {
    if (technique.id == '5-4-3-2-1') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroundingExerciseScreen()),
      );
    } else if (technique.id == 'positive-affirmations') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AffirmationsScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CalmTechniqueScreen(technique: technique),
        ),
      );
    }
  }
}
