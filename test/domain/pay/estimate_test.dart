library;

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/domain/pay/estimate.dart';
import 'package:shiftwise/domain/schedule/shift.dart';

Shift _shift({
  required int startHour,
  required int endHour,
  int breakMinutes = 0,
  String rate = '16.50',
}) {
  return Shift.create(
    id: 'a',
    jobName: 'Cafe',
    start: DateTime(2026, 9, 4, startHour),
    end: DateTime(2026, 9, 4, endHour),
    breakMinutes: breakMinutes,
    ratePerHour: Decimal.parse(rate),
  );
}

void main() {
  group('workedMinutes / workedHours', () {
    test('8h shift, no break', () {
      expect(workedMinutes(_shift(startHour: 9, endHour: 17)), 480);
      expect(
        workedHours(_shift(startHour: 9, endHour: 17)),
        Decimal.parse('8'),
      );
    });

    test('7h30 net of 30m break', () {
      final shift = _shift(startHour: 9, endHour: 17, breakMinutes: 30);
      expect(workedMinutes(shift), 450);
      expect(workedHours(shift), Decimal.parse('7.5'));
    });

    test('overnight shift keeps full duration', () {
      final shift = Shift.create(
        id: 'a',
        jobName: 'Hospital',
        start: DateTime(2026, 9, 4, 22, 0),
        end: DateTime(2026, 9, 5, 6, 0),
        breakMinutes: 30,
        ratePerHour: Decimal.parse('20'),
      );
      expect(workedMinutes(shift), 450);
    });
  });

  group('estimatedGrossPay', () {
    test('8h at 15.50 is 124.00', () {
      final pay = estimatedGrossPay(
        _shift(startHour: 9, endHour: 17, rate: '15.50'),
      );
      expect(pay, Decimal.parse('124.00'));
    });

    test('7h30 at 16.50 is 123.75', () {
      final pay = estimatedGrossPay(
        _shift(startHour: 9, endHour: 17, breakMinutes: 30),
      );
      expect(pay, Decimal.parse('123.75'));
    });

    test('zero rate yields zero', () {
      expect(
        estimatedGrossPay(_shift(startHour: 9, endHour: 17, rate: '0')),
        Decimal.zero,
      );
    });
  });

  group('properties', () {
    final shifts = [
      _shift(startHour: 6, endHour: 14, breakMinutes: 30, rate: '15.25'),
      _shift(startHour: 9, endHour: 17, breakMinutes: 0, rate: '16.50'),
      _shift(startHour: 14, endHour: 22, breakMinutes: 45, rate: '18.75'),
      _shift(startHour: 22, endHour: 23, breakMinutes: 0, rate: '22'),
    ];

    test('pay and worked time are never negative', () {
      for (final shift in shifts) {
        expect(workedMinutes(shift), greaterThanOrEqualTo(0));
        expect(estimatedGrossPay(shift) < Decimal.zero, isFalse);
      }
    });

    test('deterministic recomputation', () {
      for (final shift in shifts) {
        final first = estimatedGrossPay(shift);
        final second = estimatedGrossPay(shift);
        expect(first, second);
      }
    });

    test('exposes the rule version for traceability', () {
      expect(payRuleVersion, isNotEmpty);
    });
  });
}
