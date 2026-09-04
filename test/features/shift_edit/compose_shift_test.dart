library;

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/features/shift_edit/compose_shift.dart';

void main() {
  test('combines date with both times', () {
    final shift = composeShift(
      id: 'a',
      jobName: 'Cafe',
      date: DateTime(2026, 9, 4),
      start: DateTime(2000, 1, 1, 14, 0),
      end: DateTime(2000, 1, 1, 22, 0),
      breakMinutes: 0,
      ratePerHour: Decimal.one,
    );
    expect(shift.start, DateTime(2026, 9, 4, 14, 0));
    expect(shift.end, DateTime(2026, 9, 4, 22, 0));
    expect(shift.isOvernight, isFalse);
  });

  test('end at or before start means overnight (next day)', () {
    final shift = composeShift(
      id: 'a',
      jobName: 'Hospital',
      date: DateTime(2026, 9, 5),
      start: DateTime(2000, 1, 1, 22, 0),
      end: DateTime(2000, 1, 1, 6, 0),
      breakMinutes: 0,
      ratePerHour: Decimal.one,
    );
    expect(shift.start, DateTime(2026, 9, 5, 22, 0));
    expect(shift.end, DateTime(2026, 9, 6, 6, 0));
    expect(shift.isOvernight, isTrue);
  });

  test('equal start and end become a full 24h day', () {
    final shift = composeShift(
      id: 'a',
      jobName: 'Cafe',
      date: DateTime(2026, 9, 4),
      start: DateTime(2000, 1, 1, 9, 0),
      end: DateTime(2000, 1, 1, 9, 0),
      breakMinutes: 0,
      ratePerHour: Decimal.one,
    );
    expect(shift.end.difference(shift.start), const Duration(days: 1));
  });

  test('model invariants still apply (oversized break throws)', () {
    expect(
      () => composeShift(
        id: 'a',
        jobName: 'Cafe',
        date: DateTime(2026, 9, 4),
        start: DateTime(2000, 1, 1, 14, 0),
        end: DateTime(2000, 1, 1, 15, 0),
        breakMinutes: 120,
        ratePerHour: Decimal.one,
      ),
      throwsArgumentError,
    );
  });
}
