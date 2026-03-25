import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'badge_service.dart';
import '../models/badge.dart';
import 'dart:async';
import '../core/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final BadgeService? _badgeService;

  FirestoreService({FirebaseFirestore? firestore, BadgeService? badgeService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _badgeService = badgeService;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create user document
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Get raw user document once (used by feature controllers)
  Future<DocumentSnapshot> getUserOnce(String uid) async {
    try {
      return await _usersCollection.doc(uid).get();
    } catch (e) {
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Update last login with optimized quota usage
  Future<void> updateLastLogin(String uid) async {
    try {
      final now = DateTime.now();

      // Write login metadata directly to avoid an extra read-before-write.

      await _usersCollection.doc(uid).update({
        'lastLogin': Timestamp.fromDate(now),
        // Use server timestamp for more efficient updates
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // For login dates tracking, use a separate optimized method
      await _updateLoginDateOptimized(uid, now);
    } catch (e) {
      throw Exception('Failed to update last login: $e');
    }
  }

  // Optimized login date tracking to reduce reads
  Future<void> _updateLoginDateOptimized(String uid, DateTime now) async {
    try {
      // Create a document ID based on year-month to partition data
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final dayKey = now.day.toString().padLeft(2, '0');

      // Use a subcollection for login tracking to avoid reading main document
      await _usersCollection
          .doc(uid)
          .collection('loginTracking')
          .doc(monthKey)
          .set({
            dayKey: Timestamp.fromDate(now),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      // Don't throw error for login tracking failure
      appLogger.w('Login tracking failed: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Stream of user data
  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Stream of user document
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots();
  }

  // Save Daily Motive
  Future<void> saveDailyMotive(String uid, String motive) async {
    final today = DateTime.now();
    final dateId =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    await _usersCollection.doc(uid).collection('dailyMotives').doc(dateId).set({
      'motive': motive,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get Daily Motive
  Future<String?> getDailyMotive(String uid) async {
    final today = DateTime.now();
    final dateId =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final doc = await _usersCollection
          .doc(uid)
          .collection('dailyMotives')
          .doc(dateId)
          .get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['motive'] as String?;
      }
      return null;
    } on FirebaseException catch (e) {
      // If rules/indexes aren't deployed yet, don't crash the UI.
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  // Save Sleep Data
  Future<void> logSleepData(
    String uid,
    DateTime date,
    Map<String, dynamic> data,
  ) async {
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      await _usersCollection.doc(uid).set({
        'sleepData': {dateKey: data},
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to log sleep data: $e');
    }
  }

  // Get Sleep Data for a specific date
  Future<Map<String, dynamic>?> getSleepData(String uid, DateTime date) async {
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('sleepData')) {
          final sleepMap = data['sleepData'] as Map<String, dynamic>;
          return sleepMap[dateKey] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get sleep data: $e');
    }
  }

  // ── Activity Completion Tracking ─────────────────────────────────────────
  // Called whenever a user FULLY completes an activity (not just opens it).
  // Powers the badge system with fast single-document reads instead of
  // expensive full-collection scans.
  //
  // activityKey values: 'journaling' | 'focus_session' | 'meditation'
  //                     | 'smart_goals' | 'daily_checkin' | 'breathing'
  //
  // Returns a List of newly unlocked badges. Will return empty if none unlocked
  // or if error.
  Future<List<Badge>> logActivityCompletion(String uid, String activityKey) async {
    try {
      await _usersCollection
          .doc(uid)
          .collection('activity_stats')
          .doc(activityKey)
          .set({
            'completionCount': FieldValue.increment(1),
            'lastCompleted': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // After logging the activity, check if they earned any badges!
      final badgeService = _badgeService ?? BadgeService(
        firestore: _firestore,
        firestoreService: this,
      );
      final newBadges = await badgeService.checkAndAwardBadges(uid);
      return newBadges;
    } catch (e) {
      // Silent fail — never block the user's main action for analytics
      return [];
    }
  }

  // Get total completion count for a single activity (used by badge system)
  Future<int> getActivityCompletionCount(String uid, String activityKey) async {
    try {
      final doc = await _usersCollection
          .doc(uid)
          .collection('activity_stats')
          .doc(activityKey)
          .get();
      if (doc.exists) {
        return (doc.data()?['completionCount'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ── Generic Collection Methods ─────────────────────────────────────────
  // Generic methods for working with any Firestore collection

  /// Set a document in any collection
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      throw Exception('Failed to set document: $e');
    }
  }

  /// Get documents from a collection where a field equals a value
  Future<QuerySnapshot> getDocumentsWhere({
    required String collection,
    required String field,
    required dynamic value,
  }) async {
    try {
      return await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();
    } catch (e) {
      throw Exception('Failed to get documents: $e');
    }
  }

  /// Delete a document from any collection
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
}
