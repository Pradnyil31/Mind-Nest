import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/smart_goal.dart';
import 'firestore_service.dart';

class GoalService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  GoalService({FirebaseFirestore? firestore, FirestoreService? firestoreService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService(firestore: firestore ?? FirebaseFirestore.instance);

  CollectionReference get _goalsCollection => _firestore.collection('smart_goals');

  Future<void> addGoal(SmartGoal goal) async {
    try {
      DocumentReference docRef = _goalsCollection.doc();
      final goalWithId = goal.copyWith(id: docRef.id);
      await docRef.set(goalWithId.toMap());
    } catch (e) {
      throw Exception('Failed to add goal: $e');
    }
  }

  Future<void> updateGoal(SmartGoal goal) async {
    try {
      await _goalsCollection.doc(goal.id).update(goal.toMap());
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  Future<void> updateProgress(String goalId, double newValue) async {
    try {
      final docRef = _goalsCollection.doc(goalId);
      final doc = await docRef.get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final targetValue = (data['targetValue'] as num?)?.toDouble() ?? 0.0;
        final wasCompleted = data['isCompleted'] as bool? ?? false;
        
        final isNowCompleted = newValue >= targetValue;

        await docRef.update({
          'currentValue': newValue,
          'isCompleted': isNowCompleted,
        });

        if (isNowCompleted && !wasCompleted) {
          final userId = data['userId'] as String?;
          if (userId != null) {
            _firestoreService.logActivityCompletion(userId, 'smart_goals');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }
  
  // userId is required so we can log completion without an extra read
  Future<void> updateCompletionStatus(String goalId, bool isCompleted, {String? userId}) async {
    try {
      await _goalsCollection.doc(goalId).update({
        'isCompleted': isCompleted,
      });

      // Log completion for badge system only when goal is marked done
      if (isCompleted && userId != null) {
        _firestoreService.logActivityCompletion(userId, 'smart_goals');
      }
    } catch (e) {
      throw Exception('Failed to update completion status: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _goalsCollection.doc(goalId).delete();
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  Stream<List<SmartGoal>> getGoalsStream(String userId) {
    return _goalsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SmartGoal.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
