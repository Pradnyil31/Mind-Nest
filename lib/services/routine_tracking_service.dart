import '../models/routine_completion.dart';

class RoutineTrackingService {
  // TODO: Implement Supabase integration

  Future<void> logRoutineCompletion(RoutineCompletion completion) async {
    // Stub
  }

  Future<List<RoutineCompletion>> getTodayCompletions(String userId) async {
    return [];
  }

  Future<List<RoutineCompletion>> getWeekCompletions(String userId) async {
    return [];
  }

  Stream<List<RoutineCompletion>> streamUserCompletions(String userId) {
    return Stream.value([]);
  }

  Future<int> getConsecutiveCompletionDays(String userId) async {
    return 0;
  }

  Future<Map<DateTime, bool>> getCompletionCalendar(
    String userId,
    int year,
    int month,
  ) async {
    return {};
  }

  Future<int> getCompletionStreak(String userId) async {
    return 0;
  }

  Future<void> markActivityComplete(
    String userId,
    dynamic activity,
    dynamic routine,
  ) async {
    // Stub - takes userId, activity object, routine object
  }

  Future<void> unmarkActivityComplete(
    String routineId,
    String activityId,
  ) async {
    // Stub
  }

  Stream<List<String>> getTodayCompletedActivitiesStream(String userId) {
    return Stream.value([]);
  }
}
