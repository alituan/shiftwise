/// WCAG AA contrast checks for the token pairings the design actually uses,
/// measured per palette — dark-mode contrast is computed, not assumed.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/tokens.dart';

double _relativeLuminance(Color c) {
  double channel(double s) =>
      s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final palettes = {'light': DesignColors.light, 'dark': DesignColors.dark};

  group('text pairings meet AA 4.5:1', () {
    for (final p in palettes.entries) {
      test('${p.key}: ink on surface and surfaceDim', () {
        expect(_contrastRatio(p.value.ink, p.value.surface), greaterThan(4.5));
        expect(
          _contrastRatio(p.value.ink, p.value.surfaceDim),
          greaterThan(4.5),
        );
      });

      test('${p.key}: primary as hero text on surface', () {
        expect(
          _contrastRatio(p.value.primary, p.value.surface),
          greaterThan(4.5),
        );
      });

      test('${p.key}: surface as button text on primary', () {
        expect(
          _contrastRatio(p.value.surface, p.value.primary),
          greaterThan(4.5),
        );
      });
    }
  });

  group('status colors meet the 3:1 icon/large-text threshold', () {
    // Status colors are icon/large-text pairings only, never small body text
    // (docs/design/tokens.md status-color rule): they must clear 3:1 on the
    // surfaces they sit on and always carry an adjacent ink label.
    for (final p in palettes.entries) {
      test('${p.key}: on surface and surfaceDim', () {
        for (final status in [
          p.value.concern,
          p.value.confirmed,
          p.value.critical,
        ]) {
          expect(_contrastRatio(status, p.value.surface), greaterThan(3));
          expect(_contrastRatio(status, p.value.surfaceDim), greaterThan(3));
        }
      });
    }
  });

  test('concern and critical are distinct in both palettes', () {
    // Luminance contrast between the two hues themselves is only ~1.4:1
    // (light) and ~1.05:1 (dark): they are distinct by hue, and the ink-label
    // rule carries the meaning — not luminance separation.
    expect(DesignColors.light.concern, isNot(DesignColors.light.critical));
    expect(DesignColors.dark.concern, isNot(DesignColors.dark.critical));
  });
}
