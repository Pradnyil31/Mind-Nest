import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/motive_config.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';

/// Service for detecting motive changes and triggering interface adaptations
/// Monitors user profile changes and provides real-time motive updates
class MotiveDetectionService extends StateNotifier<MotiveDetectionState> {
  final FirestoreService _firestoreService;
  final AuthService _authService;
  StreamSubscription<dynamic>? _userSubscription;
  Timer? _refreshTimer;

  MotiveDetectionService({
    FirestoreService? firestoreService,
    AuthService? authService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _authService = authService ?? AuthService(),
       super(const MotiveDetectionState()) {
    _initializeMotiveMonitoring();
  }

  /// Initialize motive monitoring and start listening for changes
  void _initializeMotiveMonitoring() {
    final user = _authService.currentUser;
    if (user != null) {
      _startMotiveMonitoring(user.uid);
    }
  }

  /// Start monitoring user profile for motive changes
  void _startMotiveMonitoring(String userId) {
    _userSubscription?.cancel();

    _userSubscription = _firestoreService
        .getUserStream(userId)
        .listen(
          (userDoc) {
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>;
              final newMotive = data['primaryMotive'] as String?;

              _handleMotiveChange(newMotive);
            }
          },
          onError: (error) {
            state = state.copyWith(
              error: 'Failed to monitor motive changes: $error',
              isLoading: false,
            );
          },
        );
  }

  /// Handle detected motive changes with comprehensive adaptation
  void _handleMotiveChange(String? newMotive) {
    final previousMotive = state.currentMotive;

    if (newMotive != previousMotive) {
      // Motive change detected - trigger comprehensive adaptation
      state = state.copyWith(
        currentMotive: newMotive,
        previousMotive: previousMotive,
        motiveChangeDetected: true,
        lastChangeTime: DateTime.now(),
        isLoading: false,
        error: null,
        adaptationInProgress: true,
      );

      // Schedule automatic interface refresh within 5 seconds
      _scheduleInterfaceRefresh();

      // Preserve cross-motive analytics data
      _preserveCrossMotiveData(previousMotive, newMotive);

      // Trigger comprehensive adaptation process
      _triggerComprehensiveAdaptation(previousMotive, newMotive);
    } else if (state.isLoading) {
      // Initial load complete
      state = state.copyWith(
        currentMotive: newMotive,
        isLoading: false,
        error: null,
      );
    }
  }

  /// Schedule interface refresh within 5 seconds of motive change
  void _scheduleInterfaceRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer(const Duration(seconds: 2), () {
      // Trigger interface adaptation with smooth transitions
      state = state.copyWith(
        shouldRefreshInterface: true,
        motiveChangeDetected: false,
        adaptationInProgress: false,
      );
    });
  }

  /// Trigger comprehensive adaptation process for motive changes
  void _triggerComprehensiveAdaptation(String? fromMotive, String? toMotive) {
    // Log comprehensive adaptation event with enhanced metrics
    final user = _authService.currentUser;
    if (user != null) {
      _firestoreService
          .setDocument(
            collection: 'motive_adaptations',
            docId: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
            data: {
              'userId': user.uid,
              'fromMotive': fromMotive,
              'toMotive': toMotive,
              'adaptationTime': DateTime.now(),
              'adaptationType': 'comprehensive',
              'preserveAnalytics': true,
              'refreshInterface': true,
              'updateRecommendations': true,
              'adaptQuickAccess': true,
              'comprehensiveAdaptation': {
                'visualThemeTransition': true,
                'welcomeMessageUpdate': true,
                'techniqueReordering': true,
                'soundRecommendationUpdate': true,
                'quickAccessPanelAdaptation': true,
                'colorSchemeTransition': true,
                'encouragementMessageUpdate': true,
                'completionMessageUpdate': true,
              },
              'adaptationMetrics': {
                'expectedDuration': '5 seconds',
                'componentsAdapted': 8,
                'userExperienceImpact': 'seamless',
                'dataPreservation': 'complete',
              },
              'crossMotiveInsights': {
                'previousMotiveStrengths': _getMotiveStrengths(fromMotive),
                'newMotiveOpportunities': _getMotiveOpportunities(toMotive),
                'continuityFactors': _getContinuityFactors(
                  fromMotive,
                  toMotive,
                ),
              },
            },
          )
          .catchError((error) {
            // Silent fail - don't block the UI for analytics
          });
    }
  }

