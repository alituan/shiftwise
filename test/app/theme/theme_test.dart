library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/app/theme/tokens.dart';

void main() {
  group('ShiftWiseThemes.light', () {
    final theme = ShiftWiseThemes.light;
    final colors = DesignColors.light;
    final type = DesignType.light;

    test('registers the palette and type extensions', () {
      expect(theme.extension<DesignColors>(), same(colors));
      expect(theme.extension<DesignType>(), same(type));
    });

    test('pins ColorScheme slots to semantic tokens', () {
      final scheme = theme.colorScheme;
      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, colors.primary);
      expect(scheme.onPrimary, colors.surface);
      expect(scheme.surface, colors.surface);
      expect(scheme.onSurface, colors.ink);
      expect(scheme.onSurfaceVariant, colors.ink);
      expect(scheme.surfaceDim, colors.surfaceDim);
      expect(scheme.error, colors.critical);
      expect(scheme.onError, colors.surface);
    });

    test('scaffold and app bar use surface, not a default background', () {
      expect(theme.scaffoldBackgroundColor, colors.surface);
      expect(theme.appBarTheme.backgroundColor, colors.surface);
      expect(theme.appBarTheme.foregroundColor, colors.ink);
    });

    test('type scale fills the Material text slots', () {
      expect(theme.textTheme.displayLarge?.fontSize, 34);
      expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w600);
      expect(theme.textTheme.titleLarge?.fontSize, 20);
      expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
      expect(theme.textTheme.labelLarge?.fontSize, 13);
      expect(theme.textTheme.labelLarge?.fontWeight, FontWeight.w400);
      expect(
        theme.textTheme.displayLarge?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('dividers are hairlines, cards are flat surfaceDim at radiusMd', () {
      expect(theme.dividerTheme.color, colors.hairline);
      expect(theme.dividerTheme.thickness, 1);
      expect(theme.cardTheme.color, colors.surfaceDim);
      expect(theme.cardTheme.elevation, 0);
      expect(
        (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(Tokens.radiusMd),
      );
    });

    test('bottom sheet keeps the single radius on its top corners', () {
      final shape = theme.bottomSheetTheme.shape as RoundedRectangleBorder;
      expect(
        (shape.borderRadius as BorderRadius).topLeft,
        const Radius.circular(Tokens.radiusMd),
      );
      expect(theme.bottomSheetTheme.backgroundColor, colors.surface);
    });
  });

  group('ShiftWiseThemes.dark', () {
    final theme = ShiftWiseThemes.dark;

    test('registers the dark palette and follows dark brightness', () {
      expect(theme.extension<DesignColors>(), same(DesignColors.dark));
      expect(theme.extension<DesignType>(), same(DesignType.dark));
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, DesignColors.dark.surface);
      expect(theme.colorScheme.onSurface, DesignColors.dark.ink);
      expect(theme.colorScheme.primary, DesignColors.dark.primary);
    });
  });
}
