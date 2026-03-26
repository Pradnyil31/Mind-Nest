import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/calm/application/calm_recommendation_service.dart';
import '../../features/calm/application/technique_library_service.dart';
import '../../models/calm_technique.dart';
import '../../models/breathing_technique.dart';
import '../../providers/app_providers.dart';
import '../../screens/grounding_exercise_screen.dart';
import '../../screens/affirmations_screen.dart';
import '../../screens/calm_technique_screen.dart';
import '../../screens/breathing_exercise_screen.dart';

/// Quick Access Emergency Panel for immediate anxiety relief
/// Displays 3-4 fastest-acting techniques based on user's motive and effectiveness
class QuickAccessPanel extends ConsumerStatefulWidget {
  final String? userMotive;
  final Color primaryColor;

  const QuickAccessPanel({
    super.key,
    this.userMotive,
    this.primaryColor = const Color(0xFF4DB6AC),
  });

  @override
  ConsumerState<QuickAccessPanel> createState() => _QuickAccessPanelState();
}

class _QuickAccessPanelState extends ConsumerState<QuickAccessPanel> {
  CalmRecommendationService get _recommendationService =>
      ref.read(calmRecommendationServiceProvider);
  List<CalmTechnique> _quickTechniques = [];
  CalmTechnique? _emergencyTechnique;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuickTechniques();
  }

  @override
  void didUpdateWidget(QuickAccessPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userMotive != widget.userMotive) {
      _loadQuickTechniques();
    }
  }

  Future<void> _loadQuickTechniques() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use technique library service for motive-specific emergency techniques
      final libraryService = ref.read(techniqueLibraryProvider.notifier);
      final emergencyTechniques = libraryService.getEmergencyTechniques();

      if (emergencyTechniques.isNotEmpty) {
        setState(() {
          _quickTechniques = emergencyTechniques.take(4).toList();
          _emergencyTechnique = emergencyTechniques.first;
          _isLoading = false;
        });
        return;
      }

      // Fallback to recommendation service
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        // Get effectiveness-based quick access techniques (under 2 minutes)
        final quickTechniques = await _recommendationService
            .getQuickAccessTechniques(user.uid, widget.userMotive);

        // Get the most effective emergency technique for immediate use
        final emergencyTechnique = await _recommendationService
            .getEmergencyTechnique(user.uid, widget.userMotive);

        if (mounted) {
          setState(() {
            _quickTechniques = quickTechniques;
            _emergencyTechnique = emergencyTechnique;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Enhanced fallback with effectiveness-based selection
      if (mounted) {
        setState(() {
          _quickTechniques = _getEffectivenessBasedQuickTechniques(
            widget.userMotive,
          );
          _emergencyTechnique = _getMotiveSpecificEmergencyTechnique(
            widget.userMotive,
          );
          _isLoading = false;
        });
      }
    }
  }

  /// Get effectiveness-based quick techniques as enhanced fallback
  List<CalmTechnique> _getEffectivenessBasedQuickTechniques(String? motive) {
    // Use the new technique library methods for better motive-specific selection
    return CalmTechnique.getEmergencyTechniques(motive);
  }

  /// Get motive-specific emergency technique as fallback
  CalmTechnique _getMotiveSpecificEmergencyTechnique(String? motive) {
    final emergencyTechniques = CalmTechnique.getEmergencyTechniques(motive);
    if (emergencyTechniques.isNotEmpty) {
      return emergencyTechniques.first;
    }

    // Ultimate fallback
    switch (motive) {
      case 'Sleep':
        return CalmTechnique.defaults.firstWhere(
          (t) => t.id == 'body-scan',
          orElse: () =>
              CalmTechnique.defaults.firstWhere((t) => t.id == '5-4-3-2-1'),
        );
      case 'Stress':
        return CalmTechnique.defaults.firstWhere(
          (t) => t.id == 'deep-breathing',
          orElse: () =>
              CalmTechnique.defaults.firstWhere((t) => t.id == '5-4-3-2-1'),
        );
      case 'Anxiety':
        return CalmTechnique.defaults.firstWhere(
          (t) => t.id == '5-4-3-2-1',
          orElse: () => CalmTechnique.defaults.firstWhere(
            (t) => t.id == 'deep-breathing',
          ),
        );
      case 'Focus':
        return CalmTechnique.defaults.firstWhere(
          (t) => t.id == 'mindful-observation',
          orElse: () =>
              CalmTechnique.defaults.firstWhere((t) => t.id == '5-4-3-2-1'),
        );
      case 'Habit Building':
        return CalmTechnique.defaults.firstWhere(
          (t) => t.id == 'positive-affirmations',
          orElse: () =>
              CalmTechnique.defaults.firstWhere((t) => t.id == '5-4-3-2-1'),
        );
      default:
        return CalmTechnique.defaults.firstWhere((t) => t.id == '5-4-3-2-1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.primaryColor.withValues(alpha: 0.1),
            widget.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with motive-specific messaging
          Row(
            children: [
              Icon(Icons.flash_on, color: widget.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                _getMotiveSpecificPanelTitle(widget.userMotive),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          Text(
            _getMotiveSpecificPanelSubtitle(widget.userMotive),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // Emergency technique (most prominent)
            if (_emergencyTechnique != null)
              _EmergencyTechniqueCard(
                technique: _emergencyTechnique!,
                primaryColor: widget.primaryColor,
                onTap: () => _startTechnique(_emergencyTechnique!),
              ),

            const SizedBox(height: 16),

            // Quick techniques grid
            if (_quickTechniques.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      2.4, // Adjusted ratio to comfortably fit 4 buttons
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _quickTechniques.length.clamp(0, 4),
                itemBuilder: (context, index) {
                  final technique = _quickTechniques[index];
                  return _QuickTechniqueButton(
                    technique: technique,
                    primaryColor: widget.primaryColor,
                    onTap: () => _startTechnique(technique),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  void _startTechnique(CalmTechnique technique) {
    // Immediate activation without navigation delays (Requirement 7.3)
    // Use PageRouteBuilder for instant navigation with no transition delays

    if (technique.id == '5-4-3-2-1') {
      // Direct grounding exercise activation
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const GroundingExerciseScreen(),
          transitionDuration: Duration.zero, // Instant navigation
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (technique.id == 'positive-affirmations') {
      // Direct affirmations activation
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AffirmationsScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (technique.type == TechniqueType.breathing) {
      // One-tap breathing exercise activation (Requirement 7.4)
      // Navigate directly to breathing exercise with optimal technique
      _startBreathingExercise();
    } else {
      // Direct technique activation for other techniques
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CalmTechniqueScreen(technique: technique),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  /// Start breathing exercise with optimal technique for user's motive
  void _startBreathingExercise() {
    // Import the breathing technique model and screen
    final BreathingTechnique optimalTechnique = _getOptimalBreathingTechnique();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BreathingExerciseScreen(technique: optimalTechnique),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Get optimal breathing technique based on user's motive
  BreathingTechnique _getOptimalBreathingTechnique() {
    // Import BreathingTechnique defaults
    switch (widget.userMotive) {
      case 'Sleep':
        // 4-7-8 is best for sleep
        return BreathingTechnique.defaults.firstWhere(
          (t) => t.id == '4-7-8',
          orElse: () => BreathingTechnique.defaults.first,
        );
      case 'Stress':
      case 'Anxiety':
        // Box breathing is best for stress/anxiety
        return BreathingTechnique.defaults.firstWhere(
          (t) => t.id == 'box',
          orElse: () => BreathingTechnique.defaults.first,
        );
      case 'Focus':
        // Coherent breathing is best for focus
        return BreathingTechnique.defaults.firstWhere(
          (t) => t.id == 'coherent',
          orElse: () => BreathingTechnique.defaults.first,
        );
      default:
        // Default to box breathing as it's most versatile
        return BreathingTechnique.defaults.firstWhere(
          (t) => t.id == 'box',
          orElse: () => BreathingTechnique.defaults.first,
        );
    }
  }

  /// Get motive-specific panel title
  String _getMotiveSpecificPanelTitle(String? motive) {
    switch (motive) {
      case 'Sleep':
        return 'Sleep Support';
      case 'Stress':
        return 'Stress Relief';
      case 'Anxiety':
        return 'Anxiety Relief';
      case 'Focus':
        return 'Focus Boost';
      case 'Habit Building':
        return 'Quick Motivation';
      default:
        return 'Quick Relief';
    }
  }

  /// Get motive-specific panel subtitle
  String _getMotiveSpecificPanelSubtitle(String? motive) {
    switch (motive) {
      case 'Sleep':
        return 'Calm your mind and prepare for restful sleep';
      case 'Stress':
        return 'Release tension and restore inner calm';
      case 'Anxiety':
        return 'Ground yourself and find your center right now';
      case 'Focus':
        return 'Clear mental fog and sharpen concentration';
      case 'Habit Building':
        return 'Stay motivated and build positive momentum';
      default:
        return 'Immediate techniques for when you need relief right now';
    }
  }
}

class _EmergencyTechniqueCard extends StatelessWidget {
  final CalmTechnique technique;
  final Color primaryColor;
  final VoidCallback onTap;

  const _EmergencyTechniqueCard({
    required this.technique,
    required this.primaryColor,
    required this.onTap,
  });

  /// Get emergency label based on technique type
  String _getEmergencyLabel(String techniqueId) {
    switch (techniqueId) {
      case '5-4-3-2-1':
        return 'GROUNDING';
      case 'deep-breathing':
        return 'BREATHE';
      case 'body-scan':
        return 'RELAX';
      case 'positive-affirmations':
        return 'MOTIVATE';
      case 'clarity-visualization':
        return 'FOCUS';
      default:
        return 'EMERGENCY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    technique.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getEmergencyLabel(technique.id),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        technique.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${technique.durationMinutes} min • Tap to start immediately',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTechniqueButton extends StatelessWidget {
  final CalmTechnique technique;
  final Color primaryColor;
  final VoidCallback onTap;

  const _QuickTechniqueButton({
    required this.technique,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 6.0,
            ), // Optimized padding
            child: Row(
              children: [
                // Icon
                Text(
                  technique.icon,
                  style: const TextStyle(fontSize: 16), // Slightly smaller icon
                ),

                const SizedBox(width: 6),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        technique.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          // Changed from bodyMedium to bodySmall
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1), // Reduced spacing further
                      Text(
                        '${technique.durationMinutes}m',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11, // Explicit smaller font size
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
