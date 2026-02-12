import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/smart_goal.dart';
import '../services/goal_service.dart';
import 'auth_provider.dart';

/// Provider for GoalService instance
final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService();
});

/// Stream provider for user's smart goals
/// 
/// Automatically streams all goals for the current user.
/// Returns empty list when user is not signed in.
final userGoalsProvider = StreamProvider<List<SmartGoal>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  final goalService = ref.watch(goalServiceProvider);
  return goalService.getGoalsStream(currentUser.uid);
});

/// Provider for active (not completed) goals
final activeGoalsProvider = Provider<List<SmartGoal>>((ref) {
  final  goals = ref.watch(userGoalsProvider);
  return goals.when(
    data: (goalsList) => goalsList.where((goal) => !goal.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for completed goals
final completedGoalsProvider = Provider<List<SmartGoal>>((ref) {
  final goals = ref.watch(userGoalsProvider);
  return goals.when(
    data: (goalsList) => goalsList.where((goal) => goal.isCompleted).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for goal statistics
final goalStatsProvider = Provider<Map<String, int>>((ref) {
  final goals = ref.watch(userGoalsProvider);
  return goals.when(
    data: (goalsList) {
      final total = goalsList.length;
      final completed = goalsList.where((goal) => goal.isCompleted).length;
      final active = total - completed;
      
      return {
        'total': total,
        'active': active,
        'completed': completed,
        'completionRate': total > 0 ? ((completed / total) * 100).round() : 0,
      };
    },
    loading: () => {'total': 0, 'active': 0, 'completed': 0, 'completionRate': 0},
    error: (_, __) => {'total': 0, 'active': 0, 'completed': 0, 'completionRate': 0},
  );
});
