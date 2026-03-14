import '../../../config/motive_config.dart';
import '../../../models/calm_technique.dart';
import 'calm_progress_service.dart';

/// Service for providing personalized calm technique recommendations
/// Based on user motive, time of day, effectiveness data, and usage patterns
class CalmRecommendationService {
  final CalmProgressService _progressService;

  CalmRecommendationService({CalmProgressService? progressService})
    : _progressService = progressService ?? CalmProgressService();

  /// Get personalized technique recommendations for the main calm screen
  /// Returns 2-3 techniques prioritized by motive, effectiveness, and time of day
  Future<List<CalmTechnique>> getPersonalizedRecommendations(
    String userId,
    String? motive,
  ) async {
    try {
      // Get user's technique effectiveness data
      final effectiveness = await _progressService.getTechniqueEffectiveness(
        userId,
      );

      // Get all available techniques
      final allTechniques = CalmTechnique.defaults;

      // Score and rank techniques
      final scoredTechniques = <_ScoredTechnique>[];

      for (final technique in allTechniques) {
        final score = _calculateTechniqueScore(
          technique,
          motive,
          effectiveness,
          RecommendationType.personalizedMain,
        );

        scoredTechniques.add(_ScoredTechnique(technique, score));
      }

      // Sort by score (highest first) and return top 3
      scoredTechniques.sort((a, b) => b.score.compareTo(a.score));

      return scoredTechniques
          .take(3)
          .map((scored) => scored.technique)
          .toList();
    } catch (e) {
      // Fallback to motive-based recommendations if error occurs
      return _getMotiveBasedFallback(motive);
    }
  }

  /// Get techniques optimized for Quick Access Emergency Panel
  /// Returns 3-4 fastest-acting techniques (under 2 minutes) for immediate relief
  Future<List<CalmTechnique>> getQuickAccessTechniques(
    String userId,
    String? motive,
  ) async {
    try {
      // Get user's technique effectiveness data
      final effectiveness = await _progressService.getTechniqueEffectiveness(
        userId,
      );

      // Filter techniques that are 2 minutes or less
      final quickTechniques = CalmTechnique.defaults
          .where((t) => t.durationMinutes <= 2)
          .toList();

      // If we don't have enough quick techniques, add some 5-minute ones
      if (quickTechniques.length < 3) {
        final additionalTechniques = CalmTechnique.defaults
            .where(
              (t) => t.durationMinutes <= 5 && !quickTechniques.contains(t),
            )
            .take(4 - quickTechniques.length);
        quickTechniques.addAll(additionalTechniques);
      }

      // Score and rank techniques for emergency use
      final scoredTechniques = <_ScoredTechnique>[];

      for (final technique in quickTechniques) {
        final score = _calculateTechniqueScore(
          technique,
          motive,
          effectiveness,
          RecommendationType.emergency,
        );

        scoredTechniques.add(_ScoredTechnique(technique, score));
      }

      // Sort by score and return top 3-4
      scoredTechniques.sort((a, b) => b.score.compareTo(a.score));

      return scoredTechniques
          .take(4)
          .map((scored) => scored.technique)
          .toList();
    } catch (e) {
      // Fallback to basic emergency techniques
      return _getEmergencyFallback(motive);
    }
  }

  /// Get the single best emergency technique for immediate use
  /// Prioritizes the most effective technique for the user's motive
  Future<CalmTechnique?> getEmergencyTechnique(
    String userId,
    String? motive,
  ) async {
    try {
      final quickTechniques = await getQuickAccessTechniques(userId, motive);
      return quickTechniques.isNotEmpty ? quickTechniques.first : null;
    } catch (e) {
      // Fallback to 5-4-3-2-1 grounding as it's universally effective
      return CalmTechnique.defaults.firstWhere((t) => t.id == '5-4-3-2-1');
    }
  }

  /// Calculate a comprehensive score for a technique based on multiple factors
  double _calculateTechniqueScore(
    CalmTechnique technique,
    String? motive,
    Map<String, double> effectiveness,
    RecommendationType recommendationType,
  ) {
    double score = 0.0;

    // 1. Motive-based priority (40% weight)
    score += _getMotivePriorityScore(technique, motive) * 0.4;

    // 2. Personal effectiveness (30% weight)
    score += _getEffectivenessScore(technique, effectiveness) * 0.3;

    // 3. Time-of-day appropriateness (20% weight)
    score += _getTimeOfDayScore(technique) * 0.2;

    // 4. Recommendation type bonus (10% weight)
    score += _getRecommendationTypeBonus(technique, recommendationType) * 0.1;

    return score;
  }