  /// Get motive-specific strengths for cross-motive insights
  List<String> _getMotiveStrengths(String? motive) {
    switch (motive) {
      case 'Sleep':
        return ['relaxation techniques', 'bedtime routines', 'body awareness'];
      case 'Stress':
        return ['breathing exercises', 'mindfulness', 'tension release'];
      case 'Anxiety':
        return [
          'grounding techniques',
          'present moment focus',
          'safety building',
        ];
      case 'Focus':
        return [
          'concentration skills',
          'mental clarity',
          'distraction management',
        ];
      case 'Habit Building':
        return [
          'consistency building',
          'motivation maintenance',
          'progress tracking',
        ];
      default:
        return ['general wellness', 'mindfulness', 'self-care'];
    }
  }

  /// Get motive-specific opportunities for new motive
  List<String> _getMotiveOpportunities(String? motive) {
    switch (motive) {
      case 'Sleep':
        return [
          'improved sleep quality',
          'better bedtime habits',
          'deeper rest',
        ];
      case 'Stress':
        return [
          'enhanced resilience',
          'better stress response',
          'increased calm',
        ];
      case 'Anxiety':
        return [
          'reduced worry',
          'increased confidence',
          'better coping skills',
        ];
      case 'Focus':
        return [
          'improved productivity',
          'better concentration',
          'mental clarity',
        ];
      case 'Habit Building':
        return [
          'stronger habits',
          'increased consistency',
          'sustainable change',
        ];
      default:
        return ['overall wellness', 'balanced lifestyle', 'personal growth'];
    }
  }

  /// Get continuity factors between motives for smooth transition
  List<String> _getContinuityFactors(String? fromMotive, String? toMotive) {
    final fromPriorities = MotiveConfig.getCalmTechniquePriorities(fromMotive);
    final toPriorities = MotiveConfig.getCalmTechniquePriorities(toMotive);

    final commonTechniques = fromPriorities
        .where((technique) => toPriorities.contains(technique))
        .toList();

    final continuityFactors = <String>[];

    if (commonTechniques.isNotEmpty) {
      continuityFactors.add(
        'Shared effective techniques: ${commonTechniques.join(", ")}',
      );
    }

    // Add motive-specific continuity insights
    if ((fromMotive == 'Stress' && toMotive == 'Anxiety') ||
        (fromMotive == 'Anxiety' && toMotive == 'Stress')) {
      continuityFactors.add('Strong breathing and grounding technique overlap');
    }

    if ((fromMotive == 'Sleep' && toMotive == 'Stress') ||
        (fromMotive == 'Stress' && toMotive == 'Sleep')) {
      continuityFactors.add('Relaxation techniques transfer well');
    }

    if (fromMotive == 'Focus' || toMotive == 'Focus') {
      continuityFactors.add('Concentration skills enhance all wellness areas');
    }

    return continuityFactors;
  }

  /// Preserve analytics data across motive changes with comprehensive tracking
  void _preserveCrossMotiveData(String? previousMotive, String? newMotive) {
    if (previousMotive != null && newMotive != null) {
      // Log motive transition for analytics
      final user = _authService.currentUser;
      if (user != null) {
        // Enhanced cross-motive data preservation
        _firestoreService
            .setDocument(
              collection: 'motive_transitions',
              docId: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
              data: {
                'userId': user.uid,
                'fromMotive': previousMotive,
                'toMotive': newMotive,
                'transitionTime': DateTime.now(),
                'preserveData': true,
                'crossMotiveTracking': {
                  'previousMotiveProfile': _getMotiveProfileSnapshot(
                    previousMotive,
                  ),
                  'newMotiveProfile': _getMotiveProfileSnapshot(newMotive),
                  'preserveEffectivenessData': true,
                  'preserveUsagePatterns': true,
                  'preservePreferences': true,
                },
                'adaptationMetrics': {
                  'expectedAdaptationTime': 5, // seconds
                  'componentsToAdapt': [
                    'techniqueRecommendations',
                    'colorTheme',
                    'welcomeMessages',
                    'quickAccessPanel',
                    'soundRecommendations',
                  ],
                },
              },
            )
            .catchError((error) {
              // Silent fail - don't block the UI for analytics
            });

        // Create cross-motive effectiveness bridge
        _createCrossMotiveEffectivenessBridge(
          user.uid,
          previousMotive,
          newMotive,
        );
      }
    }
  }

