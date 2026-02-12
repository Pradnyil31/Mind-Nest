import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';
import '../models/focus_session.dart';

class FocusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _sessionsCollection => _firestore.collection('focus_sessions');

  Future<void> saveSession(FocusSession session) async {
    try {
      await _sessionsCollection.doc(session.id).set(session.toMap());
    } catch (e, stackTrace) {
      appLogger.e('Error saving focus session', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<FocusSession>> getRecentSessions(String userId) {
    return _sessionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FocusSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
