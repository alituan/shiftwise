/**
 * Design system tokens — dark-first, no light mode yet (owner decision,
 * 2026-09-06). Every value a component needs lives here as a typed
 * constant; components reference these, never an inline hex/rgba string.
 * Mirrors docs/design/tokens.md exactly — keep both in sync.
 */

export const colors = {
  background: '#0A0A0B',
  surface: 'rgba(255,255,255,0.06)',
  surfaceBorder: 'rgba(255,255,255,0.12)',
  ink: '#FFFFFF',
  inkSecondary: 'rgba(255,255,255,0.55)',
  primary: '#3B6EF8',
  primaryGlow: 'rgba(59,110,248,0.35)',
  concern: '#F59E0B',
  confirmed: '#10B981',
  critical: '#EF4444',

  // Component-specific surfaces, not general semantic tokens, kept
  // alongside the roles above since they're one-off per spec.
  bottomSheetSurface: '#141416', // one step above background
  bottomSheetHandle: 'rgba(255,255,255,0.2)',
  bottomSheetBorder: 'rgba(255,255,255,0.10)',
  bottomSheetBackdrop: 'rgba(0,0,0,0.6)',
  bottomNavBackground: 'rgba(10,10,11,0.92)',
  bottomNavBorder: 'rgba(255,255,255,0.08)',
  bottomNavInactive: 'rgba(255,255,255,0.35)',
  ghostButtonText: 'rgba(255,255,255,0.55)',
} as const;

/** The one ambient glow effect behind hero content — see GlowEffect component. */
export const glow = {
  centerColor: 'rgba(59,110,248,0.45)',
  edgeColor: 'transparent',
  size: 280,
} as const;

export const typography = {
  hero: { fontFamily: 'Inter_700Bold', fontSize: 34, color: colors.ink },
  title: { fontFamily: 'Inter_700Bold', fontSize: 20, color: colors.ink },
  body: { fontFamily: 'Inter_400Regular', fontSize: 16, color: colors.ink },
  secondary: { fontFamily: 'Inter_400Regular', fontSize: 14, color: colors.inkSecondary },
  label: { fontFamily: 'Inter_400Regular', fontSize: 12, color: colors.inkSecondary },
} as const;

/** All numeric/time/money displays force tabular figures — see Typography.tsx. */
export const tabularFigures = {
  fontVariant: ['tabular-nums'] as const,
};

export const radii = {
  card: 16,
  button: 14,
  bottomSheetHandle: 2,
} as const;

export const spacing = {
  cardPadding: 16,
} as const;

export const dimensions = {
  primaryButtonHeight: 52,
  bottomNavHeight: 64,
  bottomSheetHandleWidth: 32,
  bottomSheetHandleHeight: 4,
  iconSize: 22,
} as const;

export const blur = {
  glassCardIntensity: 20,
  bottomNavIntensity: 20,
} as const;

export const animation = {
  primaryButtonPressScale: 0.97,
  primaryButtonPressDurationMs: 150,
  ghostButtonPressOpacity: 0.6,
  ghostButtonPressDurationMs: 100,
  tabIconScalePeak: 1.15,
} as const;

export const fonts = {
  regular: 'Inter_400Regular',
  bold: 'Inter_700Bold',
} as const;
