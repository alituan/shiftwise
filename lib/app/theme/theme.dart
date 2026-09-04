/// Light and dark [ThemeData] assembled exclusively from the design tokens.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the two app themes. Framework-facing [ColorScheme] slots are pinned
/// to the same semantic tokens so stock Material components inherit the
/// palette without any per-widget hex.
abstract final class ShiftWiseThemes {
  static ThemeData get light =>
      _theme(Brightness.light, DesignColors.light, DesignType.light);

  static ThemeData get dark =>
      _theme(Brightness.dark, DesignColors.dark, DesignType.dark);

  static ThemeData _theme(
    Brightness brightness,
    DesignColors colors,
    DesignType type,
  ) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.surface,
          surface: colors.surface,
          onSurface: colors.ink,
          onSurfaceVariant: colors.ink,
          surfaceDim: colors.surfaceDim,
          error: colors.critical,
          onError: colors.surface,
          outlineVariant: colors.hairline,
        );

    // The four type-scale roles fill the Material slots feature code is most
    // likely to reach for; apply() propagates family and ink to the rest.
    final textTheme =
        TextTheme(
          displayLarge: type.hero,
          titleLarge: type.title,
          bodyLarge: type.body,
          labelLarge: type.label,
        ).apply(
          bodyColor: colors.ink,
          displayColor: colors.ink,
          fontFamily: 'Inter',
        );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      extensions: [colors, type],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: type.title,
      ),
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1),
      // M3 defaults the FAB to a seed-derived primaryContainer that is not
      // in the semantic palette — CTAs and the FAB share the primary token.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.surface,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceDim,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Tokens.radiusMd),
          ),
        ),
      ),
    );
  }
}
