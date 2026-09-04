/// Wall-clock display formatting for shift times. Phase 1 uses fixed en-US
/// formatting; locale/timezone settings arrive with the Settings screens.
library;

import 'package:intl/intl.dart';

String formatTimeOfDay(DateTime t) => DateFormat('h:mm a').format(t);

String formatWeekdayShort(DateTime t) => DateFormat('EEE').format(t);

String formatMonthDay(DateTime t) => DateFormat('MMM d').format(t);

String formatShiftRange(DateTime start, DateTime end) =>
    '${formatTimeOfDay(start)}–${formatTimeOfDay(end)}';

/// "in 3h 12m" style countdown, coarse-to-fine, never negative.
String formatCountdown(Duration remaining) {
  if (remaining.isNegative || remaining == Duration.zero) return 'now';
  final days = remaining.inDays;
  final hours = remaining.inHours % 24;
  final minutes = remaining.inMinutes % 60;
  if (days > 0) return 'in ${days}d ${hours}h';
  if (hours > 0) return 'in ${hours}h ${minutes}m';
  return 'in ${minutes}m';
}
