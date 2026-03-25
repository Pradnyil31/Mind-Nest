import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';
import '../models/meditation_session.dart';

class MeditationService {
  final FirebaseFirestore _firestore;

  MeditationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _sessionsCollection => _firestore.collection('meditation_sessions');
  DocumentReference _summaryStatsDoc(String userId) =>
      _firestore.collection('users').doc(userId).collection('meditation_stats').doc('summary');

  /// Save a completed meditation session
  Future<void> saveSession(MeditationSession session) async {
    try {
      await _sessionsCollection.doc(session.id).set(session.toMap());
    } catch (e, stackTrace) {
      appLogger.e('Error saving meditation session', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get recent meditation sessions for a user
  Stream<List<MeditationSession>> getRecentSessions(String userId, {int limit = 10}) {
    return _sessionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MeditationSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Get total session count for a user
  Future<int> getTotalSessionCount(String userId) async {
    try {
      final statsSnapshot = await _summaryStatsDoc(userId).get();
      if (statsSnapshot.exists) {
        final stats = statsSnapshot.data() as Map<String, dynamic>;
        final totalSessions = stats['totalSessions'];
        if (totalSessions is int) return totalSessions;
      }

      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e, stackTrace) {
      appLogger.e('Error getting session count', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Get total meditation minutes for a user
  Future<int> getTotalMinutes(String userId) async {
    try {
      final statsSnapshot = await _summaryStatsDoc(userId).get();
      if (statsSnapshot.exists) {
        final stats = statsSnapshot.data() as Map<String, dynamic>;
        final totalMinutes = stats['totalMinutes'];
        if (totalMinutes is int) return totalMinutes;
      }

      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .get();
      
      int totalMinutes = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalMinutes += (data['durationMinutes'] ?? 0) as int;
      }
      return totalMinutes;
    } catch (e, stackTrace) {
      appLogger.e('Error calculating total minutes', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Check if user has meditated today
  Future<bool> hasMeditatedToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final snapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      appLogger.e('Error checking today\'s meditation', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
