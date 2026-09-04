# ShiftWise Flutter — Cross-Platform Architecture & Design Addendum

**Version:** 1.0 Flutter Edition
**Status:** Supersedes Section 3 (stack), Section 3.3 (repo structure), and Section 5 (visual system) of `shiftwise-web-app-project-plan.md`
**Everything else in the original doc** — Sections 6–19 (auth authority rules, Firestore model, AI job state machine, pay-engine rules, billing flow, security/privacy controls, phases, release gates) — **still applies.** Those are framework-independent architecture decisions. Do not relitigate them just because the frontend changed.

---

## 0. Decision: Flutter replaces the web plan, not alongside it

One person, five active projects (Murandasi, FinSave, Amarira Yange, Anatomy Insights, this). Two frontends against one backend means the pay-rounding logic, entitlement gates, and AI-import state machine all get written and maintained twice — once in TypeScript, once in Dart. That's how rounding bugs and entitlement-check drift happen: not from bad engineers, from the same rule existing in two places.

**Decision:** One Flutter codebase → iOS, Android, Web (as a secondary target, not primary), Desktop if ever needed. Firebase stays as-is (Auth, Firestore, Storage, Functions, FCM) — it's frontend-agnostic and FlutterFire is mature.

If you later need real SEO-indexed marketing pages, that's a *separate*, tiny static site (even plain HTML) — not a reason to bring back Next.js for the app itself.

---

## 1. UI/UX Design System

### 1.1 The actual brief, not the generic one

A shift worker opens this app to answer one of three questions, usually fast, often in bad conditions: end of a shift, half-asleep, glare on the screen, one thumb, spotty signal in a stockroom. The design has to survive that context, not look good in a portfolio screenshot. That reframes every decision below.

Reject by default: SaaS gradient washes, glass/blur cards, soft `rgba(0,0,0,.1)` shadow-on-everything, all-caps tracked-out labels, a monospace face for "that data feel." These read as generic dashboard, and a dashboard aesthetic actively fights the job this app does — dashboards reward lingering and exploring; this app rewards a 2-second glance and getting out.

### 1.2 Color — revised token set

Keep the bones of your original set (it was already restrained) but sharpen contrast and give status color real semantic weight since color is one of the few signals that survives a rushed glance.

| Role | Token | Value | Why |
|---|---|---|---|
| Ink (primary text) | `colorInk` | `#14171C` | Near-black, not pure black — softer on eyes at 6am |
| Surface | `colorSurface` | `#F6F5F2` | Warm off-white, not clinical `#FFFFFF` — reads calmer, less "hospital app" |
| Surface-dim (cards, recessed) | `colorSurfaceDim` | `#EAE8E3` | One step down, for day-cells and secondary panels |
| Primary (brand, CTAs) | `colorPrimary` | `#2B4C6F` | Deep slate-blue — trustworthy without being generic SaaS-blue (`#3D5A80` was too close to Stripe/Linear default) |
| Concern / warning | `colorConcern` | `#C4501C` | Burnt orange, not alarm-red — signals "look at this" not "emergency" |
| Confirmed / success | `colorConfirmed` | `#3A7D5C` | Muted forest green — calm confirmation, not neon |
| Critical (errors only) | `colorCritical` | `#B3261E` | Reserved *only* for destructive actions and hard failures — never reused for "concern" |

Rule: **concern ≠ error.** Your original plan already separates "possible schedule concern" from actual failures — the color system needs to reflect that distinction too, or users start ignoring warnings because they look identical to real errors.

Every status must also carry a non-color signal (icon + label), per your existing accessibility requirement — this isn't new, just restated: color-blind users and glare-washed screens both defeat color-only status.

### 1.3 Typography

One typeface family, two weights doing real work — not two families. Something with **excellent tabular figures**, since this app is 80% numbers (times, hours, money): **Inter** or **IBM Plex Sans** are both free, both built for exactly this (readable digits at small sizes, real tabular-nums support). Avoid anything geometric-trendy (no Poppins, no Circular) — those optimize for personality over legibility at 14sp on a scratched screen.

- Display / large numbers (next-shift countdown, pay total): Semibold, tabular figures forced on.
- Body / labels: Regular.
- Never more than 3 sizes visible on one screen. Resist the urge to add a fourth "just for this label."

### 1.4 Layout concept

