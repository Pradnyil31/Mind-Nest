import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';
import '../models/daily_checkin.dart';
import 'firestore_service.dart';
import '../config/routine_config.dart';

class CheckInService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  CheckInService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firestoreService =
           firestoreService ??
           FirestoreService(firestore: firestore ?? FirebaseFirestore.instance);

  CollectionReference get _checkInsCollection =>
      _firestore.collection('daily_checkins');
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

      // Log completion for badge system — only fires on actual check-in submission
      await _firestoreService.logActivityCompletion(
        checkIn.userId,
        'daily_checkin',
      );

      // Trigger adaptive routine logic and return changes
      return await _applyAdaptiveRoutine(checkIn);
    } catch (e) {
      throw Exception('Failed to submit check-in: $e');
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

          // Extract user's wake/bed times for optimal scheduling
          int wakeH = 7, wakeM = 0, bedH = 22, bedM = 0;
          if (data.containsKey('routine')) {
            final r = data['routine'] as Map<String, dynamic>?;
            if (r != null) {
              _parseTimeStr(r['wakeUpTime']?.toString(), (h, m) { wakeH = h; wakeM = m; });
              _parseTimeStr(r['bedTime']?.toString(),   (h, m) { bedH  = h; bedM  = m; });
            }
          }

          bool changed = false;
          Map<String, dynamic> tempSchedule = {};
          if (data.containsKey('temporarySchedule')) {
            final rawTemp = Map<String, dynamic>.from(data['temporarySchedule']);
            tempSchedule = rawTemp.map((k, v) => MapEntry(k, v?.toString() ?? '8:00 AM'));
          }
          Map<String, dynamic> routineSchedule = {};
          if (data.containsKey('routineSchedule')) {
            final rawRoutine = Map<String, dynamic>.from(data['routineSchedule']);
            routineSchedule = rawRoutine.map((k, v) => MapEntry(k, v?.toString() ?? '8:00 AM'));
          }

          // Sync existing activities to schedule with OPTIMAL times
          for (var activity in currentRoutine) {
            if (!routineSchedule.containsKey(activity)) {
              final timeSlot = RoutineConfig.getOptimalTimeSlot(
                activity, wakeHour: wakeH, wakeMinute: wakeM, bedHour: bedH, bedMinute: bedM,
              );
              routineSchedule[activity] = timeSlot;
              tempSchedule[activity] = timeSlot;
              changed = true;
            }
          }

          // Inject AI-suggested adaptations at their OPTIMAL time
          for (var activity in adaptations) {
            if (!currentRoutine.contains(activity)) {
              currentRoutine.add(activity);
              addedActivities.add(activity);
              final timeSlot = RoutineConfig.getOptimalTimeSlot(
                activity, wakeHour: wakeH, wakeMinute: wakeM, bedHour: bedH, bedMinute: bedM,
              );
              tempSchedule[activity] = timeSlot;
              routineSchedule[activity] = timeSlot;
              changed = true;
            }
          }

          if (changed) {
            await _usersCollection.doc(checkIn.userId).update({
              'routineActivities': currentRoutine,
              'temporarySchedule': tempSchedule,
              'routineSchedule': routineSchedule,
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

  // Get today's check-in data to display in Insights/Card
  Future<Map<String, dynamic>?> getTodayCheckIn(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = await _checkInsCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data() as Map<String, dynamic>;
    }
    return null;
  }

  /// Parses a time string like "7:30 AM" or "10:00 PM" and calls [onParsed]
  /// with the resulting (hour24, minute) pair. Silent no-op on parse failure.
  void _parseTimeStr(String? timeStr, void Function(int h, int m) onParsed) {
    if (timeStr == null || timeStr.isEmpty) return;
    try {
      final parts = timeStr.trim().split(RegExp(r'[:\s]+'));
      if (parts.length < 2) return;
      int h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final isPM = timeStr.toUpperCase().contains('PM');
      if (isPM && h != 12) h += 12;
      if (!isPM && h == 12) h = 0;
      onParsed(h, m);
    } catch (_) {}
  }
}