  /// Get motive profile snapshot for cross-motive analytics
  Map<String, dynamic> _getMotiveProfileSnapshot(String motive) {
    final profile = MotiveConfig.getProfile(motive);
    return {
      'displayName': profile?.displayName ?? motive,
      'emoji': profile?.emoji ?? '🌱',
      'calmTechniquePriorities': profile?.calmTechniquePriorities ?? [],
      'recommendedScreens': profile?.recommendedScreens ?? [],
    };
  }

  /// Create effectiveness bridge for cross-motive learning
  void _createCrossMotiveEffectivenessBridge(
    String userId,
    String fromMotive,
    String toMotive,
  ) {
    // Log cross-motive effectiveness data for future recommendations
    _firestoreService
        .setDocument(
          collection: 'cross_motive_effectiveness',
          docId: '${userId}_${fromMotive}_to_$toMotive',
          data: {
            'userId': userId,
            'fromMotive': fromMotive,
            'toMotive': toMotive,
            'transitionTime': DateTime.now(),
            'effectivenessPreservation': {
              'maintainTechniqueHistory': true,
              'adaptRecommendations': true,
              'preserveMoodTrends': true,
            },
            'learningOpportunities': {
              'crossMotiveTechniques': _identifyCrossMotiveTechniques(
                fromMotive,
                toMotive,
              ),
              'sharedEffectivenessPotential': true,
            },
          },
        )
        .catchError((error) {
          // Silent fail - don't block the UI for analytics
        });
  }

  /// Identify techniques that work across multiple motives
  List<String> _identifyCrossMotiveTechniques(
    String fromMotive,
    String toMotive,
  ) {
    final fromPriorities = MotiveConfig.getCalmTechniquePriorities(fromMotive);
    final toPriorities = MotiveConfig.getCalmTechniquePriorities(toMotive);

    // Find common techniques that could maintain effectiveness
    return fromPriorities
        .where((technique) => toPriorities.contains(technique))
        .toList();
  }

  /// Get motive-specific welcome message with smooth transition support and comprehensive context
  String getMotiveWelcomeMessage(String? motive) {
    if (state.motiveChangeDetected && state.previousMotive != null) {
      return _getTransitionWelcomeMessage(state.previousMotive, motive);
    }

    return _getStandardWelcomeMessage(motive);
  }

  /// Get transition welcome message for motive changes with comprehensive adaptation context
  String _getTransitionWelcomeMessage(String? fromMotive, String? toMotive) {
    final fromProfile = MotiveConfig.getProfile(fromMotive);
    final toProfile = MotiveConfig.getProfile(toMotive);

    if (fromProfile != null && toProfile != null) {
      // Provide context-aware transition messages
      final continuityFactors = _getContinuityFactors(fromMotive, toMotive);
      final hasCommonTechniques = continuityFactors.any(
        (factor) => factor.contains('techniques'),
      );

      if (hasCommonTechniques) {
        return '${toProfile.emoji} Transitioning to ${toProfile.displayName} - your proven techniques will continue to serve you well';
      } else {
        return '${toProfile.emoji} Welcome to your ${toProfile.displayName} journey - building on your wellness foundation';
      }
    }

    return _getStandardWelcomeMessage(toMotive);
  }

  /// Get standard welcome message for current motive with personalized content and comprehensive context
  String _getStandardWelcomeMessage(String? motive) {
    final profile = MotiveConfig.getProfile(motive);

    if (profile != null) {
      // Enhanced motive-specific welcome messages with comprehensive context
      switch (motive) {
        case 'Sleep':
          return '${profile.emoji} Find peace and prepare for restful sleep - your sanctuary awaits';
        case 'Stress':
          return '${profile.emoji} Release tension and build resilience - breathe into calm';
        case 'Anxiety':
          return '${profile.emoji} Ground yourself and find your center - you are safe and supported';
        case 'Focus':
          return '${profile.emoji} Clear your mind and sharpen concentration - clarity is within reach';
        case 'Habit Building':
          return '${profile.emoji} Stay motivated and build consistency - every small step counts';
        default:
          return '${profile.emoji} Find your calm and inner peace - your wellness journey continues';
      }
    }

    return '🌱 Find your calm and inner peace - your wellness journey begins here';
  }