  /// Calculate motive-based priority score (0.0 to 1.0)
  double _getMotivePriorityScore(CalmTechnique technique, String? motive) {
    if (motive == null) return 0.5; // Neutral score for no motive

    final priorities = MotiveConfig.getCalmTechniquePriorities(motive);

    // Check if technique type matches motive priorities
    final techniqueTypeName = _getTechniqueTypeName(technique.type);

    for (int i = 0; i < priorities.length; i++) {
      if (priorities[i].toLowerCase().contains(
            techniqueTypeName.toLowerCase(),
          ) ||
          techniqueTypeName.toLowerCase().contains(
            priorities[i].toLowerCase(),
          )) {
        // Higher score for higher priority (first in list gets highest score)
        return 1.0 - (i / priorities.length);
      }
    }

    // Check specific technique matches for motive
    return _getSpecificMotiveTechniqueScore(technique, motive);
  }

  /// Get specific technique scores based on motive research and effectiveness
  double _getSpecificMotiveTechniqueScore(
    CalmTechnique technique,
    String motive,
  ) {
    switch (motive.toLowerCase()) {
      case 'sleep':
        if (technique.id == 'cold-water-visualization') return 0.9;
        if (technique.type == TechniqueType.visualization) return 0.8;
        if (technique.type == TechniqueType.breathing) return 0.7;
        break;

      case 'stress':
        if (technique.type == TechniqueType.breathing) return 0.9;
        if (technique.type == TechniqueType.grounding) return 0.8;
        if (technique.id == 'worry-banking') return 0.85;
        break;

      case 'anxiety':
        if (technique.id == '5-4-3-2-1') return 0.95;
        if (technique.type == TechniqueType.grounding) return 0.9;
        if (technique.type == TechniqueType.breathing) return 0.8;
        break;

      case 'focus':
        if (technique.type == TechniqueType.grounding) return 0.9;
        if (technique.type == TechniqueType.breathing) return 0.8;
        if (technique.type == TechniqueType.visualization) return 0.7;
        break;

      case 'habit building':
        if (technique.type == TechniqueType.affirmation) return 0.9;
        if (technique.type == TechniqueType.breathing) return 0.8;
        if (technique.type == TechniqueType.grounding) return 0.7;
        break;
    }

    return 0.5; // Default neutral score
  }

  /// Calculate effectiveness score based on user's historical data (0.0 to 1.0)
  double _getEffectivenessScore(
    CalmTechnique technique,
    Map<String, double> effectiveness,
  ) {
    final userEffectiveness = effectiveness[technique.title];

    if (userEffectiveness == null) {
      // No data available, return neutral score
      return 0.5;
    }

    // Normalize effectiveness score (assuming mood improvement range is -10 to +10)
    // Positive improvements get higher scores
    if (userEffectiveness > 0) {
      return 0.5 + (userEffectiveness / 20.0).clamp(0.0, 0.5);
    } else {
      return 0.5 + (userEffectiveness / 20.0).clamp(-0.5, 0.0);
    }
  }

  /// Calculate time-of-day appropriateness score (0.0 to 1.0)
  double _getTimeOfDayScore(CalmTechnique technique) {
    final hour = DateTime.now().hour;

    // Morning (6-12): Energizing techniques
    if (hour >= 6 && hour < 12) {
      if (technique.type == TechniqueType.affirmation) return 0.9;
      if (technique.type == TechniqueType.breathing) return 0.8;
      return 0.6;
    }

    // Afternoon (12-18): Focus and stress relief
    if (hour >= 12 && hour < 18) {
      if (technique.type == TechniqueType.grounding) return 0.9;
      if (technique.id == 'worry-banking') return 0.8;
      return 0.7;
    }

    // Evening (18-22): Relaxation and wind-down
    if (hour >= 18 && hour < 22) {
      if (technique.type == TechniqueType.visualization) return 0.9;
      if (technique.id == 'cold-water-visualization') return 0.8;
      return 0.7;
    }

    // Night (22-6): Sleep preparation
    if (hour >= 22 || hour < 6) {
      if (technique.type == TechniqueType.visualization) return 0.95;
      if (technique.id == 'cold-water-visualization') return 0.9;
      return 0.6;
    }

    return 0.7; // Default score
  }

