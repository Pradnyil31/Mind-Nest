import '../models/routine_completion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineTrackingService {
  final SupabaseClient _client;

  RoutineTrackingService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  String _dateKey(DateTime date) => date.toIso8601String().split('T').first;

  Future<void> logRoutineCompletion(RoutineCompletion completion) async {
    await _client.from('routine_completions').upsert({
      'user_id': completion.userId,
      'completion_date': _dateKey(completion.date),
      'completed_activities': completion.completedActivities,
      'total_activities': completion.totalActivities,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,completion_date');
  }

  Future<List<RoutineCompletion>> getTodayCompletions(String userId) async {
    final today = _dateKey(DateTime.now());
    final row = await _client
        .from('routine_completions')
        .select()
        .eq('user_id', userId)
        .eq('completion_date', today)
        .maybeSingle();

    if (row == null) return [];

    return [
      RoutineCompletion(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        date: DateTime.parse(row['completion_date'] as String),
        completedActivities: List<String>.from(
          row['completed_activities'] ?? <String>[],
        ),
        totalActivities: row['total_activities'] as int? ?? 0,
      ),
    ];
  }

  Future<List<RoutineCompletion>> getWeekCompletions(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final rows = await _client
        .from('routine_completions')
        .select()
        .eq('user_id', userId)
        .gte('completion_date', _dateKey(weekAgo))
        .lte('completion_date', _dateKey(now))
        .order('completion_date', ascending: false);

    return rows
        .map<RoutineCompletion>(
          (row) => RoutineCompletion(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            date: DateTime.parse(row['completion_date'] as String),
            completedActivities: List<String>.from(
              row['completed_activities'] ?? <String>[],
            ),
            totalActivities: row['total_activities'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Stream<List<RoutineCompletion>> streamUserCompletions(String userId) {
    return _client.from('routine_completions').stream(primaryKey: ['id']).map((
      rows,
    ) {
      final filtered =
          rows.where((row) => row['user_id']?.toString() == userId).toList()
            ..sort(
              (a, b) => (b['completion_date']?.toString() ?? '').compareTo(
                a['completion_date']?.toString() ?? '',
              ),
            );

      return filtered
          .map(
            (row) => RoutineCompletion(
              id: row['id'] as String,
              userId: row['user_id'] as String,
              date: DateTime.parse(row['completion_date'] as String),
              completedActivities: List<String>.from(
                row['completed_activities'] ?? <String>[],
              ),
              totalActivities: row['total_activities'] as int? ?? 0,
            ),
          )
          .toList();
    });
  }

  Future<int> getConsecutiveCompletionDays(String userId) async {
    return getCompletionStreak(userId);
  }

  Future<Map<DateTime, bool>> getCompletionCalendar(
    String userId,
    int year,
    int month,
  ) async {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final rows = await _client
        .from('routine_completions')
        .select('completion_date, completed_activities')
        .eq('user_id', userId)
        .gte('completion_date', _dateKey(monthStart))
        .lte('completion_date', _dateKey(monthEnd));

    final result = <DateTime, bool>{};
    for (final row in rows) {
      final date = DateTime.parse(row['completion_date'] as String);
      final completed = List<String>.from(
        row['completed_activities'] ?? <String>[],
      );
      result[DateTime(date.year, date.month, date.day)] = completed.isNotEmpty;
    }
    return result;
  }

  Future<int> getCompletionStreak(String userId) async {
    final rows = await _client
        .from('routine_completions')
        .select('completion_date, completed_activities')
        .eq('user_id', userId)
        .order('completion_date', ascending: false)
        .limit(90);

    if (rows.isEmpty) return 0;

    var streak = 0;
    var cursor = DateTime.now();

    for (final row in rows) {
      final completed = List<String>.from(
        row['completed_activities'] ?? <String>[],
      );
      if (completed.isEmpty) {
        continue;
      }

      final date = DateTime.parse(row['completion_date'] as String);
      final day = DateTime(date.year, date.month, date.day);
      final expected = DateTime(cursor.year, cursor.month, cursor.day);

      if (day == expected) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (day.isBefore(expected)) {
        break;
      }
    }

    return streak;
  }

  Future<void> markActivityComplete(
    String userId,
    dynamic activity,
    dynamic routine,
  ) async {
    final today = _dateKey(DateTime.now());
    final row = await _client
        .from('routine_completions')
        .select('completed_activities, total_activities')
        .eq('user_id', userId)
        .eq('completion_date', today)
        .maybeSingle();

    final completed = List<String>.from(row?['completed_activities'] ?? []);
    final activityName = activity.toString();
    if (!completed.contains(activityName)) {
      completed.add(activityName);
    }

    final totalActivities = routine is List ? routine.length : 0;

    await _client.from('routine_completions').upsert({
      'user_id': userId,
      'completion_date': today,
      'completed_activities': completed,
      'total_activities': totalActivities > 0
          ? totalActivities
          : (row?['total_activities'] as int? ?? 0),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,completion_date');
  }

  Future<void> unmarkActivityComplete(String userId, String activity) async {
    final today = _dateKey(DateTime.now());
    final row = await _client
        .from('routine_completions')
        .select('completed_activities, total_activities')
        .eq('user_id', userId)
        .eq('completion_date', today)
        .maybeSingle();

    if (row == null) return;

    final completed = List<String>.from(row['completed_activities'] ?? []);
    completed.remove(activity);

    await _client.from('routine_completions').upsert({
      'user_id': userId,
      'completion_date': today,
      'completed_activities': completed,
      'total_activities': row['total_activities'] as int? ?? 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,completion_date');
  }

  Stream<List<String>> getTodayCompletedActivitiesStream(String userId) {
    final today = _dateKey(DateTime.now());
    return _client.from('routine_completions').stream(primaryKey: ['id']).map((
      rows,
    ) {
      final row = rows.cast<Map<String, dynamic>?>().firstWhere(
        (r) =>
            r?['user_id']?.toString() == userId &&
            r?['completion_date']?.toString() == today,
        orElse: () => null,
      );
      if (row == null) return <String>[];
      return List<String>.from(row['completed_activities'] ?? []);
    });
  }
}
