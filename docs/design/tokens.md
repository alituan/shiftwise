# Design Tokens

Source of truth for every color, type, and spacing value. **No inline hex values or magic numbers in feature code** — everything references `src/theme/tokens.ts` (mapped into the Uniwind/Tailwind theme), which this doc mirrors.

## Design brief (read this before changing anything below)

A shift worker opens this app to answer one of three questions, usually fast, often in bad conditions: end of a shift, half-asleep, glare on screen, one thumb, spotty signal. Design for a 2-second glance, not a lingering dashboard session. Reject generic SaaS defaults: gradient washes, glass/blur cards, shadow-on-everything, all-caps tracked labels.

## Color

Two palettes, same semantic roles. Every token below has a light and dark value — components reference the semantic token (`colorSurface`), never a raw hex, so theme switching is automatic and there's no per-screen dark-mode logic to maintain.

| Role | Token | Light | Dark | Why |
|---|---|---|---|---|
| Ink (primary text) | `colorInk` | `#14171C` | `#EDEBE6` | Near-black on light; warm off-white on dark, not pure white — avoids harsh glare at night, which is when this app gets used most |
| Ink-muted (secondary) | `colorInkMuted` | ink @ 60% | ink @ 60% | Inactive nav icons, helper text, placeholder rows — reduced emphasis that still clears 3:1 on surface in both palettes |
| Surface | `colorSurface` | `#F6F5F2` | `#1B1E24` | Warm off-white / near-black, not clinical white or pure `#000` |
| Surface-dim | `colorSurfaceDim` | `#EAE8E3` | `#252932` | One step down — day-cells, secondary panels |
| Primary (brand, CTAs) | `colorPrimary` | `#2B4C6F` | `#7FA8CC` | Dark mode primary is lightened, not the same hex on a dark background — a `#2B4C6F` button on `#1B1E24` fails contrast |
| Concern / warning | `colorConcern` | `#C4501C` | `#E08349` | Lightened for dark-background contrast, same hue identity |
| Confirmed / success | `colorConfirmed` | `#3A7D5C` | `#6FBF95` | Lightened for dark-background contrast |
| Critical (errors only) | `colorCritical` | `#B3261E` | `#E5766F` | Lightened for dark-background contrast |
| Splash | `colorSplash` | ink @ 12% | ink @ 12% | The only ripple color — every ink-response surface splashes from this token, never a Material default |
| Hairline | `colorHairline` | ink @ 8% | ink @ 8% | The only separator treatment — see spacing/shape in screens.md |

**Rule: concern ≠ error.** These must look visually distinct or users start ignoring warnings — true in both palettes independently, verify contrast between `colorConcern` and `colorCritical` separately for light and dark, don't assume light-mode contrast checking covers dark mode.

**Rule: color is never the only status signal.** Every confirmed/concern/failed/syncing state needs an icon or label alongside the color — see `StatusChip` component in `docs/design/screens.md`.

**Rule: status colors are icon/large-text pairings only — never small body text.** `colorConcern`, `colorConfirmed`, and `colorCritical` are specified against the 3:1 large-text/icon threshold on `colorSurface`, not the 4.5:1 small-text threshold (`colorConcern` on light `colorSurface` measures 4.27:1). Never set body or label text in a status color; a status-colored element (icon, chip tint, large text) must always carry an adjacent `colorInk` label so meaning survives contrast limits, glare, and color-vision deficiencies.

**Contrast requirement:** every text-on-surface and icon-on-surface pairing meets WCAG AA (4.5:1 normal text, 3:1 large text/icons) in **both** palettes independently — don't derive dark-mode contrast by assumption, check it directly, since simply lightening a hue doesn't guarantee the ratio holds.

**Theme source:** system default (`MediaQuery.platformBrightnessOf`) on first launch, with a manual override in Settings. Persist the override locally; don't re-derive from system brightness on every launch if the user has explicitly chosen one.

## Typography

- One family: **Inter** or **IBM Plex Sans** — strong tabular-figure support, this app is ~80% numbers.
- Two weights: Regular (body), Semibold (display numbers, headers).
- Force tabular figures on for all time/hours/money display.
- Full type scale (exact sizes, weights, and roles) lives in `docs/design/screens.md` — this doc covers family/weight choice, that one covers the concrete scale so it stays next to where it's applied.

## Spacing & shape

Spacing scale, corner radius, and elevation rules live in `docs/design/screens.md` alongside the component inventory — kept together since spacing decisions only make sense in the context of the components using them.

## Layout principles

- Mobile is the primary target. Desktop/tablet (if a web target is ever built via Expo web) reuses a three-region layout: nav / workspace / context panel.
- The next-shift countdown is the one hero element — largest type, primary color. Everything else stays quiet.
- Separate content with hairline dividers and `colorSurfaceDim`, not shadows-on-every-card.
- Bottom nav (mobile): Schedule, Scan, Pay, Settings — thumb reach.

## Motion

One deliberate animation, not motion-on-every-interaction. The confirm moment (AI-suggested shift → user-confirmed) is the one worth marking — a clean checkmark draw-in, not a bounce effect. Everything else uses standard platform transitions. Respect the OS-level reduce-motion accessibility setting.

## Writing/microcopy rules

- Buttons name the action: "Confirm 6 shifts," not "Submit."
- Empty states give a next action, not just an illustration: "No shifts yet — add one or scan a schedule photo."
- Errors state what happened + what to do: "Couldn't upload — check your connection and try again."
- Never say "take-home pay" or imply tax accuracy anywhere in copy — hard content rule, see `docs/scope.md`.

## Golden-test requirement

Every design-system component (buttons, day-cell, status chips) needs a visual snapshot test in `__tests__/` **in both light and dark palettes** before it's considered done. Set this up in Phase 1 — retrofitting baselines after drift has already happened defeats the purpose, and retrofitting a second palette after screens are already built is exactly the rework dark-mode-from-day-one is meant to avoid.
