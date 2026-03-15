import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/calm_technique.dart';
import 'motive_detection_service.dart';

/// Service for managing motive-specific technique library organization
/// Provides dynamic technique prioritization, filtering, and categorization
class TechniqueLibraryService extends StateNotifier<TechniqueLibraryState> {
  final MotiveDetectionService _motiveDetectionService;
  StreamSubscription<MotiveDetectionState>? _motiveSubscription;

  TechniqueLibraryService({MotiveDetectionService? motiveDetectionService})
    : _motiveDetectionService =
          motiveDetectionService ?? MotiveDetectionService(),
      super(const TechniqueLibraryState()) {
    _initializeLibrary();
  }

  /// Initialize the technique library with current motive
  void _initializeLibrary() {
    final currentMotive = _motiveDetectionService.state.currentMotive;
    _updateLibraryForMotive(currentMotive);

    // Listen for motive changes
    _motiveSubscription = _motiveDetectionService.stream.listen((motiveState) {
      if (motiveState.shouldRefreshInterface ||
          motiveState.motiveChangeDetected) {
        _updateLibraryForMotive(motiveState.currentMotive);
      }
    });
  }

  /// Update library organization for new motive
  void _updateLibraryForMotive(String? motive) {
    final prioritizedTechniques = CalmTechnique.getMotivePrioritized(motive);
    final categorizedTechniques = CalmTechnique.getMotiveCategorized(motive);
    final emergencyTechniques = CalmTechnique.getEmergencyTechniques(motive);
    final primaryTechniques = CalmTechnique.getMotiveFiltered(
      motive,
      primaryOnly: true,
    );

    state = state.copyWith(
      currentMotive: motive,
      allTechniques: prioritizedTechniques,
      categorizedTechniques: categorizedTechniques,
      emergencyTechniques: emergencyTechniques,
      primaryTechniques: primaryTechniques,
      isLoading: false,
    );
  }

  /// Get techniques for specific category with motive prioritization
  List<CalmTechnique> getTechniquesByCategory(TechniqueType category) {
    return state.categorizedTechniques[category] ?? [];
  }

  /// Get emergency techniques for quick access panel
  List<CalmTechnique> getEmergencyTechniques() {
    return state.emergencyTechniques;
  }

  /// Get primary techniques for current motive
  List<CalmTechnique> getPrimaryTechniques() {
    return state.primaryTechniques;
  }

  /// Get all techniques prioritized by current motive
  List<CalmTechnique> getAllTechniques() {
    return state.allTechniques;
  }

  /// Get technique with motive-specific information
  TechniqueWithMotiveInfo getTechniqueWithMotiveInfo(String techniqueId) {
    final technique = state.allTechniques.firstWhere(
      (t) => t.id == techniqueId,
      orElse: () =>
          CalmTechnique.defaults.firstWhere((t) => t.id == techniqueId),
    );

    return TechniqueWithMotiveInfo(
      technique: technique,
      motiveDescription: technique.getMotiveDescription(state.currentMotive),
      motiveBenefits: technique.getMotiveBenefits(state.currentMotive),
      isPrimary: technique.isPrimaryForMotive(state.currentMotive),
      isSecondary: technique.isSecondaryForMotive(state.currentMotive),
      priorityScore: technique.getMotivePriorityScore(state.currentMotive),
    );
  }

