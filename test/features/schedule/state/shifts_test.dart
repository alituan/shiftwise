library;

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/schedule/state/shifts.dart';

void main() {
  late ProviderContainer container;
  late Shift cafe;
  late Shift hospital;

  setUp(() {
    container = ProviderContainer();
    cafe = Shift.create(
      id: 'cafe',
      jobName: 'Cafe',
      start: DateTime(2026, 9, 4, 9),
      end: DateTime(2026, 9, 4, 17),
      breakMinutes: 30,
      ratePerHour: Decimal.parse('16.50'),
    );
    hospital = Shift.create(
      id: 'hospital',
      jobName: 'Hospital',
      start: DateTime(2026, 9, 5, 22),
      end: DateTime(2026, 9, 6, 6),
      breakMinutes: 0,
      ratePerHour: Decimal.parse('20'),
    );
  });

  tearDown(() => container.dispose());

  test('starts empty (guest mode)', () {
    expect(container.read(shiftsProvider), isEmpty);
  });

  test('add appends', () {
    container.read(shiftsProvider.notifier)
      ..add(cafe)
      ..add(hospital);
    expect(container.read(shiftsProvider), [cafe, hospital]);
  });

  test('update replaces by id and keeps order', () {
    container.read(shiftsProvider.notifier)
      ..add(cafe)
      ..add(hospital)
      ..update(cafe.copyWith(jobName: 'Cafe East'));
    final shifts = container.read(shiftsProvider);
    expect(shifts.first.jobName, 'Cafe East');
    expect(shifts.first.id, 'cafe');
    expect(shifts[1], hospital);
  });

  test('remove filters by id', () {
    container.read(shiftsProvider.notifier)
      ..add(cafe)
      ..add(hospital)
      ..remove('cafe');
    expect(container.read(shiftsProvider), [hospital]);
  });
}
