library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/tokens.dart';

void main() {
  group('spacing scale — 4px base unit (docs/design/screens.md)', () {
    test('matches the documented values', () {
      expect(Tokens.space2xs, 4);
      expect(Tokens.spaceXs, 8);
      expect(Tokens.spaceSm, 12);
      expect(Tokens.spaceMd, 16);
      expect(Tokens.spaceLg, 24);
      expect(Tokens.spaceXl, 32);
      expect(Tokens.space2xl, 48);
    });
  });

  group('shape and elevation', () {
    test('single corner radius', () {
      expect(Tokens.radiusMd, 8);
    });

    test('single elevation token exists for the bottom sheet', () {
      expect(Tokens.elevationSheet, hasLength(1));
    });
  });

  group('palette hex values mirror docs/design/tokens.md', () {
    test('light', () {
      final c = DesignColors.light;
      expect(c.ink.toARGB32(), 0xFF14171C);
      expect(c.surface.toARGB32(), 0xFFF6F5F2);
      expect(c.surfaceDim.toARGB32(), 0xFFEAE8E3);
      expect(c.primary.toARGB32(), 0xFF2B4C6F);
      expect(c.concern.toARGB32(), 0xFFC4501C);
      expect(c.confirmed.toARGB32(), 0xFF3A7D5C);
      expect(c.critical.toARGB32(), 0xFFB3261E);
    });

    test('dark', () {
      final c = DesignColors.dark;
      expect(c.ink.toARGB32(), 0xFFEDEBE6);
      expect(c.surface.toARGB32(), 0xFF1B1E24);
      expect(c.surfaceDim.toARGB32(), 0xFF252932);
      expect(c.primary.toARGB32(), 0xFF7FA8CC);
      expect(c.concern.toARGB32(), 0xFFE08349);
      expect(c.confirmed.toARGB32(), 0xFF6FBF95);
      expect(c.critical.toARGB32(), 0xFFE5766F);
    });

    test('hairline is ink at 8% opacity in both palettes', () {
      // 0.08 * 255 rounds to alpha 20 (0x14) on an otherwise-unchanged ink.
      for (final c in [DesignColors.light, DesignColors.dark]) {
        expect(
          c.hairline.toARGB32(),
          (c.ink.toARGB32() & 0x00FFFFFF) | 0x14000000,
        );
      }
    });
  });

  group('type scale mirrors docs/design/screens.md', () {
    test('sizes and weights', () {
      for (final t in [DesignType.light, DesignType.dark]) {
        expect(t.hero.fontSize, 34);
        expect(t.hero.fontWeight, FontWeight.w600);
        expect(t.title.fontSize, 20);
        expect(t.title.fontWeight, FontWeight.w600);
        expect(t.body.fontSize, 16);
        expect(t.body.fontWeight, FontWeight.w400);
        expect(t.label.fontSize, 13);
        expect(t.label.fontWeight, FontWeight.w400);
      }
    });

    test('one family, tabular figures forced on every style', () {
      for (final t in [DesignType.light, DesignType.dark]) {
        for (final style in [t.hero, t.title, t.body, t.label]) {
          expect(style.fontFamily, 'Inter');
          expect(
            style.fontFeatures,
            contains(const FontFeature.tabularFigures()),
          );
        }
      }
    });

    test('text colors follow the palette ink', () {
      expect(DesignType.light.hero.color, DesignColors.light.ink);
      expect(DesignType.light.label.color, DesignColors.light.ink);
      expect(DesignType.dark.hero.color, DesignColors.dark.ink);
      expect(DesignType.dark.label.color, DesignColors.dark.ink);
    });
  });
}
