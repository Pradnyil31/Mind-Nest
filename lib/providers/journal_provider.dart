import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import 'auth_provider.dart';

/// Provider for JournalService instance
final journalServiceProvider = Provider<JournalService>((ref) {
  return JournalService();
});

/// Stream provider for user's journal entries
/// 
/// Automatically streams all journal entries for the current user.
/// Sorted by timestamp in descending order (newest first).
final userJournalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  final journalService = ref.watch(journalServiceProvider);
  return journalService.getEntriesStream(currentUser.uid);
});

/// Provider for recent journal entries (last 7 days)
final recentJournalEntriesProvider = Provider<List<JournalEntry>>((ref) {
  final allEntries = ref.watch(userJournalEntriesProvider);
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  
  return allEntries.when(
    data: (entries) => entries
        .where((entry) => entry.timestamp.isAfter(sevenDaysAgo))
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for journal entry count
final journalEntryCountProvider = Provider<int>((ref) {
  final entries = ref.watch(userJournalEntriesProvider);
  return entries.when(
    data: (entriesList) => entriesList.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider to check if user has journaled today
final hasJournaledTodayProvider = Provider<bool>((ref) {
  final entries = ref.watch(userJournalEntriesProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  return entries.when(
    data: (entriesList) {
      return entriesList.any((entry) => 
        entry.timestamp.isAfter(startOfDay) && 
        entry.timestamp.isBefore(now.add(const Duration(days: 1)))
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
});
