import 'package:flutter/material.dart';

/// Immutable view-model for the Home screen.
///
/// This is intentionally small to start with. As we progressively
/// move logic out of `HomeContent`, new fields should be added here
/// instead of being kept as widget-local state.
class HomeState {
  final bool isLoading;
  final String displayName;
  final List<String> goals;
  final int streak;
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;

  const HomeState({
    required this.isLoading,
    required this.displayName,
    required this.goals,
    required this.streak,
    required this.wakeTime,
    required this.bedTime,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: true,
        displayName: 'User',
        goals: <String>[],
        streak: 0,
        wakeTime: TimeOfDay(hour: 7, minute: 0),
        bedTime: TimeOfDay(hour: 22, minute: 0),
      );

  HomeState copyWith({
    bool? isLoading,
    String? displayName,
    List<String>? goals,
    int? streak,
    TimeOfDay? wakeTime,
    TimeOfDay? bedTime,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      displayName: displayName ?? this.displayName,
      goals: goals ?? this.goals,
      streak: streak ?? this.streak,
      wakeTime: wakeTime ?? this.wakeTime,
      bedTime: bedTime ?? this.bedTime,
    );
  }
}
