library;

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/domain/money/format.dart';

void main() {
  group('formatUsd', () {
    test('whole and fractional amounts', () {
      expect(formatUsd(Decimal.parse('124')), '\$124.00');
      expect(formatUsd(Decimal.parse('123.75')), '\$123.75');
      expect(formatUsd(Decimal.parse('0.5')), '\$0.50');
      expect(formatUsd(Decimal.parse('0.05')), '\$0.05');
    });

    test('zero pads to two digits', () {
      expect(formatUsd(Decimal.zero), '\$0.00');
    });

    test('negative amounts keep the sign', () {
      expect(formatUsd(Decimal.parse('-12.4')), '-\$12.40');
    });

    test('rounds cent fractions', () {
      expect(formatUsd(Decimal.parse('1.999')), '\$2.00');
      expect(formatUsd(Decimal.parse('1.994')), '\$1.99');
    });
  });

  group('formatHours', () {
    test('keeps at least one decimal place', () {
      expect(formatHours(Decimal.fromInt(8)), '8.0');
      expect(formatHours(Decimal.zero), '0.0');
      expect(formatHours(Decimal.parse('7.5')), '7.5');
    });
  });
}
