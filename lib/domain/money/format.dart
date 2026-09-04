/// Currency and hour display formatting. Decimal in, string out — currency
/// values never touch double (AGENTS.md hard rule).
library;

import 'package:decimal/decimal.dart';

/// Formats as US dollars with exactly two fractional digits, rounding the
/// cent value. Phase 1 assumes USD; user currency settings come later.
String formatUsd(Decimal amount) {
  final cents = (amount * Decimal.fromInt(100)).round();
  final negative = cents < Decimal.zero;
  final digits = cents.abs().toString().padLeft(3, '0');
  final whole = digits.substring(0, digits.length - 2);
  final fraction = digits.substring(digits.length - 2);
  return '${negative ? '-' : ''}\$$whole.$fraction';
}

/// Hours with at least one decimal place — "8.0", "7.5", "0.0".
String formatHours(Decimal hours) {
  if (hours == hours.truncate()) {
    return '${hours.truncate()}.0';
  }
  return hours.toString();
}