  /// Get bonus score based on recommendation type (0.0 to 1.0)
  double _getRecommendationTypeBonus(
    CalmTechnique technique,
    RecommendationType type,
  ) {
    switch (type) {
      case RecommendationType.emergency:
        // Prioritize quick, grounding techniques for emergencies
        if (technique.durationMinutes <= 2) {
          if (technique.type == TechniqueType.grounding) return 1.0;
          if (technique.type == TechniqueType.breathing) return 0.9;
        }
        return 0.5;

      case RecommendationType.personalizedMain:
        // Balanced approach for main recommendations
        return 0.7;

      case RecommendationType.timeOfDay:
        // Time-based recommendations get time bonus
        return _getTimeOfDayScore(technique);

      case RecommendationType.effectiveness:
        // Effectiveness-based recommendations rely on user data
        return 0.8;
    }
  }

  /// Convert TechniqueType enum to string for comparison
  String _getTechniqueTypeName(TechniqueType type) {
    switch (type) {
      case TechniqueType.grounding:
        return 'Grounding';
      case TechniqueType.affirmation:
        return 'Affirmations';
      case TechniqueType.breathing:
        return 'Breathing';
      case TechniqueType.visualization:
        return 'Visualization';
    }
  }

  /// Fallback recommendations when personalization fails
  List<CalmTechnique> _getMotiveBasedFallback(String? motive) {
    final priorities = MotiveConfig.getCalmTechniquePriorities(motive);
    final techniques = <CalmTechnique>[];

    // Try to find techniques matching motive priorities
    for (final priority in priorities) {
      final matchingTechnique = CalmTechnique.defaults.firstWhere(
        (t) => _getTechniqueTypeName(
          t.type,
        ).toLowerCase().contains(priority.toLowerCase()),
        orElse: () => CalmTechnique.defaults.first,
      );

      if (!techniques.contains(matchingTechnique)) {
        techniques.add(matchingTechnique);
      }

      if (techniques.length >= 3) break;
    }

    // Fill remaining slots if needed
    while (techniques.length < 3) {
      final remaining = CalmTechnique.defaults
          .where((t) => !techniques.contains(t))
          .toList();
      if (remaining.isNotEmpty) {
        techniques.add(remaining.first);
      } else {
        break;
      }
    }

    return techniques;
  }

  /// Emergency fallback techniques when personalization fails
  List<CalmTechnique> _getEmergencyFallback(String? motive) {
    // Always include 5-4-3-2-1 grounding as it's universally effective
    final emergency = [
      CalmTechnique.defaults.firstWhere((t) => t.id == '5-4-3-2-1'),
    ];

    // Add motive-specific emergency techniques
    switch (motive?.toLowerCase()) {
      case 'anxiety':
        emergency.addAll([
          CalmTechnique.defaults.firstWhere(
            (t) => t.id == 'positive-affirmations',
          ),
          CalmTechnique.defaults.firstWhere(
            (t) => t.id == 'cold-water-visualization',
          ),
        ]);
        break;

      case 'stress':
        emergency.addAll([
          CalmTechnique.defaults.firstWhere((t) => t.id == 'worry-banking'),
          CalmTechnique.defaults.firstWhere(
            (t) => t.id == 'positive-affirmations',
          ),
        ]);
        break;

      default:
        // Generic emergency techniques
        emergency.addAll([
          CalmTechnique.defaults.firstWhere(
            (t) => t.id == 'positive-affirmations',
          ),
          CalmTechnique.defaults.firstWhere(
            (t) => t.id == 'cold-water-visualization',
          ),
        ]);
    }

    return emergency.take(4).toList();
  }
}

/// Internal class for scoring techniques
class _ScoredTechnique {
  final CalmTechnique technique;
  final double score;

  _ScoredTechnique(this.technique, this.score);
}

/// Types of recommendations for different contexts
enum RecommendationType {
  personalizedMain,
  emergency,
  timeOfDay,
  effectiveness,
}
