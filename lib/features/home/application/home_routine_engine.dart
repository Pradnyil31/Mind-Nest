import 'dart:math';

import 'package:flutter/material.dart';
import '../../../config/routine_config.dart';

class HomeRoutineEngine {
  static List<String> generateBalancedRoutine(List<String> pool, int count) {
    final rng = Random(_seedFromNow());

    final morningPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Morning')
        .toList();
    final afternoonPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Afternoon')
        .toList();
    final eveningPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Evening')
        .toList();

    if (morningPool.length < 4) {
      morningPool.addAll(RoutineConfig.getActivitiesForPeriod('Morning'));
    }
    if (afternoonPool.length < 4) {
      afternoonPool.addAll(RoutineConfig.getActivitiesForPeriod('Afternoon'));
    }
    if (eveningPool.length < 4) {
      eveningPool.addAll(RoutineConfig.getActivitiesForPeriod('Evening'));
    }

    morningPool.shuffle(rng);
    afternoonPool.shuffle(rng);
    eveningPool.shuffle(rng);

    // Equal distribution: divide activities equally across three periods
    final base = count ~/ 3;
    final rem = count % 3;

    // Distribute remainder evenly: first period gets +1, then second, then third
    final mCount = base + (rem >= 1 ? 1 : 0);
    final aCount = base + (rem >= 2 ? 1 : 0);
    final eCount = base + (rem >= 3 ? 1 : 0);

    final result = <String>{};

    void pickFrom(List<String> src, int needed) {
      int taken = 0;
      for (final a in src) {
        if (taken >= needed) break;
        if (result.add(a)) taken++;
      }
    }

    pickFrom(morningPool, mCount);
    pickFrom(afternoonPool, aCount);
    pickFrom(eveningPool, eCount);

    if (result.length < count) {
      final all = [...morningPool, ...afternoonPool, ...eveningPool]
        ..shuffle(rng);
      for (final a in all) {
        if (result.length >= count) break;
        result.add(a);
      }
    }

    return result.take(count).toList();
  }

  static Map<String, String> calculateDynamicSchedule(
    List<String> activities,
    TimeOfDay wakeTime,
    TimeOfDay bedTime,
  ) {
    final schedule = <String, String>{};
    for (final activity in activities) {
      // Period is derived from RoutineConfig so the daily-generated list
      // always respects the canonical period for each activity.
      schedule[activity] = RoutineConfig.getOptimalTimeSlot(
        activity,
        wakeHour   : wakeTime.hour,
        wakeMinute : wakeTime.minute,
        bedHour    : bedTime.hour,
        bedMinute  : bedTime.minute,
      );
    }
    return schedule;
  }

  static String minToTime(int totalMinutes) {
    totalMinutes = totalMinutes % (24 * 60);
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  static List<String> generateDailyFromBase(
    List<String> baseRoutine,
    List<String> pool,
    int targetCount,
  ) {
    final rng = Random(_seedFromNow());

    // Calculate exact distribution across periods
    final basePerPeriod = targetCount ~/ 3;
    final remainder = targetCount % 3;

    // Distribute remainder: first 'remainder' periods get +1
    final targetMorning = basePerPeriod + (remainder > 0 ? 1 : 0);
    final targetAfternoon = basePerPeriod + (remainder > 1 ? 1 : 0);
    final targetEvening = basePerPeriod;

    // Group pool by time period
    final morningPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Morning')
        .toList();
    final afternoonPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Afternoon')
        .toList();
    final eveningPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Evening')
        .toList();

    morningPool.shuffle(rng);
    afternoonPool.shuffle(rng);
    eveningPool.shuffle(rng);

    final result = <String>[];
    final added = <String>{};

    // Add base routine activities first, respecting period targets
    for (final activity in baseRoutine) {
      if (activity.trim().isEmpty || added.contains(activity)) continue;

      final period = RoutineConfig.getTimePeriod(activity);
      int currentInPeriod = result
          .where((a) => RoutineConfig.getTimePeriod(a) == period)
          .length;

      // Only add if we haven't hit the target for this period
      int targetForPeriod = period == 'Morning'
          ? targetMorning
          : period == 'Afternoon'
          ? targetAfternoon
          : targetEvening;

      if (currentInPeriod < targetForPeriod) {
        result.add(activity);
        added.add(activity);
      }
    }

    // Fill each period to exact target from pool
    void fillPeriod(List<String> periodPool, int target) {
      int current = result
          .where(
            (a) =>
                periodPool.isEmpty ||
                RoutineConfig.getTimePeriod(a) ==
                    (periodPool == morningPool
                        ? 'Morning'
                        : periodPool == afternoonPool
                        ? 'Afternoon'
                        : 'Evening'),
          )
          .length;

      for (final activity in periodPool) {
        if (result.length >= targetCount) break;
        if (current >= target) break;
        if (added.add(activity)) {
          result.add(activity);
          current++;
        }
      }
    }

    fillPeriod(morningPool, targetMorning);
    fillPeriod(afternoonPool, targetAfternoon);
    fillPeriod(eveningPool, targetEvening);

    // If still under target, fill remaining from all pools
    if (result.length < targetCount) {
      final allRemaining = [...morningPool, ...afternoonPool, ...eveningPool]
        ..shuffle(rng);
      for (final activity in allRemaining) {
        if (result.length >= targetCount) break;
        if (added.add(activity)) {
          result.add(activity);
        }
      }
    }

    return result;
  }

  static int _seedFromNow() {
    final now = DateTime.now();
    return now.year + now.month + now.day;
  }
}