```
Mobile (primary target)
┌─────────────────────────┐
│ ← Week strip (scroll) →  │  compact, always visible
├─────────────────────────┤
│                          │
│   NEXT SHIFT             │  <- the hero. Big. One glance answers Q1.
│   Tue · 2:00–10:00 PM    │
│   in 3h 12m               │
│                          │
├─────────────────────────┤
│  Today's hours: 8.0      │  secondary, smaller
│  Est. pay: $124.00       │
├─────────────────────────┤
│  [Day cells below, tap   │
│   to expand]             │
└─────────────────────────┘
  Schedule  Scan  Pay  Settings   <- bottom nav, thumb reach
```

The hero is not a marketing hero — it's the literal next-shift countdown, because that's the single most-asked question. This is the one place to spend visual boldness (larger type, primary color) — everything else stays quiet, per the restraint principle. Don't turn every day-cell into its own elevated card with a shadow; use hairline dividers and the surface-dim token for separation instead. Shadows-on-everything is exactly the generic-SaaS tell to avoid.

Desktop/tablet (secondary target if you build Flutter web) can reuse the three-region layout from the original plan (nav / workspace / context panel) — that structure isn't framework-specific.

### 1.5 Motion

One deliberate motion, not motion-on-every-card. Candidate for the "one orchestrated moment": when a shift moves from `review_required` → `confirmed` during AI import, a single satisfying confirm animation (checkmark draw-in, not a bounce-fest) — because that's the moment of trust-transfer from AI-suggestion to user-owned data, and it's worth marking. Everything else (list scroll, nav transitions) uses platform-standard Flutter transitions — don't hand-roll custom page transitions everywhere, that's effort spent on the wrong thing.

Respect reduced-motion OS setting (`MediaQuery.disableAnimations` in Flutter) — same requirement as the original WCAG 2.2 AA target, just implemented via Flutter's accessibility API instead of `prefers-reduced-motion`.

### 1.6 Writing / microcopy

Same rules as the original doc's copy guidance, restated for app context:
- Buttons say the action: "Confirm 6 shifts," not "Submit." "Add job," not "Create."
- Empty schedule state: "No shifts yet — add one or scan a schedule photo," not a mascot illustration with no path forward.
- Errors state what happened and what to do: "Couldn't upload — check your connection and try again," never "Something went wrong."
- Never say "take-home pay" or imply tax accuracy — same constraint as the original doc, Section 1.1. This is a hard content rule, not a style preference.

---

