/// Assembles a Shift from the edit form's picks: combines the chosen date
/// with the two time-of-day picks, treating end <= start as an overnight
/// shift that ends the next day.
library;

import 'package:decimal/decimal.dart';
import 'package:shiftwise/domain/schedule/shift.dart';

Shift composeShift({
  required String id,
  required String jobName,
  required DateTime date,
  required DateTime start,
  required DateTime end,
  required int breakMinutes,
  required Decimal ratePerHour,
}) {
  final startAt = DateTime(
    date.year,
    date.month,
    date.day,
    start.hour,
    start.minute,
  );
  var endAt = DateTime(date.year, date.month, date.day, end.hour, end.minute);
  if (!endAt.isAfter(startAt)) {
    endAt = endAt.add(const Duration(days: 1));
  }
  return Shift.create(
    id: id,
    jobName: jobName,
    start: startAt,
    end: endAt,
    breakMinutes: breakMinutes,
    ratePerHour: ratePerHour,
  );
}
