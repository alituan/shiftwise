library;

import 'package:decimal/decimal.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/schedule/state/shifts.dart';

/// Fixed clock: Friday 2026-09-04 11:00 local.
final DateTime testNow = DateTime(2026, 9, 4, 11, 0);

Shift cafeShift() => Shift.create(
  id: 'cafe',
  jobName: 'Cafe',
  start: DateTime(2026, 9, 4, 14, 0),
  end: DateTime(2026, 9, 4, 22, 0),
  breakMinutes: 30,
  ratePerHour: Decimal.parse('16.50'),
);

Shift hospitalShift() => Shift.create(
  id: 'hospital',
  jobName: 'Hospital',
  start: DateTime(2026, 9, 5, 22, 0),
  end: DateTime(2026, 9, 6, 6, 0),
  breakMinutes: 0,
  ratePerHour: Decimal.parse('20'),
);

/// Seeded notifier for overrides in screen tests and goldens.
class SeededShifts extends Shifts {
  SeededShifts(this.seeds);

  final List<Shift> seeds;

  @override
  List<Shift> build() => seeds;
}
