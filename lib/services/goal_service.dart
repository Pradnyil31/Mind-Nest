import '../models/smart_goal.dart';

class GoalService {
  // TODO: Implement Supabase integration
  // Services should use FirestoreService for data access

  GoalService();

  Future<void> addGoal(SmartGoal goal) async {
    // Stub
  }

  Future<void> updateGoal(SmartGoal goal) async {
    // Stub
  }

  Future<void> updateProgress(String goalId, double newValue) async {
    // Stub
  }

  Future<void> updateCompletionStatus(String goalId, bool isCompleted) async {
    // Stub
  }

  Future<void> deleteGoal(String goalId) async {
    // Stub
  }

  Stream<List<SmartGoal>> getGoalsStream(String userId) {
    return Stream.value([]);
  }
}
