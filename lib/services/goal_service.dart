import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/smart_goal.dart';

class GoalService {
  final FirebaseFirestore _firestore;

  GoalService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _goalsCollection => _firestore.collection('smart_goals');

  Future<void> addGoal(SmartGoal goal) async {
    try {
      DocumentReference docRef = _goalsCollection.doc();
      final goalWithId = goal.copyWith(id: docRef.id);
      await docRef.set(goalWithId.toMap());
    } catch (e) {
      throw 'Failed to add goal: $e';
    }
  }

  Future<void> updateGoal(SmartGoal goal) async {
    try {
      await _goalsCollection.doc(goal.id).update(goal.toMap());
    } catch (e) {
      throw 'Failed to update goal: $e';
    }
  }

  Future<void> updateProgress(String goalId, double newValue) async {
    try {
      await _goalsCollection.doc(goalId).update({
        'currentValue': newValue,
      });
    } catch (e) {
      throw 'Failed to update progress: $e';
    }
  }
  
  Future<void> updateCompletionStatus(String goalId, bool isCompleted) async {
    try {
      await _goalsCollection.doc(goalId).update({
        'isCompleted': isCompleted,
      });
    } catch (e) {
      throw 'Failed to update completion status: $e';
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _goalsCollection.doc(goalId).delete();
    } catch (e) {
      throw 'Failed to delete goal: $e';
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
