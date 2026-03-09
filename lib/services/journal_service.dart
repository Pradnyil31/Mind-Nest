import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/journal_entry.dart';

class JournalService {
  final SupabaseClient _client;

  JournalService({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  Future<void> addEntry(JournalEntry entry) async {
    try {
      await _client.from('journal_entries').insert({
        'user_id': entry.userId,
        'title': entry.title,
        'content': entry.content,
        'mood': entry.mood,
        'tags': entry.tags,
        'created_at': entry.timestamp.toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to add journal entry: $e';
    }
  }

  Stream<List<JournalEntry>> getEntriesStream(String userId) {
    return _client
        .from('journal_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) {
          return rows.map((row) => _entryFromRow(row)).toList();
        });
  }

  Future<void> updateEntry(JournalEntry entry) async {
    try {
      await _client
          .from('journal_entries')
          .update({
            'title': entry.title,
            'content': entry.content,
            'mood': entry.mood,
            'tags': entry.tags,
          })
          .eq('id', entry.id);
    } catch (e) {
      throw 'Failed to update journal entry: $e';
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _client.from('journal_entries').delete().eq('id', entryId);
    } catch (e) {
      throw 'Failed to delete journal entry: $e';
    }
  }

  JournalEntry _entryFromRow(Map<String, dynamic> row) {
    return JournalEntry(
      id: row['id'],
      userId: row['user_id'],
      title: row['title'],
      content: row['content'],
      mood: row['mood'] ?? 'Neutral',
      timestamp: DateTime.parse(row['created_at']),
      tags: List<String>.from(row['tags'] ?? []),
    );
  }
}
