class ProgressInsightsService {
  // TODO: Implement Supabase integration

  Future<String> getTrendDirection(String userId) async {
    return 'stable';
  }

  Future<List<String>> getWeeklyHighlights(String userId) async {
    return [];
  }

  Future<Map<String, dynamic>> getBadgeProgress(String userId) async {
    return {};
  }

  Future<List<String>> getUnlockedBadges(String userId) async {
    return [];
  }

  Future<int> getStreakDays(String userId) async {
    return 0;
  }

  Future<List<String>> getMilestones(String userId) async {
    return [];
  }

  Future<List<dynamic>> detectNewBadges(String userId) async {
    return [];
  }

  Future<Map<DateTime, double>> getCompletionHistory(
    String userId, [
    int days = 30,
  ]) async {
    return {};
  }

  Future<Map<String, int>> getActivityBreakdown(
    String userId, [
    int days = 30,
  ]) async {
    return {};
  }
}
