import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/daily_checkin.dart';

class CheckInService {
  final SupabaseClient _client;

  CheckInService({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  Future<List<String>> submitCheckIn(DailyCheckIn checkIn) async {
    try {
      final dateStr = checkIn.date.toIso8601String().split('T').first;

      await _client.from('daily_checkins').upsert({
        'user_id': checkIn.userId,
        'date': dateStr,
        'mood': checkIn.mood,
        'sleep_quality': checkIn.sleepQuality,
        'energy_level': checkIn.energyLevel,
        'active_goals_checked': checkIn.activeGoalsChecked,
        'notes': checkIn.notes,
      });

      // Return empty list for now - could analyze and suggest routine additions
      return [];
    } catch (e) {
      throw 'Failed to submit check-in: $e';
    }
  }

  Future<DailyCheckIn?> getTodayCheckIn(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;

      final data = await _client
          .from('daily_checkins')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();

      if (data == null) return null;
      return _checkInFromRow(data);
    } catch (e) {
      throw 'Failed to get today\'s check-in: $e';
    }
  }

  Future<List<DailyCheckIn>> getCheckInsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startStr = startDate.toIso8601String().split('T').first;
      final endStr = endDate.toIso8601String().split('T').first;

      final data = await _client
          .from('daily_checkins')
          .select()
          .eq('user_id', userId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: false);

      return data.map((row) => _checkInFromRow(row)).toList();
    } catch (e) {
      throw 'Failed to get check-ins: $e';
    }
  }

  Future<bool> hasCheckedInToday(String userId) async {
    try {
      final checkIn = await getTodayCheckIn(userId);
      return checkIn != null;
    } catch (e) {
      return false;
    }
  }

  DailyCheckIn _checkInFromRow(Map<String, dynamic> row) {
    return DailyCheckIn(
      id: row['id'],
      userId: row['user_id'],
      date: DateTime.parse(row['date']),
      mood: row['mood'],
      sleepQuality: row['sleep_quality'] ?? 5,
      energyLevel: row['energy_level'] ?? 5,
      activeGoalsChecked: List<String>.from(row['active_goals_checked'] ?? []),
      notes: row['notes'] ?? '',
    );
  }
}
