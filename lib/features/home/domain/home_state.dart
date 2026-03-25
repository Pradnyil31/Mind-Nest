import 'package:flutter/material.dart';
import '../../../services/personalization_service.dart';

/// Immutable view-model for the Home screen.
///
/// This is intentionally small to start with. As we progressively
/// move logic out of `HomeContent`, new fields should be added here
/// instead of being kept as widget-local state.
class HomeState {
  final bool hasLoaded;
  final String displayName;
  final List<String> goals;
  final int streak;
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;
  final bool hasCheckedInToday;
  final int completedSteps;
  final int totalSteps;
  final RecommendedExercise? recommendation;

  const HomeState({
    required this.hasLoaded,
    required this.displayName,
    required this.goals,
    required this.streak,
    required this.wakeTime,
    required this.bedTime,
    required this.hasCheckedInToday,
    required this.completedSteps,
    required this.totalSteps,
    required this.recommendation,
  });

  factory HomeState.initial() => const HomeState(
        hasLoaded: false,
        displayName: 'User',
        goals: <String>[],
        streak: 0,
        wakeTime: TimeOfDay(hour: 7, minute: 0),
        bedTime: TimeOfDay(hour: 22, minute: 0),
        hasCheckedInToday: false,
        completedSteps: 0,
        totalSteps: 0,
        recommendation: null,
      );

  double get progress =>
      totalSteps == 0 ? 0.0 : completedSteps / totalSteps;

  HomeState copyWith({
    bool? hasLoaded,
    String? displayName,
    List<String>? goals,
    int? streak,
    TimeOfDay? wakeTime,
    TimeOfDay? bedTime,
    bool? hasCheckedInToday,
    int? completedSteps,
    int? totalSteps,
    RecommendedExercise? recommendation,
  }) {
    return HomeState(
      hasLoaded: hasLoaded ?? this.hasLoaded,
      displayName: displayName ?? this.displayName,
      goals: goals ?? this.goals,
      streak: streak ?? this.streak,
      wakeTime: wakeTime ?? this.wakeTime,
      bedTime: bedTime ?? this.bedTime,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      completedSteps: completedSteps ?? this.completedSteps,
      totalSteps: totalSteps ?? this.totalSteps,
      recommendation: recommendation ?? this.recommendation,
    );
  }
}
