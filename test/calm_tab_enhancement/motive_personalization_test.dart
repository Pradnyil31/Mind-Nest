import 'package:flutter_test/flutter_test.dart';
import 'package:fy_project/config/motive_config.dart';

void main() {
  group('MotiveConfig personalization', () {
    test('generateRoutine applies commitment limits', () {
      final routine = MotiveConfig.generateRoutine(
        motive: 'Sleep',
        commitment: '5 minutes',
      );

      expect(routine.length, lessThanOrEqualTo(3));
      expect(routine, isNotEmpty);
    });

    test('getActivitiesForSupportAreas maps selected areas to activities', () {
      final activities = MotiveConfig.getActivitiesForSupportAreas(
        'Sleep',
        const ['Racing thoughts', 'Stress at night'],
      );

      expect(activities, contains('Brain dump journaling'));
      expect(activities, contains('Progressive muscle relaxation'));
    });

    test('getInsightMessage injects count placeholders', () {
      final message = MotiveConfig.getInsightMessage(
        'Focus',
        'streak',
        count: 7,
      );

      expect(message, contains('7'));
      expect(message.toLowerCase(), contains('day'));
    });
  });
}
