# Screens

Assumes `docs/design/tokens.md` is already loaded/understood. Each screen below: purpose, states, layout note.

## Schedule (home)

**Purpose:** answer "when's my next shift" in one glance.

```
┌─────────────────────────┐
│ ← Week strip (scroll) →  │
├─────────────────────────┤
│   NEXT SHIFT              │  <- hero: largest type, colorPrimary
│   Tue · 2:00–10:00 PM    │
│   in 3h 12m               │
├─────────────────────────┤
│  Today's hours: 8.0      │  secondary weight
│  Est. pay: $124.00       │
├─────────────────────────┤
│  Day cells (tap to       │
│  expand)                 │
└─────────────────────────┘
```

States required: empty (no shifts — show add/scan CTA), loading, offline (cached data visible, sync indicator), syncing, error.

Day cells show: time, job marker, concern marker (icon, not color-only).

## Scan

**Purpose:** photo → reviewable draft → confirmed shifts. AI never writes directly to confirmed data — see `docs/architecture/ai-import.md` for the full pipeline this screen drives.

Flow: camera/file picker → crop to user's own row (`expo-image-picker`) → privacy/consent notice naming the AI processor → local preview → upload → queued/processing/review states → side-by-side crop-vs-extracted-result for review → explicit per-shift confirm.

States: idle, capturing, cropping, uploading, queued, processing, review_required, confirmed, failed. Each needs distinct visual treatment — this maps directly to the job state machine in `docs/architecture/ai-import.md`, keep them in sync.

## Pay

**Purpose:** show estimated gross pay with visible inputs, never implying exact take-home.

Always label "Estimated gross pay," never bare "Pay." Show hours, base estimate, applied differentials, and the rule version used for the calculation (traceability — see `docs/architecture/pay-engine.md`). No tax/take-home figure unless separately scoped and approved.

## Spacing scale

4px base unit. Use only these values — no arbitrary padding/margin numbers in feature code:

| Token | Value | Use |
|---|---|---|
| `space2xs` | 4 | icon-to-label gaps |
| `spaceXs` | 8 | tight internal padding (chip, badge) |
| `spaceSm` | 12 | default internal padding (list row, small card) |
| `spaceMd` | 16 | screen horizontal margin, standard gap between elements |
| `spaceLg` | 24 | gap between distinct sections on a screen |
| `spaceXl` | 32 | gap above/below the hero element |
| `space2xl` | 48 | top safe-area breathing room on hero screens |

## Type scale

Paired with the family/weight rules above — these are the only sizes in the app, referenced by role, not by raw sp value in feature code:

| Token | Size | Weight | Use |
|---|---|---|---|
| `textHero` | 34sp | Semibold | Next-shift countdown, pay total |
| `textTitle` | 20sp | Semibold | Screen titles, section headers |
| `textBody` | 16sp | Regular | Default body text, list rows |
| `textLabel` | 13sp | Regular | Secondary labels, timestamps, helper text |

Never introduce a fifth size without updating this table first — see AGENTS.md rule against magic values.

## Corner radius & elevation

- One radius: `radiusMd = 8px`, used for cards, buttons, sheets. No mixed radii per the SaaS-card-kit anti-pattern noted in the design brief.
- No drop shadows for separation — use `colorSurfaceDim` fill and hairline `colorInk` @ 8% opacity dividers instead. Reserve elevation (a single subtle shadow token, `elevationSheet`) for exactly one case: the bottom sheet floating over content, since that's a real depth relationship, not decoration.

## Component inventory

Every screen in this doc references one of these. Build each once in `src/shared/components/`, reuse everywhere — don't let two screens invent two versions of the same component.

| Component | Used on | Behavior notes |
|---|---|---|
| `StatusChip` | Schedule (concern marker), Scan (job state), Pay (rule version tag) | Icon + label pair, never color-only. Variants: `confirmed`, `concern`, `failed`, `syncing`, `neutral` — maps to color tokens above. |
| `SyncIndicator` | Schedule, Scan | Small persistent indicator (not a modal/toast) showing `synced` / `syncing` / `offline` / `conflict`. Tapping a `conflict` state opens the conflict resolution prompt (`docs/architecture/offline-conflict-resolution.md`). |
| `DayCell` | Schedule week strip and expanded day view | Shows date, shift time range if present, `StatusChip` for concern if any, empty-state variant (no shift that day). |
| `ShiftRow` | Schedule day expansion, Scan review list | Time range, job name, break duration, edit/delete swipe actions (see gestures below). |
| `HeroCountdown` | Schedule only | The one screen-specific hero component — not reused elsewhere, don't generalize it prematurely. |
| `ReviewCard` | Scan review screen | Side-by-side (wide) or stacked (narrow) crop image vs. extracted fields, per-field confidence indicator, accept/edit/discard actions. |
| `EmptyState` | Any screen with no data | Icon, one line of copy, one primary action — never just an illustration with no path forward (per copy rules in tokens.md). |
| `ConflictPrompt` | Triggered from `SyncIndicator` or inline on a `ShiftRow` | Full-screen or large bottom sheet (not a small dialog — this decision matters, see below) showing both versions side by side per `offline-conflict-resolution.md` UX rules. |

## Interaction & gesture rules

- **Tap targets:** minimum 44×44pt on every interactive element, no exceptions, including icon-only buttons — this is the accessibility floor, not a nice-to-have.
- **Swipe on `ShiftRow`:** swipe-left reveals Edit + Delete actions (two-action reveal, not a single destructive swipe-to-delete — deleting a shift is consequential enough to require a confirmed tap after the swipe reveal, not just a swipe gesture alone).
- **Pull-to-refresh:** Schedule screen only, standard platform gesture, triggers a manual Firestore re-sync check (mostly a UX affordance since Firestore listeners are already live — this is for the user's peace of mind after reconnecting from offline, not a functional requirement).
- **Bottom sheet vs. full route:** a screen opens as a bottom sheet if the user needs to glance back at what triggered it (shift detail from a day cell, conflict prompt) and as a full route if it's a multi-step flow they're committing to (Scan capture-to-review, Settings sub-pages). If unsure which, default to full route — sheets that get too tall defeat their own purpose.
- **Confirm dialogs:** only for destructive/hard-to-reverse actions (delete shift, account deletion, discard AI-import draft). Never a confirm dialog for reversible actions like editing a field — that's just friction.



Standard CRUD + preference screens: profile, locale/timezone/week-start, jobs and effective-dated rates, notifications, billing/subscription, export, consent management, per-schedule deletion, account deletion.

No special design treatment needed here beyond token compliance — these are utility screens, not hero moments. Resist the urge to make every screen "interesting."