  /// Get motive-specific encouragement message
  String getMotiveEncouragementMessage(String? motive) {
    return MotiveConfig.getInsightMessage(motive, 'encouragement');
  }

  /// Get motive-specific completion celebration
  String getMotiveCompletionMessage(String? motive) {
    return MotiveConfig.getInsightMessage(motive, 'completion');
  }

  /// Check if interface adaptation is in progress
  bool get isAdaptationInProgress => state.adaptationInProgress;

  /// Get comprehensive adaptation status with detailed information
  Map<String, dynamic> getAdaptationStatus() {
    return {
      'isInProgress': state.adaptationInProgress,
      'shouldRefreshInterface': state.shouldRefreshInterface,
      'motiveChangeDetected': state.motiveChangeDetected,
      'currentMotive': state.currentMotive,
      'previousMotive': state.previousMotive,
      'lastChangeTime': state.lastChangeTime,
      'adaptationComponents': {
        'visualTheme': state.shouldRefreshInterface,
        'welcomeMessages': state.motiveChangeDetected,
        'techniqueRecommendations': state.shouldRefreshInterface,
        'quickAccessPanel': state.shouldRefreshInterface,
        'soundRecommendations': state.shouldRefreshInterface,
        'colorScheme': state.shouldRefreshInterface,
      },
      'adaptationMetrics': {
        'expectedDuration': '5 seconds',
        'completionStatus': state.adaptationInProgress
            ? 'in_progress'
            : 'completed',
        'dataPreservation': 'enabled',
        'userExperienceImpact': 'seamless',
      },
    };
  }

  /// Get cross-motive insights for comprehensive adaptation
  Map<String, dynamic> getCrossMotiveInsights() {
    if (state.previousMotive == null || state.currentMotive == null) {
      return {};
    }

    return {
      'transitionType': '${state.previousMotive}_to_${state.currentMotive}',
      'continuityFactors': _getContinuityFactors(
        state.previousMotive,
        state.currentMotive,
      ),
      'previousMotiveStrengths': _getMotiveStrengths(state.previousMotive),
      'newMotiveOpportunities': _getMotiveOpportunities(state.currentMotive),
      'sharedTechniques':
          MotiveConfig.getCalmTechniquePriorities(state.previousMotive)
              .where(
                (technique) => MotiveConfig.getCalmTechniquePriorities(
                  state.currentMotive,
                ).contains(technique),
              )
              .toList(),
      'adaptationRecommendations': _getAdaptationRecommendations(
        state.previousMotive,
        state.currentMotive,
      ),
    };
  }

  /// Get adaptation recommendations for smooth motive transitions
  List<String> _getAdaptationRecommendations(
    String? fromMotive,
    String? toMotive,
  ) {
    final recommendations = <String>[];

    // Add general adaptation recommendations
    recommendations.add('Your progress and preferences have been preserved');
    recommendations.add(
      'Technique recommendations have been updated for your new focus',
    );

    // Add specific transition recommendations
    if (fromMotive == 'Sleep' && toMotive == 'Stress') {
      recommendations.add(
        'Your relaxation skills will help with stress management',
      );
    } else if (fromMotive == 'Anxiety' && toMotive == 'Focus') {
      recommendations.add(
        'Grounding techniques will enhance your concentration practice',
      );
    } else if (fromMotive == 'Stress' && toMotive == 'Sleep') {
      recommendations.add(
        'Stress relief techniques will improve your sleep quality',
      );
    } else if (toMotive == 'Habit Building') {
      recommendations.add(
        'Your existing practice creates a strong foundation for habit building',
      );
    }

    recommendations.add(
      'Quick access panel has been optimized for your new goals',
    );

    return recommendations;
  }

  /// Get motive-specific color theme with transition support
  MotiveColorTheme getMotiveColorTheme(String? motive) {
    return MotiveColorTheme.fromMotive(motive);
  }

