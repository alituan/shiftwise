# Design Tokens

Source of truth for every color, type, and spacing value. **No inline hex values or magic numbers in feature code** — everything references `mobile/src/design/tokens.ts` (mirrored into `mobile/global.css`'s Uniwind `@theme` block), which this doc mirrors.

## 2026-09-06 — dark-first rebuild (owner spec)

This replaces the light/dark palette carried over from the Flutter app (see `docs/architecture/stack.md`'s deviation record for why). **No light mode for now** — dark-first only, a system-follow override is a later addition, not built yet.

### Base

- Background: `#0A0A0B` — applied once at the app root (`app/_layout.tsx`), never per-screen.
- Font: **Inter**, two weights only — Regular (400) and Bold (700). Loaded via `@expo-google-fonts/inter`.
- Tabular figures forced on all numeric displays (time/hours/money) — see `Typography.tsx`'s `numeric` prop.

### Color tokens

| Token | Value | Role |
|---|---|---|
| `background` | `#0A0A0B` | App background, set once at the root |
| `surface` | `rgba(255,255,255,0.06)` | Glass tint (cards, sheets over blur) |
| `surfaceBorder` | `rgba(255,255,255,0.12)` | The only depth signal on glass surfaces — no shadows |
| `ink` | `#FFFFFF` | Primary text/icon color |
| `inkSecondary` | `rgba(255,255,255,0.55)` | De-emphasized text (ghost button, secondary type) |
| `primary` | `#3B6EF8` | Electric blue — primary button, active states |
| `primaryGlow` | `rgba(59,110,248,0.35)` | Reserved for future glow-adjacent UI; the hero glow effect itself uses a distinct, more saturated value — see below |
| `concern` | `#F59E0B` | Same "icon/label pairing, never color alone" rule as before — see the original design-brief rules further down this doc |
| `confirmed` | `#10B981` | |
| `critical` | `#EF4444` | |

Component-specific surfaces (not general roles, kept alongside since they're one-off per spec): `bottomSheetSurface` (`#141416`), `bottomSheetHandle`/`bottomSheetBorder`/`bottomSheetBackdrop`, `bottomNavBackground`/`bottomNavBorder`/`bottomNavInactive`. Full list: `mobile/src/design/tokens.ts`.

### Glow effect

Ambient radial gradient behind hero content — center `rgba(59,110,248,0.45)` fading to transparent, 280×280, positioned top-center. Implemented with `react-native-svg`'s `RadialGradient` (not `expo-linear-gradient`, which is linear-only and cannot produce a true radial falloff) — see `GlowEffect.tsx`.

### Typography scale

| Token | Weight/Size | Color |
|---|---|---|
| `hero` | Inter Bold 34 | `#FFFFFF`, tabular figures when used for numbers |
| `title` | Inter Bold 20 | `#FFFFFF` |
| `body` | Inter Regular 16 | `#FFFFFF` |
| `secondary` | Inter Regular 14 | `rgba(255,255,255,0.55)` |
| `label` | Inter Regular 12 | `rgba(255,255,255,0.55)` |

### Component specs

- **GlassCard**: `rgba(255,255,255,0.06)` background, `1px solid rgba(255,255,255,0.12)` border, `16px` radius, `expo-blur` `BlurView` intensity 20, `16px` padding, no shadow. See `GlassCard.tsx`'s header comment for the three-layer composition (unblurred border/clip shell, static blur layer, tinted content layer) — putting background color directly on the blurred node causes Android compositing/corner-clipping artifacts.
- **PrimaryButton**: `#3B6EF8` flat background (no gradient, no shadow), `14px` radius, `52px` height, full width, Inter Bold 16 `#FFFFFF` text. Press: scale to 0.97 over 150ms via `react-native-reanimated`'s `withTiming`.
- **GhostButton**: transparent, no border, Inter Regular 15 `rgba(255,255,255,0.55)`. Press: opacity to 0.6 over 100ms.
- **BottomNav**: `64px` + safe-area-inset height, `rgba(10,10,11,0.92)` tint over an `expo-blur` `BlurView`, `1px solid rgba(255,255,255,0.08)` top border, `lucide-react-native` icons at size 22. Active = `#FFFFFF` icon + Inter Regular 11 `#FFFFFF` label below; inactive = `rgba(255,255,255,0.35)` icon, no label. No pill/background indicator — color change only. Tab press: icon scale 1.0→1.15→1.0 via `withSpring`.
- **AppBottomSheet** (`@gorhom/bottom-sheet` wrapper): `#141416` background (one step above base), `32×4` handle at `rgba(255,255,255,0.2)` with `2px` radius, `1px solid rgba(255,255,255,0.10)` top border, `rgba(0,0,0,0.6)` backdrop.
- **GoogleSignInButton**: same glass-card composition as `GlassCard`, Google "G" mark left-aligned (`react-native-svg`), Inter Regular 16 `#FFFFFF` "Continue with Google", full width.

### Animation libraries

Exactly two: `react-native-reanimated` (all gesture/transition animations, via `withSpring`/`withTiming` only — never the legacy `Animated` API) and `react-native-gesture-handler` (gesture detection, also required by `@gorhom/bottom-sheet`). No other animation library.

### Icons

`lucide-react-native` only. No other icon library.

---

## Pre-2026-09-06 design brief and rules (still in force where not superseded above)

A shift worker opens this app to answer one of three questions, usually fast, often in bad conditions: end of a shift, half-asleep, glare on screen, one thumb, spotty signal. Design for a 2-second glance, not a lingering dashboard session. Reject generic SaaS defaults: gradient washes, glass/blur cards, shadow-on-everything, all-caps tracked labels.

**Rule: concern ≠ error.** These must look visually distinct or users start ignoring warnings.

**Rule: color is never the only status signal.** Every confirmed/concern/failed/syncing state needs an icon or label alongside the color.

**Rule: status colors are icon/large-text pairings only — never small body text.** A status-colored element (icon, chip tint, large text) must always carry an adjacent `ink`-colored label so meaning survives contrast limits, glare, and color-vision deficiencies.

**Contrast requirement:** every text-on-surface and icon-on-surface pairing meets WCAG AA (4.5:1 normal text, 3:1 large text/icons). With no light mode yet, this only needs verifying against the dark palette above — re-verify independently whenever a light mode is added, don't assume the dark-mode ratio carries over.

## Writing/microcopy rules

- Buttons name the action: "Confirm 6 shifts," not "Submit."
- Empty states give a next action, not just an illustration: "No shifts yet — add one or scan a schedule photo."
- Errors state what happened + what to do: "Couldn't upload — check your connection and try again."
- Never say "take-home pay" or imply tax accuracy anywhere in copy — hard content rule, see `docs/scope.md`.

## Golden-test requirement

Every design-system component (buttons, day-cell, status chips) needs a component test — and once a second theme/palette exists, a visual snapshot test in both — before it's considered done.