  /// Search techniques with motive-aware ranking
  List<CalmTechnique> searchTechniques(String query) {
    final lowercaseQuery = query.toLowerCase();

    final matchingTechniques = state.allTechniques.where((technique) {
      final titleMatch = technique.title.toLowerCase().contains(lowercaseQuery);
      final descriptionMatch = technique.description.toLowerCase().contains(
        lowercaseQuery,
      );
      final motiveDescriptionMatch = technique
          .getMotiveDescription(state.currentMotive)
          .toLowerCase()
          .contains(lowercaseQuery);

      return titleMatch || descriptionMatch || motiveDescriptionMatch;
    }).toList();

    // Sort by motive priority, then by relevance
    matchingTechniques.sort((a, b) {
      final priorityA = a.getMotivePriorityScore(state.currentMotive);
      final priorityB = b.getMotivePriorityScore(state.currentMotive);

      if (priorityA != priorityB) {
        return priorityB.compareTo(priorityA);
      }

      // Secondary sort by title match (exact matches first)
      final titleMatchA = a.title.toLowerCase().contains(lowercaseQuery);
      final titleMatchB = b.title.toLowerCase().contains(lowercaseQuery);

      if (titleMatchA && !titleMatchB) return -1;
      if (!titleMatchA && titleMatchB) return 1;

      return 0;
    });

    return matchingTechniques;
  }

  /// Get technique recommendations based on usage patterns and motive
  List<CalmTechnique> getRecommendedTechniques({int limit = 3}) {
    // For now, return top primary techniques
    // In future, this could incorporate usage analytics
    return state.primaryTechniques.take(limit).toList();
  }

  /// Get techniques by effectiveness for current motive
  List<CalmTechnique> getTechniquesByEffectiveness() {
    // Sort by priority score (proxy for effectiveness)
    final techniques = List<CalmTechnique>.from(state.allTechniques);
    techniques.sort(
      (a, b) => b
          .getMotivePriorityScore(state.currentMotive)
          .compareTo(a.getMotivePriorityScore(state.currentMotive)),
    );
    return techniques;
  }

  /// Force refresh library for current motive
  void refreshLibrary() {
    state = state.copyWith(isLoading: true);
    _updateLibraryForMotive(state.currentMotive);
  }

  @override
  void dispose() {
    _motiveSubscription?.cancel();
    super.dispose();
  }
}

/// State for technique library
class TechniqueLibraryState {
  final String? currentMotive;
  final List<CalmTechnique> allTechniques;
  final Map<TechniqueType, List<CalmTechnique>> categorizedTechniques;
  final List<CalmTechnique> emergencyTechniques;
  final List<CalmTechnique> primaryTechniques;
  final bool isLoading;

  const TechniqueLibraryState({
    this.currentMotive,
    this.allTechniques = const [],
    this.categorizedTechniques = const {},
    this.emergencyTechniques = const [],
    this.primaryTechniques = const [],
    this.isLoading = true,
  });

  TechniqueLibraryState copyWith({
    String? currentMotive,
    List<CalmTechnique>? allTechniques,
    Map<TechniqueType, List<CalmTechnique>>? categorizedTechniques,
    List<CalmTechnique>? emergencyTechniques,
    List<CalmTechnique>? primaryTechniques,
    bool? isLoading,
  }) {
    return TechniqueLibraryState(
      currentMotive: currentMotive ?? this.currentMotive,
      allTechniques: allTechniques ?? this.allTechniques,
      categorizedTechniques:
          categorizedTechniques ?? this.categorizedTechniques,
      emergencyTechniques: emergencyTechniques ?? this.emergencyTechniques,
      primaryTechniques: primaryTechniques ?? this.primaryTechniques,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Technique with motive-specific information
class TechniqueWithMotiveInfo {
  final CalmTechnique technique;
  final String motiveDescription;
  final List<String> motiveBenefits;
  final bool isPrimary;
  final bool isSecondary;
  final int priorityScore;

  const TechniqueWithMotiveInfo({
    required this.technique,
    required this.motiveDescription,
    required this.motiveBenefits,
    required this.isPrimary,
    required this.isSecondary,
    required this.priorityScore,
  });
}

/// Provider for technique library service
final techniqueLibraryProvider =
    StateNotifierProvider<TechniqueLibraryService, TechniqueLibraryState>((
      ref,
    ) {
      final motiveService = ref.watch(motiveDetectionProvider.notifier);
      return TechniqueLibraryService(motiveDetectionService: motiveService);
    });
