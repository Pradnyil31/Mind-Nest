import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';
import '../models/daily_checkin.dart';

class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _checkInsCollection => _firestore.collection('daily_checkins');
  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<List<String>> submitCheckIn(DailyCheckIn checkIn) async {
    try {
      DocumentReference docRef = _checkInsCollection.doc();
      final checkInWithId = DailyCheckIn(
        id: docRef.id,
        userId: checkIn.userId,
        date: checkIn.date,
        mood: checkIn.mood,
        sleepQuality: checkIn.sleepQuality,
        energyLevel: checkIn.energyLevel,
        activeGoalsChecked: checkIn.activeGoalsChecked,
        notes: checkIn.notes,
      );
      
      await docRef.set(checkInWithId.toMap());
      
      // Trigger adaptive routine logic and return changes
      return await _applyAdaptiveRoutine(checkIn);
      
    } catch (e) {
      throw 'Failed to submit check-in: $e';
    }
  }

  Future<List<String>> _applyAdaptiveRoutine(DailyCheckIn checkIn) async {
    List<String> addedActivities = [];
    try {
      List<String> adaptations = [];
      
      // 1. Low Energy -> Power Nap
      if (checkIn.energyLevel < 4) {
        adaptations.add('Power Nap');
      }
      
      // 2. High Energy -> Deep Work
      if (checkIn.energyLevel > 8) {
        adaptations.add('Deep Work');
      }

      // 3. Poor Sleep -> Early Bedtime
      if (checkIn.sleepQuality < 5) {
        adaptations.add('Early Bedtime');
      }

      // 4. Stress/Anxiety -> Meditation
      if (['Anxious', 'Stress', 'Tired'].contains(checkIn.mood)) {
        adaptations.add('Meditation');
      }

      if (adaptations.isNotEmpty) {
        final userDoc = await _usersCollection.doc(checkIn.userId).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          List<String> currentRoutine = [];
          if (data.containsKey('routineActivities')) {
            currentRoutine = List<String>.from(data['routineActivities']);
          } else {
             currentRoutine = ['Morning Sunlight', 'Delay Caffeine', 'Dim Lights'];
          }

          bool changed = false;
          for (var activity in adaptations) {
            if (!currentRoutine.contains(activity)) {
              currentRoutine.add(activity);
              addedActivities.add(activity);
              changed = true;
            }
          }

          if (changed) {
            await _usersCollection.doc(checkIn.userId).update({
              'routineActivities': currentRoutine
            });
          }
        }
      }
      return addedActivities;
    } catch (e, stackTrace) {
      appLogger.e('Error adapting routine', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Check if user has checked in today
  Future<bool> hasCheckedInToday(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = await _checkInsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    return query.docs.isNotEmpty;
  }
}
