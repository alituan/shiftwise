library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/shared/time_format.dart';

void main() {
  group('time formatting (en-US, Phase 1)', () {
    test('time of day', () {
      expect(formatTimeOfDay(DateTime(2026, 9, 4, 14, 0)), '2:00 PM');
      expect(formatTimeOfDay(DateTime(2026, 9, 4, 9, 5)), '9:05 AM');
      expect(formatTimeOfDay(DateTime(2026, 9, 4, 0, 0)), '12:00 AM');
    });

    test('shift range', () {
      expect(
        formatShiftRange(DateTime(2026, 9, 4, 14, 0), DateTime(2026, 9, 4, 22)),
        '2:00 PM–10:00 PM',
      );
    });

    test('weekday and month-day', () {
      expect(formatWeekdayShort(DateTime(2026, 9, 4)), 'Fri');
      expect(formatMonthDay(DateTime(2026, 9, 4)), 'Sep 4');
    });
  });

  group('formatCountdown', () {
    test('coarse-to-fine', () {
      expect(formatCountdown(const Duration(days: 2, hours: 3)), 'in 2d 3h');
      expect(
        formatCountdown(const Duration(hours: 3, minutes: 12)),
        'in 3h 12m',
      );
      expect(formatCountdown(const Duration(minutes: 12)), 'in 12m');
      expect(formatCountdown(const Duration(hours: 3)), 'in 3h 0m');
    });

    test('now or past', () {
      expect(formatCountdown(Duration.zero), 'now');
      expect(formatCountdown(const Duration(minutes: -1)), 'now');
    });
  });
}
