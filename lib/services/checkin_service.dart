import '../models/daily_checkin.dart';

class CheckInService {
  // TODO: Implement Supabase integration
  // Services should use FirestoreService for data access

  Future<List<String>> submitCheckIn(DailyCheckIn checkIn) async {
    // Stub - returns empty list
    return [];
  }

  Future<DailyCheckIn?> getTodayCheckIn(String userId) async {
    // Stub
    return null;
  }

  Future<List<DailyCheckIn>> getCheckInsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Stub
    return [];
  }

  Future<bool> hasCheckedInToday(String userId) async {
    // Stub
    return false;
  }
}
