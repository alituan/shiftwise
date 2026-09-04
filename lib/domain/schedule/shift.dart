/// Manual shift model — Phase 1 guest mode.
///
/// In-memory only by design: no local persistence layer (Firestore's offline
/// cache becomes the store in Phase 2 — AGENTS.md local-persistence rule).
library;

import 'package:meta/meta.dart';

import 'package:decimal/decimal.dart';

@immutable
class Shift {
  const Shift._({
    required this.id,
    required this.jobName,
    required this.start,
    required this.end,
    required this.breakMinutes,
    required this.ratePerHour,
  });

  /// Validated factory — the interval invariant is enforced at the model
  /// boundary so no invalid Shift can exist downstream.
  factory Shift.create({
    required String id,
    required String jobName,
    required DateTime start,
    required DateTime end,
    required int breakMinutes,
    required Decimal ratePerHour,
  }) {
    if (jobName.trim().isEmpty) {
      throw ArgumentError.value(jobName, 'jobName', 'must not be empty');
    }
    if (!end.isAfter(start)) {
      throw ArgumentError.value(end, 'end', 'must be after start');
    }
    if (breakMinutes < 0) {
      throw ArgumentError.value(breakMinutes, 'breakMinutes', 'must be >= 0');
    }
    if (breakMinutes * 60 > end.difference(start).inSeconds) {
      throw ArgumentError.value(
        breakMinutes,
        'breakMinutes',
        'unpaid break cannot exceed the shift length',
      );
    }
    if (ratePerHour < Decimal.zero) {
      throw ArgumentError.value(ratePerHour, 'ratePerHour', 'must be >= 0');
    }
    return Shift._(
      id: id,
      jobName: jobName.trim(),
      start: start,
      end: end,
      breakMinutes: breakMinutes,
      ratePerHour: ratePerHour,
    );
  }

  final String id;
  final String jobName;

  /// Local wall-clock start; guest mode has no timezone handling yet.
  final DateTime start;
  final DateTime end;

  /// Unpaid break minutes inside the shift.
  final int breakMinutes;
  final Decimal ratePerHour;

  bool get isOvernight =>
      start.year != end.year ||
      start.month != end.month ||
      start.day != end.day;

  /// True when the shift starts on the given calendar day. Overnight shifts
  /// are grouped under their start day.
  bool startsOn(DateTime day) =>
      start.year == day.year &&
      start.month == day.month &&
      start.day == day.day;

  Shift copyWith({
    String? id,
    String? jobName,
    DateTime? start,
    DateTime? end,
    int? breakMinutes,
    Decimal? ratePerHour,
  }) => Shift.create(
    id: id ?? this.id,
    jobName: jobName ?? this.jobName,
    start: start ?? this.start,
    end: end ?? this.end,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    ratePerHour: ratePerHour ?? this.ratePerHour,
  );

  @override
  bool operator ==(Object other) => other is Shift && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
