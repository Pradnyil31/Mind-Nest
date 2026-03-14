import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_providers.dart';
import '../domain/home_state.dart';

/// Central state controller for the Home screen.
///
/// Step 1 of the architecture refactor:
/// - Start by only reading a minimal set of data (name, goals, streak, wake/bed times).
/// - Keep existing `HomeContent` logic as-is.
/// - Later, we will progressively move logic from the widget into this controller.
class HomeController extends StateNotifier<HomeState> {
  HomeController(this._ref) : super(HomeState.initial());

  final Ref _ref;

  Future<void> loadInitial(String uid) async {
    // Guard: avoid duplicate work if already loaded once.
    if (!state.isLoading) return;

    try {
      final firestore = _ref.read(firestoreServiceProvider);
      final routineService = _ref.read(routineServiceProvider);

      final userDoc = await firestore.getUserOnce(uid);
      String displayName = 'User';
      List<String> goals = <String>[];
      TimeOfDay wakeTime = state.wakeTime;
      TimeOfDay bedTime = state.bedTime;

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        displayName = data['displayName'] ?? displayName;
        goals = List<String>.from(data['primaryGoals'] ?? const <String>[]);

        if (data['routine'] is Map<String, dynamic>) {
          final routine = data['routine'] as Map<String, dynamic>;
          if (routine['wakeUpTime'] is String) {
            wakeTime = _parseTime(routine['wakeUpTime'] as String);
          }
          if (routine['bedTime'] is String) {
            bedTime = _parseTime(routine['bedTime'] as String);
          }
        }
      }

      final streak = await routineService.getCompletionStreak(uid);

      state = state.copyWith(
        isLoading: false,
        displayName: displayName,
        goals: goals,
        streak: streak,
        wakeTime: wakeTime,
        bedTime: bedTime,
      );
    } catch (_) {
      // Keep failure silent for now; we can add explicit error handling later.
      state = state.copyWith(isLoading: false);
    }
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      if (parts[1] == 'PM' && hour != 12) hour += 12;
      if (parts[1] == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }
}

/// Provider that exposes the `HomeController` for the Home screen.
final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController(ref);
});

