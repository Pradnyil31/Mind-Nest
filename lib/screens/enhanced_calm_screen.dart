import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/motive_config.dart';
import '../models/calm_technique.dart';
import '../services/auth_service.dart';
import '../widgets/calm/interactive_soundscape_widget.dart';
import '../widgets/calm/mini_audio_player.dart';
import '../widgets/calm/quick_access_panel.dart';
import '../features/calm/application/motive_detection_service.dart';
import '../features/calm/application/theme_transition_service.dart';
import '../features/calm/application/calm_recommendation_service.dart';
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

    // Start entrance animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startEntranceAnimation();
      _fadeController.forward();
    });
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
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Motive-specific welcome header with smooth transitions
                    _buildMotiveWelcomeHeader(currentMotive, colorTheme),
                    const SizedBox(height: 24),

                    // Enhanced Quick Access Emergency Panel
                    _buildEnhancedQuickAccessPanel(currentMotive, colorTheme),
                    const SizedBox(height: 32),

                    // Personalized Techniques Section with staggered animations
                    _buildPersonalizedTechniquesSection(
                      currentMotive,
                      colorTheme,
                    ),
                    const SizedBox(height: 32),

                    // Ambient Soundscapes Section
                    _buildAmbientSoundscapesSection(currentMotive, colorTheme),
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

    return AppBar(
      title: ThemeTransitionService.createFadeTransition(
        controller: entranceController,
        delay: 0.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'Calm',
              style: GoogleFonts.lato(
                color: const Color(0xFF2D2D2D),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
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

    return ThemeTransitionService.createAnimatedGradientContainer(
      theme: colorTheme,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: colorTheme.primaryColor.withValues(alpha: 0.2),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ThemeTransitionService.createFadeTransition(
          controller: entranceController,
          delay: 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your $displayName Journey',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          welcomeMessage,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Motive-specific encouragement
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  encouragementMessage,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedQuickAccessPanel(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    return ThemeTransitionService.createScaleTransition(
      controller: entranceController,
      delay: 0.6,
      child: QuickAccessPanel(
        userMotive: motive,
        primaryColor: colorTheme.primaryColor,
      ),
    );
  }

  Widget _buildPersonalizedTechniquesSection(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemeTransitionService.createFadeTransition(
          controller: entranceController,
          delay: 0.8,
          child: _buildSectionHeader(
            'Personalized Techniques',
            'Curated for your ${MotiveConfig.getProfile(motive)?.displayName ?? 'wellness'} journey',
          ),
        ),
        const SizedBox(height: 16),
        _buildPersonalizedTechniquesList(motive, colorTheme),
      ],
    );
  }

  Widget _buildPersonalizedTechniquesList(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    if (_isLoadingRecommendations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final techniques = _personalizedTechniques.isNotEmpty
        ? _personalizedTechniques
        : _getPrioritizedTechniques(motive);

    return Column(
      children: techniques.asMap().entries.map((entry) {
        final index = entry.key;
        final technique = entry.value;

        return ThemeTransitionService.createStaggeredTechniqueCard(
          index: index,
          controller: entranceController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTechniqueCard(technique, motive, colorTheme),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmbientSoundscapesSection(
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    return ThemeTransitionService.createFadeTransition(
      controller: entranceController,
      delay: 1.0,
      child: InteractiveSoundscapeWidget(
        userMotive: motive,
        primaryColor: colorTheme.primaryColor,
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTechniqueCard(
    CalmTechnique technique,
    String? motive,
    MotiveColorTheme colorTheme,
  ) {
    final techniqueColor = _getTechniqueColor(technique.type);

    return GestureDetector(
      onTap: () => _handleTechniqueNavigation(technique),
      child: ThemeTransitionService.createMorphingContainer(
        theme: colorTheme,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: techniqueColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(technique.icon, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technique.title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getMotiveSpecificDescription(technique, motive),
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: techniqueColor),
                      const SizedBox(width: 4),
                      Text(
                        '${technique.durationMinutes} min',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: techniqueColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_isTechniquePrioritized(technique, motive))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorTheme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Recommended',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
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

  bool _isTechniquePrioritized(CalmTechnique technique, String? motive) {
    return MotiveConfig.isTechniquePrioritized(motive, technique.type.name);
  }

  String _getMotiveSpecificDescription(
    CalmTechnique technique,
    String? motive,
  ) {
    // Return motive-specific benefits for techniques
    if (motive == 'Sleep' && technique.type == TechniqueType.grounding) {
      return 'Perfect for calming racing thoughts before bed';
    } else if (motive == 'Anxiety' &&
        technique.type == TechniqueType.grounding) {
      return 'Anchor yourself in the present moment';
    } else if (motive == 'Focus' &&
        technique.type == TechniqueType.visualization) {
      return 'Clear mental fog and enhance concentration';
    } else if (motive == 'Stress' &&
        technique.type == TechniqueType.breathing) {
      return 'Release tension and restore calm energy';
    } else if (motive == 'Habit Building' &&
        technique.type == TechniqueType.affirmation) {
      return 'Build motivation and reinforce positive habits';
    }
    return technique.description;
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
