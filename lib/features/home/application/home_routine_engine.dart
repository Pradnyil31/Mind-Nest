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

    final base = count ~/ 3;
    final rem = count % 3;
    final mCount = base + (rem > 0 ? 1 : 0);
    final aCount = base + (rem > 1 ? 1 : 0);
    final eCount = base;

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
      final all = [...morningPool, ...afternoonPool, ...eveningPool]..shuffle(rng);
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

    int wakeMin = wakeTime.hour * 60 + wakeTime.minute;
    int bedMin = bedTime.hour * 60 + bedTime.minute;
    if (bedMin < wakeMin) bedMin += 24 * 60;

    int morningOffset = 0;
    int afternoonOffset = 0;
    int afternoonStart = 12 * 60;
    int eveningStart = 17 * 60;
    if (wakeMin > afternoonStart) afternoonStart = wakeMin + 60;
    if (wakeMin > eveningStart) eveningStart = wakeMin + 180;

    for (final activity in activities) {
      final lower = activity.toLowerCase();
      String timeString;

      if (lower.contains('sunlight')) {
        timeString = minToTime(wakeMin + 15);
      } else if (lower.contains('caffeine') && lower.contains('delay')) {
        timeString = minToTime(wakeMin + 90);
      } else if (lower.contains('caffeine') && (lower.contains('cut') || lower.contains('off'))) {
        if (bedMin - wakeMin >= 12 * 60) {
          timeString = minToTime(wakeMin + 90);
        } else {
          timeString = minToTime(bedMin - 10 * 60);
        }
      } else if (lower.contains('sleep') || lower.contains('bed time')) {
        timeString = _formatTimeOfDay(bedTime);
      } else if (lower.contains('wind down')) {
        timeString = minToTime(bedMin - 60);
      } else {
        final period = RoutineConfig.getTimePeriod(activity);
        if (period == 'Morning') {
          timeString = minToTime(wakeMin + 15 + morningOffset);
          morningOffset += 30;
        } else if (period == 'Afternoon') {
          timeString = minToTime(afternoonStart + afternoonOffset);
          afternoonOffset += 60;
        } else {
          timeString = minToTime(eveningStart + 60);
        }
      }

      schedule[activity] = timeString;
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

  static int _seedFromNow() {
    final now = DateTime.now();
    return now.year + now.month + now.day;
  }
}
