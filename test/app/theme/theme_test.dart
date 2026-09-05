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
      // De-emphasized Material slot maps to the muted role, not full ink.
      expect(scheme.onSurfaceVariant, colors.inkMuted);
      expect(scheme.surfaceDim, colors.surfaceDim);
      expect(scheme.surfaceContainerLow, colors.surface);
      expect(scheme.surfaceContainerHighest, colors.surfaceDim);
      expect(scheme.outline, colors.hairline);
      expect(scheme.outlineVariant, colors.hairline);
      expect(scheme.error, colors.critical);
      expect(scheme.onError, colors.surface);
    });

    test('Material 3 is off and every component theme is pinned', () {
      expect(theme.useMaterial3, isFalse);
      expect(theme.visualDensity, VisualDensity.compact);
      expect(theme.appBarTheme.backgroundColor, colors.surface);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.cardTheme.color, colors.surfaceDim);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.dividerTheme.color, colors.hairline);
      expect(theme.bottomSheetTheme.elevation, 0);
      expect(theme.navigationBarTheme.backgroundColor, colors.surface);
      expect(theme.navigationBarTheme.indicatorColor, Colors.transparent);
      expect(theme.dialogTheme.backgroundColor, colors.surface);
      expect(theme.dialogTheme.elevation, 0);
      expect(theme.snackBarTheme.backgroundColor, colors.surfaceDim);
      expect(theme.snackBarTheme.elevation, 0);
      expect(theme.floatingActionButtonTheme.backgroundColor, colors.primary);
      expect(theme.floatingActionButtonTheme.elevation, 0);
      expect(theme.progressIndicatorTheme.color, colors.primary);
      expect(theme.chipTheme.backgroundColor, colors.surfaceDim);
      expect(theme.chipTheme.elevation, 0);
      expect(theme.iconTheme.color, colors.ink);
      expect(theme.tabBarTheme.labelColor, colors.ink);
      expect(theme.tabBarTheme.indicatorColor, colors.primary);
      expect(theme.drawerTheme.backgroundColor, colors.surface);
      expect(theme.tooltipTheme.textStyle?.color, colors.surface);
      // Input is underline-only and never filled.
      expect(theme.inputDecorationTheme.filled, isFalse);
      expect(
        theme.inputDecorationTheme.enabledBorder,
        isA<UnderlineInputBorder>(),
      );
      expect(
        theme.inputDecorationTheme.focusedBorder,
        isA<UnderlineInputBorder>(),
      );
      // Buttons carry zero elevation in every state — null means the
      // widget's built-in default, which is 0 for these button types.
      final styles = [
        theme.filledButtonTheme.style,
        theme.elevatedButtonTheme.style,
        theme.textButtonTheme.style,
        theme.outlinedButtonTheme.style,
      ];
      for (final style in styles) {
        expect(style?.elevation?.resolve({}) ?? 0, 0);
        expect(style?.backgroundColor?.resolve({}), isNotNull);
      }
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

    test('bottom sheet carries the only elevation in the design', () {
      // Framework elevation is zero — the single elevationSheet shadow token
      // is applied by the sheet content (see account_sheet.dart).
      expect(theme.bottomSheetTheme.elevation, 0);
    });

    test('FAB stays on the semantic palette, not a seed container tone', () {
      expect(theme.floatingActionButtonTheme.backgroundColor, colors.primary);
      expect(theme.floatingActionButtonTheme.foregroundColor, colors.surface);
    });
  });

  group('ShiftWiseThemes.dark', () {
    final theme = ShiftWiseThemes.dark;
    final colors = DesignColors.dark;

    test('registers the dark palette and follows dark brightness', () {
      expect(theme.extension<DesignColors>(), same(DesignColors.dark));
      expect(theme.extension<DesignType>(), same(DesignType.dark));
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, colors.surface);
      expect(theme.colorScheme.onSurface, colors.ink);
      expect(theme.colorScheme.primary, colors.primary);
    });

    test('dark mirrors the light pins token-for-token', () {
      final scheme = theme.colorScheme;
      expect(scheme.surfaceDim, colors.surfaceDim);
      expect(scheme.onSurfaceVariant, colors.inkMuted);
      expect(scheme.outline, colors.hairline);
      expect(theme.useMaterial3, isFalse);
      expect(theme.visualDensity, VisualDensity.compact);
      expect(theme.inputDecorationTheme.filled, isFalse);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.cardTheme.color, colors.surfaceDim);
      expect(theme.snackBarTheme.backgroundColor, colors.surfaceDim);
      expect(theme.chipTheme.backgroundColor, colors.surfaceDim);
      expect(theme.tabBarTheme.indicatorColor, colors.primary);
    });
  });
}
