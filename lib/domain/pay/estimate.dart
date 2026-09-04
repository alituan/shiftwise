/// Phase-1 basic pay estimate: hours × rate. Differentials and boundary
/// rules are the Phase 4 pay engine — nothing here should imply more.
library;

import 'package:decimal/decimal.dart';
import 'package:shiftwise/domain/schedule/shift.dart';

/// Version of the calculation rules used for this estimate — surfaced with
/// every pay figure for traceability (docs/design/screens.md, Pay).
const String payRuleVersion = 'phase1-manual-v1';

/// Worked minutes after unpaid break. Never negative (model invariant).
int workedMinutes(Shift shift) =>
    shift.end.difference(shift.start).inMinutes - shift.breakMinutes;

/// Division by 60 can be non-terminating (e.g. 1 minute): truncate far below
/// cent precision. Exact rounding rules are the Phase 4 pay engine's job.
const int _divisionScale = 9;

Decimal workedHours(Shift shift) =>
    (Decimal.fromInt(workedMinutes(shift)) / Decimal.fromInt(60)).toDecimal(
      scaleOnInfinitePrecision: _divisionScale,
    );

/// Estimated gross pay — worked hours × rate. Gross only: never take-home,
/// never tax (docs/scope.md phrasing rules).
Decimal estimatedGrossPay(Shift shift) =>
    (Decimal.fromInt(workedMinutes(shift)) *
            shift.ratePerHour /
            Decimal.fromInt(60))
        .toDecimal(scaleOnInfinitePrecision: _divisionScale);
