import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meditation_session.dart';
import '../services/meditation_service.dart';
import '../services/meditation_analytics_service.dart';
import 'auth_provider.dart';

/// Provider for MeditationService instance
final meditationServiceProvider = Provider<MeditationService>((ref) {
  return MeditationService();
});

/// Provider for MeditationAnalyticsService instance
final meditationAnalyticsProvider = Provider<MeditationAnalyticsService>((ref) {
  return MeditationAnalyticsService();
});

/// Stream provider for recent meditation sessions
final recentMeditationSessionsProvider = StreamProvider<List<MeditationSession>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  final meditationService = ref.watch(meditationServiceProvider);
  return meditationService.getRecentSessions(currentUser.uid, limit: 10);
});

/// Provider for total meditation session count
final meditationSessionCountProvider = FutureProvider<int>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return 0;
  }
  
  final meditationService = ref.watch(meditationServiceProvider);
  return await meditationService.getTotalSessionCount(currentUser.uid);
});

/// Provider for total meditation minutes
final totalMeditationMinutesProvider = FutureProvider<int>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return 0;
  }
  
  final meditationService = ref.watch(meditationServiceProvider);
  return await meditationService.getTotalMinutes(currentUser.uid);
});

/// Provider for meditation streak
final meditationStreakProvider = FutureProvider<int>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return 0;
  }
  
  final analyticsService = ref.watch(meditationAnalyticsProvider);
  return await analyticsService.getCurrentStreak(currentUser.uid);
});

/// Provider to check if user has meditated today
final hasMeditatedTodayProvider = FutureProvider<bool>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return false;
  }
  
  final meditationService = ref.watch(meditationServiceProvider);
  return await meditationService.hasMeditatedToday(currentUser.uid);
});