  /// Mark interface refresh as completed
  void markInterfaceRefreshed() {
    state = state.copyWith(
      shouldRefreshInterface: false,
      adaptationInProgress: false,
    );
  }

  /// Force refresh motive detection
  Future<void> refreshMotiveDetection() async {
    final user = _authService.currentUser;
    if (user != null) {
      state = state.copyWith(isLoading: true, error: null);

      try {
        final userDoc = await _firestoreService.getUserStream(user.uid).first;
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final motive = data['primaryMotive'] as String?;
          _handleMotiveChange(motive);
        }
      } catch (e) {
        state = state.copyWith(
          error: 'Failed to refresh motive: $e',
          isLoading: false,
        );
      }
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// State for motive detection and adaptation
class MotiveDetectionState {
  final String? currentMotive;
  final String? previousMotive;
  final bool motiveChangeDetected;
  final bool shouldRefreshInterface;
  final bool adaptationInProgress;
  final DateTime? lastChangeTime;
  final bool isLoading;
  final String? error;

  const MotiveDetectionState({
    this.currentMotive,
    this.previousMotive,
    this.motiveChangeDetected = false,
    this.shouldRefreshInterface = false,
    this.adaptationInProgress = false,
    this.lastChangeTime,
    this.isLoading = true,
    this.error,
  });

  MotiveDetectionState copyWith({
    String? currentMotive,
    String? previousMotive,
    bool? motiveChangeDetected,
    bool? shouldRefreshInterface,
    bool? adaptationInProgress,
    DateTime? lastChangeTime,
    bool? isLoading,
    String? error,
  }) {
    return MotiveDetectionState(
      currentMotive: currentMotive ?? this.currentMotive,
      previousMotive: previousMotive ?? this.previousMotive,
      motiveChangeDetected: motiveChangeDetected ?? this.motiveChangeDetected,
      shouldRefreshInterface:
          shouldRefreshInterface ?? this.shouldRefreshInterface,
      adaptationInProgress: adaptationInProgress ?? this.adaptationInProgress,
      lastChangeTime: lastChangeTime ?? this.lastChangeTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Motive-specific color theme for smooth transitions
class MotiveColorTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color accentColor;
  final List<Color> gradientColors;

  const MotiveColorTheme({
    required this.primaryColor,
    required this.backgroundColor,
    required this.accentColor,
    required this.gradientColors,
  });

  factory MotiveColorTheme.fromMotive(String? motive) {
    switch (motive) {
      case 'Sleep':
        return MotiveColorTheme(
          primaryColor: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFFF0F4FF),
          accentColor: const Color(0xFF8B5CF6),
          gradientColors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        );
      case 'Stress':
        return MotiveColorTheme(
          primaryColor: const Color(0xFF10B981),
          backgroundColor: const Color(0xFFF0FFF4),
          accentColor: const Color(0xFF059669),
          gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
        );
      case 'Anxiety':
        return MotiveColorTheme(
          primaryColor: const Color(0xFF8B5CF6),
          backgroundColor: const Color(0xFFFFF0F8),
          accentColor: const Color(0xFFA855F7),
          gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
        );
      case 'Focus':
        return MotiveColorTheme(
          primaryColor: const Color(0xFFF59E0B),
          backgroundColor: const Color(0xFFFFF8F0),
          accentColor: const Color(0xFFD97706),
          gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        );
      case 'Habit Building':
        return MotiveColorTheme(
          primaryColor: const Color(0xFFEF4444),
          backgroundColor: const Color(0xFFFFF0F0),
          accentColor: const Color(0xFFDC2626),
          gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        );
      default:
        return MotiveColorTheme(
          primaryColor: const Color(0xFF4DB6AC),
          backgroundColor: const Color(0xFFF3F4F9),
          accentColor: const Color(0xFF26A69A),
          gradientColors: [const Color(0xFF4DB6AC), const Color(0xFF26A69A)],
        );
    }
  }
}

/// Provider for motive detection service
final motiveDetectionProvider =
    StateNotifierProvider<MotiveDetectionService, MotiveDetectionState>(
      (ref) => MotiveDetectionService(),
    );