## 2. Flutter Stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter (stable channel), Dart with sound null safety | Cross-platform from one codebase |
| State management | **Riverpod** (`flutter_riverpod` + `riverpod_generator`) | Testable, compile-safe DI, scales past Provider's boilerplate; avoid Bloc unless you have team members who already know it — Riverpod is the better solo-dev default |
| Backend | Firebase: Auth, Cloud Firestore, Cloud Storage, Cloud Functions (2nd gen), FCM | Unchanged from original plan — framework-agnostic |
| Local persistence | Firestore offline cache (built-in) + `Isar` or `Hive` only if you need structured local-only data (draft state, unsynced edits queue) beyond what Firestore cache gives you | Don't reach for a second local DB unless Firestore's cache genuinely can't cover the need — extra persistence layer is extra sync-bug surface |
| Money | `decimal` package — never raw `double` for currency | Same reasoning as original doc's floating-point ban, Dart has the identical footgun |
| Forms/validation | `flutter_form_builder` + custom validators mirroring the same schema rules as your Cloud Functions (keep validation logic conceptually shared even if not literally shared code) | |
| Push notifications | `firebase_messaging` (remote) + `flutter_local_notifications` (scheduled local reminders that work offline) | Use local notifications for "shift starts in 30 min" (deterministic, no connectivity needed); use FCM only for server-triggered alerts (e.g., AI import finished) |
| Image handling | `image_picker` (camera/gallery) + `image_cropper` (crop to user's row) + `image` package (re-encode, strip EXIF) | Replicates the browser crop/re-encode pipeline from Section 8.1 of the original plan |
| Routing | `go_router` | Declarative, supports deep links and route guards consistently across platforms |
| Testing | `flutter_test`, `mocktail`, `firebase_emulator` integration tests, `golden_toolkit` for visual regression on the design system | Golden tests matter here specifically because you're investing real design effort — protect it from silent drift |
| CI/CD | GitHub Actions (`flutter test`, `flutter analyze`, build for each platform) + Codemagic or Fastlane for store deploys | |
| Monitoring | Firebase Crashlytics + Sentry (Flutter SDK) if you want redaction parity with the original plan | |

### 2.1 What does NOT change from the original doc

- Firestore data model (Section 7) — identical, it's backend, not frontend.
- AI job state machine (Section 8.2/8.3) — identical.
- Billing trusted-flow (Section 10.2) — identical; the browser-never-writes-entitlement rule becomes app-never-writes-entitlement, same enforcement via Cloud Functions.
- Pay engine rules (Section 9) — identical logic, reimplemented in Dart with `decimal` instead of TypeScript with fixed-point/decimal.
- Security posture (Section 12) — Firestore/Storage rules are now your **only** security boundary (no server-rendered app to add defense-in-depth), so treat rules-testing as higher priority, not equal priority, versus the web plan.

---

## 3. Repository Structure

```
/
├── lib/
│   ├── main.dart
│   ├── app/                          # app-level: routing, theme, DI setup
│   │   ├── router.dart
│   │   ├── theme/
│   │   │   ├── tokens.dart           # color/type/spacing tokens from Section 1
│   │   │   └── theme.dart
│   │   └── app.dart
│   ├── features/
│   │   ├── auth/
│   │   ├── schedule/                 # calendar views, shift CRUD
│   │   ├── scan/                     # camera, crop, AI import review flow
│   │   ├── pay/                      # pay estimate display
│   │   ├── jobs/                     # job/rate management
│   │   ├── settings/
│   │   └── billing/
│   │       └── {data,domain,presentation}/   # each feature: repository, models, providers, screens/widgets
│   ├── domain/                       # framework-free core logic
│   │   ├── money/                    # decimal-based Money type, currency formatting
│   │   ├── time/                     # timezone, DST, shift-boundary logic
│   │   ├── pay/                      # pure pay-calculation engine
│   │   └── concerns/                 # schedule-concern rule evaluation
│   ├── shared/
│   │   ├── widgets/                  # design-system components (buttons, day-cell, status chips)
│   │   └── firebase/                 # Firestore/Storage/Functions client wrappers
│   └── l10n/                         # locale-aware date/time/currency formatting
├── functions/                        # unchanged from original plan — Cloud Functions, Node/TS
│   └── src/{callable,http,workers,billing,privacy,observability}/
├── firebase/{firestore.rules,firestore.indexes.json,storage.rules}
├── test/
│   ├── domain/                       # pure unit tests: money, time, pay, concerns
│   ├── features/
│   ├── golden/                       # visual regression for design system
│   └── integration/                  # Firebase emulator + widget integration
├── docs/{decisions,privacy,runbooks}/
├── docs/threat-model.md
├── docs/design-system.md             # source of truth for tokens, screenshots of each state
├── assets/{icons,fonts}/
├── AGENTS.md
└── PROJECT_PLAN.md
```

**Key discipline carried over from the original doc:** `domain/` stays pure Dart — no Flutter widget imports, no Firebase imports. Same reasoning as the original plan's "time and money logic remains pure and independent of React/Firestore" — this is what makes the pay engine unit-testable without spinning up emulators for every test run, and it's identical in Flutter.

---

## 4. AGENTS.md guidance for Claude Code workspace

Add these Flutter-specific rules on top of the original Section 18 governance rules (which still apply: one phase at a time, state assumptions, ask before architecture changes, no unjustified libraries, no weakened tests):

- Never write currency math with `double`. `flutter analyze` should be configured to flag raw `double` arithmetic in `domain/money/` and `domain/pay/` — treat this as a lint-enforced rule, not a reminder in a doc.
- Every new widget touching color must reference `theme/tokens.dart` — no inline hex values in feature code. This is how the design system stays coherent as the agent adds screens over many sessions.
- Any screen showing a status (confirmed, concern, failed, syncing) must render both a color and a non-color signal (icon or label) — reject any implementation missing one.
- Firestore/Storage rule changes require a corresponding emulator test in the same commit — no exceptions, since rules are the only security boundary in a client-only app.
- Before adding any new local persistence (Isar/Hive/SharedPreferences beyond trivial flags), confirm Firestore's offline cache genuinely can't cover the case — default answer is no, don't add it.

---

## 5. What I'd stress-test next, if you want to keep going

1. **Offline conflict resolution** — the revision/updatedAt comparison logic from Section 11.1 needs an actual design doc with test cases (same-shift edited on two devices, one offline) before any UI gets built around it. This is the highest-risk piece of the whole app and it's currently one paragraph.
2. **Push notification scheduling logic** — when an AI-imported schedule changes a shift time, do previously-scheduled local notifications get cancelled and rescheduled? If not designed explicitly, users get reminders for shifts that no longer exist at that time.
3. **Design system golden-test baseline** — set this up in Phase 1, not after the fact, or visual drift creeps in silently across a long multi-session Claude Code build.

Say the word and I'll draft #1 (offline conflict resolution) as its own short spec — that's the piece most likely to bite you if it's hand-waved.
