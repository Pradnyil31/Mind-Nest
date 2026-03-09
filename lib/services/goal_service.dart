import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/smart_goal.dart';

class GoalService {
  final SupabaseClient _client;

  GoalService({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  Future<void> addGoal(SmartGoal goal) async {
    try {
      await _client.from('smart_goals').insert({
        'user_id': goal.userId,
        'title': goal.title,
        'description': goal.description,
        'target_value': goal.targetValue,
        'current_value': goal.currentValue,
        'unit': goal.unit,
        'deadline': goal.deadline.toIso8601String(),
        'color_value': goal.colorValue,
        'is_completed': goal.isCompleted,
      });
    } catch (e) {
      throw 'Failed to add goal: $e';
    }
  }

  Future<void> updateGoal(SmartGoal goal) async {
    try {
      await _client
          .from('smart_goals')
          .update({
            'title': goal.title,
            'description': goal.description,
            'target_value': goal.targetValue,
            'current_value': goal.currentValue,
            'unit': goal.unit,
            'deadline': goal.deadline.toIso8601String(),
            'color_value': goal.colorValue,
            'is_completed': goal.isCompleted,
          })
          .eq('id', goal.id);
    } catch (e) {
      throw 'Failed to update goal: $e';
    }
  }

  Future<void> updateProgress(String goalId, double newValue) async {
    try {
      await _client
          .from('smart_goals')
          .update({'current_value': newValue})
          .eq('id', goalId);
    } catch (e) {
      throw 'Failed to update progress: $e';
    }
  }

  Future<void> updateCompletionStatus(String goalId, bool isCompleted) async {
    try {
      await _client
          .from('smart_goals')
          .update({'is_completed': isCompleted})
          .eq('id', goalId);
    } catch (e) {
      throw 'Failed to update completion status: $e';
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _client.from('smart_goals').delete().eq('id', goalId);
    } catch (e) {
      throw 'Failed to delete goal: $e';
    }
  }

  Stream<List<SmartGoal>> getGoalsStream(String userId) {
    return _client
        .from('smart_goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) {
          return rows.map((row) => _goalFromRow(row)).toList();
        });
  }

  SmartGoal _goalFromRow(Map<String, dynamic> row) {
    return SmartGoal(
      id: row['id'],
      userId: row['user_id'],
      title: row['title'],
      description: row['description'] ?? '',
      targetValue: (row['target_value'] ?? 0).toDouble(),
      currentValue: (row['current_value'] ?? 0).toDouble(),
      unit: row['unit'] ?? '',
      deadline: DateTime.parse(row['deadline']),
      colorValue: row['color_value'] ?? 0xFF4CAF50,
      isCompleted: row['is_completed'] ?? false,
    );
  }
}
