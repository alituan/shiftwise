/// Single source of truth for every design value in the app.
///
/// Mirrors `docs/design/tokens.md` (color roles, type family and weights) and
/// `docs/design/screens.md` (spacing scale, type scale, radius, elevation).
/// Feature code never contains hex values or raw sizes: it references these
/// tokens so light/dark switching stays automatic.
library;

import 'package:flutter/material.dart';

/// Brightness-independent tokens: spacing, shape, and the single elevation.
abstract final class Tokens {
  /// Spacing scale — 4px base unit; the only allowed padding/margin values.
  static const double space2xs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;

  /// The only corner radius — cards, buttons, sheets.
  static const double radiusMd = 8;

  /// The only elevation: the bottom sheet floating over content. Separation
  /// everywhere else is hairline dividers plus `colorSurfaceDim` fills.
  static const List<BoxShadow> elevationSheet = [
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

/// Semantic color palette for one brightness mode.
///
/// Read via `context.designColors` — never a raw hex — so both palettes stay
/// in sync and theme switching is automatic.
@immutable
final class DesignColors extends ThemeExtension<DesignColors> {
  const DesignColors({
    required this.ink,
    required this.surface,
    required this.surfaceDim,
    required this.primary,
    required this.concern,
    required this.confirmed,
    required this.critical,
    required this.hairline,
  });

  /// Primary text — including the labels paired with status colors.
  final Color ink;

  /// App background.
  final Color surface;

  /// Day cells, secondary panels, card fills — one step down from surface.
  final Color surfaceDim;

  /// Brand color: CTAs and the hero countdown.
  final Color primary;

  /// Status colors: icon/large-text pairings only, never small body text —
  /// they are specified to the 3:1 threshold, not 4.5:1 (the status-color
  /// rule in docs/design/tokens.md). Always pair with an ink label.
  final Color concern;
  final Color confirmed;
  final Color critical;

  /// Ink at 8% opacity — the app's only separator treatment.
  final Color hairline;

  /// Light palette, per docs/design/tokens.md.
  static final DesignColors light = DesignColors(
    ink: const Color(0xFF14171C),
    surface: const Color(0xFFF6F5F2),
    surfaceDim: const Color(0xFFEAE8E3),
    primary: const Color(0xFF2B4C6F),
    concern: const Color(0xFFC4501C),
    confirmed: const Color(0xFF3A7D5C),
    critical: const Color(0xFFB3261E),
    hairline: const Color(0xFF14171C).withValues(alpha: 0.08),
  );

  /// Dark palette — hues re-tuned for dark-surface contrast, not copied from
  /// light, per docs/design/tokens.md.
  static final DesignColors dark = DesignColors(
    ink: const Color(0xFFEDEBE6),
    surface: const Color(0xFF1B1E24),
    surfaceDim: const Color(0xFF252932),
    primary: const Color(0xFF7FA8CC),
    concern: const Color(0xFFE08349),
    confirmed: const Color(0xFF6FBF95),
    critical: const Color(0xFFE5766F),
    hairline: const Color(0xFFEDEBE6).withValues(alpha: 0.08),
  );

  @override
  DesignColors copyWith({
    Color? ink,
    Color? surface,
    Color? surfaceDim,
    Color? primary,
    Color? concern,
    Color? confirmed,
    Color? critical,
    Color? hairline,
  }) {
    return DesignColors(
      ink: ink ?? this.ink,
      surface: surface ?? this.surface,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      primary: primary ?? this.primary,
      concern: concern ?? this.concern,
      confirmed: confirmed ?? this.confirmed,
      critical: critical ?? this.critical,
      hairline: hairline ?? this.hairline,
    );
  }

  @override
  DesignColors lerp(DesignColors other, double t) {
    if (identical(this, other)) return this;
    return DesignColors(
      ink: Color.lerp(ink, other.ink, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      concern: Color.lerp(concern, other.concern, t)!,
      confirmed: Color.lerp(confirmed, other.confirmed, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
    );
  }
}

/// The app's entire type scale: one family, two weights, four roles.
/// Tabular figures are forced on every style — this app is mostly numbers.
@immutable
final class DesignType extends ThemeExtension<DesignType> {
  const DesignType({
    required this.hero,
    required this.title,
    required this.body,
    required this.label,
  });

  /// 34sp Semibold — next-shift countdown, pay total.
  final TextStyle hero;

  /// 20sp Semibold — screen titles, section headers.
  final TextStyle title;

  /// 16sp Regular — default body text, list rows.
  final TextStyle body;

  /// 13sp Regular — secondary labels, timestamps, helper text.
  final TextStyle label;

  static DesignType _of(Color ink) => DesignType(
    hero: TextStyle(
      fontFamily: 'Inter',
      fontSize: 34,
      fontWeight: FontWeight.w600,
      color: ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    title: TextStyle(
      fontFamily: 'Inter',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    body: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    label: TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );

  /// Light palette type.
  static final DesignType light = _of(DesignColors.light.ink);

  /// Dark palette type.
  static final DesignType dark = _of(DesignColors.dark.ink);

  @override
  DesignType copyWith({
    TextStyle? hero,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
  }) {
    return DesignType(
      hero: hero ?? this.hero,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
    );
  }

  @override
  DesignType lerp(DesignType other, double t) {
    if (identical(this, other)) return this;
    return DesignType(
      hero: TextStyle.lerp(hero, other.hero, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
    );
  }
}

extension DesignTokensContext on BuildContext {
  /// Semantic colors for the active brightness mode.
  DesignColors get designColors => Theme.of(this).extension<DesignColors>()!;

  /// Type scale for the active brightness mode.
  DesignType get designType => Theme.of(this).extension<DesignType>()!;
}
