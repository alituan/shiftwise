/// Light and dark [ThemeData] assembled exclusively from the design tokens.
///
/// Material 3 is off (`useMaterial3: false`): production UI is built from
/// the custom component library (lib/shared/widgets/) — AppButton,
/// AppAppBar, AppNavBar, AppSheet — so no Material component default
/// reaches the screen. The component themes below are belt-and-braces
/// pins for the framework surfaces that remain (dialogs, pickers,
/// snackbars, progress): every slot is an explicit token, nothing is
/// seed-derived. Reference aesthetic: Linear / Vercel / Arc — dense,
/// dark-first, high contrast.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the two app themes. The dark palette is the design reference;
/// light stays in sync through the same semantic roles.
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
    // Every slot is an explicit token — no ColorScheme.fromSeed, so no
    // seed-derived containers or tertiary hues can leak into any widget.
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.surface,
      secondary: colors.primary,
      onSecondary: colors.surface,
      tertiary: colors.primary,
      onTertiary: colors.surface,
      error: colors.critical,
      onError: colors.surface,
      surface: colors.surface,
      onSurface: colors.ink,
      onSurfaceVariant: colors.inkMuted,
      surfaceDim: colors.surfaceDim,
      surfaceBright: colors.surfaceDim,
      surfaceContainer: colors.surfaceDim,
      surfaceContainerHigh: colors.surfaceDim,
      surfaceContainerHighest: colors.surfaceDim,
      surfaceContainerLow: colors.surface,
      surfaceContainerLowest: colors.surface,
      outline: colors.hairline,
      outlineVariant: colors.hairline,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: colors.ink,
      onInverseSurface: colors.surface,
      inversePrimary: colors.primary,
    );

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

    final underline = UnderlineInputBorder(
      borderSide: BorderSide(color: colors.hairline),
    );

    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      extensions: [colors, type],
      visualDensity: VisualDensity.compact,
      iconTheme: IconThemeData(color: colors.ink, size: 24),
      splashFactory: InkRipple.splashFactory,
      // Framework-facing component pins: production screens use the custom
      // library, these cover dialogs, pickers, snackbars, and any future
      // framework surface so no Material default visual can appear.
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: type.title,
        iconTheme: IconThemeData(color: colors.ink),
        actionsIconTheme: IconThemeData(color: colors.ink),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.surface,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
      buttonTheme: ButtonThemeData(
        colorScheme: colorScheme,
        textTheme: ButtonTextTheme.primary,
        minWidth: 48,
        height: 48,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.ink,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusMd),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.ink,
          highlightColor: colors.splash,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceDim,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
        titleTextStyle: type.title,
        contentTextStyle: type.body,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        // Framework elevation stays at zero: the design's single shadow
        // (Tokens.elevationSheet) is applied by the sheet content itself,
        // where it can be the exact token BoxShadow.
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Tokens.radiusMd),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceDim,
        contentTextStyle: type.body.copyWith(color: colors.ink),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(type.label),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: colors.ink)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceDim,
        selectedColor: colors.surfaceDim,
        disabledColor: colors.surfaceDim,
        deleteIconColor: colors.inkMuted,
        labelStyle: type.label.copyWith(color: colors.ink),
        secondaryLabelStyle: type.label.copyWith(color: colors.ink),
        iconTheme: IconThemeData(color: colors.ink, size: 18),
        side: BorderSide(color: colors.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radius2xs),
        ),
        elevation: 0,
        pressElevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.surface
              : colors.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceDim,
        ),
        trackOutlineColor: WidgetStatePropertyAll(colors.hairline),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(colors.surface),
        side: BorderSide(color: colors.inkMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radius2xs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.inkMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.ink,
        unselectedLabelColor: colors.inkMuted,
        indicatorColor: colors.primary,
        dividerColor: colors.hairline,
        overlayColor: WidgetStatePropertyAll(colors.splash),
        labelStyle: type.label,
        unselectedLabelStyle: type.label,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        // Underline-only fields: no Material filled default anywhere.
        filled: false,
        border: underline,
        enabledBorder: underline,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.critical),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.critical, width: 1.5),
        ),
        labelStyle: type.label.copyWith(color: colors.inkMuted),
        floatingLabelStyle: type.label.copyWith(color: colors.ink),
        helperStyle: type.label.copyWith(color: colors.inkMuted),
        errorStyle: type.label.copyWith(color: colors.critical),
        hintStyle: type.label.copyWith(color: colors.inkMuted),
        isDense: true,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
      tooltipTheme: TooltipThemeData(
        textStyle: type.label.copyWith(color: colors.surface),
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: BorderRadius.circular(Tokens.radius2xs),
        ),
      ),
    );
  }
}
