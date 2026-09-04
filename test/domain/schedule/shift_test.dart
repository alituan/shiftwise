library;

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/domain/schedule/shift.dart';

DateTime _at(int y, int m, int d, int h, int min) => DateTime(y, m, d, h, min);

void main() {
  group('Shift.create invariants', () {
    test('accepts a normal day shift', () {
      final shift = Shift.create(
        id: 'a',
        jobName: 'Cafe',
        start: _at(2026, 9, 4, 9, 0),
        end: _at(2026, 9, 4, 17, 0),
        breakMinutes: 30,
        ratePerHour: Decimal.parse('16.50'),
      );
      expect(shift.jobName, 'Cafe');
      expect(shift.isOvernight, isFalse);
    });

    test('accepts an overnight shift', () {
      final shift = Shift.create(
        id: 'a',
        jobName: 'Hospital',
        start: _at(2026, 9, 4, 22, 0),
        end: _at(2026, 9, 5, 6, 0),
        breakMinutes: 0,
        ratePerHour: Decimal.parse('20'),
      );
      expect(shift.isOvernight, isTrue);
      expect(shift.startsOn(_at(2026, 9, 4, 0, 0)), isTrue);
      expect(shift.startsOn(_at(2026, 9, 5, 0, 0)), isFalse);
    });

    test('rejects end at or before start', () {
      for (final end in [_at(2026, 9, 4, 8, 0), _at(2026, 9, 4, 9, 0)]) {
        expect(
          () => Shift.create(
            id: 'a',
            jobName: 'Cafe',
            start: _at(2026, 9, 4, 9, 0),
            end: end,
            breakMinutes: 0,
            ratePerHour: Decimal.one,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects negative or oversized break', () {
      expect(
        () => Shift.create(
          id: 'a',
          jobName: 'Cafe',
          start: _at(2026, 9, 4, 9, 0),
          end: _at(2026, 9, 4, 17, 0),
          breakMinutes: -1,
          ratePerHour: Decimal.one,
        ),
        throwsArgumentError,
      );
      expect(
        () => Shift.create(
          id: 'a',
          jobName: 'Cafe',
          start: _at(2026, 9, 4, 9, 0),
          end: _at(2026, 9, 4, 17, 0),
          breakMinutes: 481,
          ratePerHour: Decimal.one,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative rate and empty job name', () {
      expect(
        () => Shift.create(
          id: 'a',
          jobName: 'Cafe',
          start: _at(2026, 9, 4, 9, 0),
          end: _at(2026, 9, 4, 17, 0),
          breakMinutes: 0,
          ratePerHour: Decimal.parse('-1'),
        ),
        throwsArgumentError,
      );
      expect(
        () => Shift.create(
          id: 'a',
          jobName: '  ',
          start: _at(2026, 9, 4, 9, 0),
          end: _at(2026, 9, 4, 17, 0),
          breakMinutes: 0,
          ratePerHour: Decimal.one,
        ),
        throwsArgumentError,
      );
    });

    test('trims the job name and keeps identity on id', () {
      final shift = Shift.create(
        id: 'a',
        jobName: '  Cafe  ',
        start: _at(2026, 9, 4, 9, 0),
        end: _at(2026, 9, 4, 17, 0),
        breakMinutes: 0,
        ratePerHour: Decimal.one,
      );
      expect(shift.jobName, 'Cafe');
      expect(shift, shift.copyWith(jobName: 'Cafe'));
    });
  });
}
