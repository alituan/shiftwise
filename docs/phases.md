# Development Phases

Work one phase at a time. Do not begin a later phase's work inside an earlier phase's PRs.

> **Stack migration in progress (2026-09-05):** `docs/decisions/0001-migrate-flutter-to-react-native-expo.md`. The phase progress notes below (marked "Progress") describe the **pre-migration Flutter implementation**, preserved as historical record — that code is being rewritten, not ported, on React Native/Expo. A new migration phase sequence (0: docs, 1: Expo scaffold + CI parity, 2: domain port, 3: auth/Firestore/rules port, 4: design tokens + screens, 5: scan pipeline) runs alongside/inside the phase numbers below; each migration step restarts the relevant phase's work on the new stack rather than resuming Dart code.

### Phase 0 — Evidence and decisions
Owner approves: segment, jurisdiction, currency, claims, AI-accuracy benchmark target, pay-calculation fixtures, retention policy, billing/merchant eligibility, unit economics.
**Exit:** assumptions documented in `docs/scope.md`; benchmark and hand-verified pay calculations exist as fixtures.

### Phase 1 — Manual core (no AI, no auth-required cloud sync yet)
Design tokens and theme (`docs/design/tokens.md`), app shell, `expo-router` setup, Schedule screen with manual shift CRUD, local-only (guest) mode, basic pay display, visual-snapshot baseline established.
**Exit:** manual flow works fully offline, on at least one real device per platform, no AI or cloud dependency.

> **Known-open (2026-09-04):** the real-device exit criterion is unmet — Phase 1 is verified in the sandbox web preview and the unit/widget/golden suite only. Closing it with a real-device or emulator smoke test is a merge precondition, tracked here so it isn't lost under Phase 2 work.

### Phase 2 — Auth and secure sync
Firebase Auth integration, Firestore model/rules/indexes (`docs/architecture/data-model.md`), Storage rules, emulator security tests, **offline conflict resolution** (`docs/architecture/offline-conflict-resolution.md` — this is the hard part, budget real time), account deletion/export skeleton.
**Exit:** hostile direct-SDK emulator tests fail closed; cross-device sync test (edit same shift on two simulated devices) passes without silent overwrite.

> **Progress (2026-09-04):** step 1 — Firebase Auth only (emulator-first) — complete; email verification surfaced but not blocking; OAuth deferred per `docs/scope.md`. Step 2 — Firestore model, deny-by-default Firestore/Storage rules, hostile direct-SDK emulator security tests (Node, `rules-tests/`), pure-Dart shift-document mapper — complete. Step 3 (2026-09-05) — `updatedBy` added to the shift schema; `writeShift` transactional Cloud Function (auto-merge, `CONFLICT(current)`, guarded deletes) with its emulator suite; shifts closed to direct client writes in the rules. Remaining in this phase: client sync wiring + conflict UX (the spec's client half) and account deletion/export. Real Firebase project and platform config files are still an owner action.

### Phase 3 — AI import
Full pipeline per `docs/architecture/ai-import.md`: crop/re-encode/consent UI, Cloud Function job creation, quota enforcement, upload, worker, schema validation, review UI, cleanup, benchmark validation against Phase 0 targets.
**Exit:** image-to-confirmed-shift flow has zero unreviewed writes and zero retry-duplication in testing.

> **Progress (2026-09-05):** step 1 — client-side preprocessing only — complete (PR #5): pick/camera → crop to the schedule row → EXIF stripped by re-encode → client validation → consent naming the AI processor → prepared-artifact state. No upload, no backend, no shift data. `aiProcessorName` in `lib/features/scan/scan_config.dart` is a placeholder until the owner selects the provider.
> Step 2 — `createParseJob` Cloud Function + quota enforcement — complete: one transaction reserves quota (`usage/{uid}_YYYY-MM`, free tier 5/month) and creates the job in `created` state; the client idempotency key IS the job id, so replays never double-charge; parallel callers serialize on the usage document (emulator-proven with genuinely concurrent test calls). Upload + Storage rules, worker, expiry sweeper/refunds, review UI, and client wiring remain — the scan screen stays inert until upload exists.

### Phase 4 — Production pay engine
Full implementation per `docs/architecture/pay-engine.md`: rates, breaks, timezone/DST handling, boundary logic, differentials, rounding, calculation explanations, user-configured concerns.
**Exit:** full boundary-condition test suite passes; every calculation exposes its inputs and rule version in the UI.

### Phase 5 — Billing
Per `docs/architecture/billing.md`: provider selection, hosted checkout, webhooks, reconciliation, entitlement writes, lifecycle tests (renewal/cancel/refund/grace), paywall UI, server-side enforcement test.
**Exit:** tampered/patched client build cannot unlock paid features in testing.

### Phase 6 — Notifications and Pro features
Local + FCM notifications with reschedule-on-change logic, multi-job support, exports, calendar integration — each shipped with a metric to validate it's used.
**Exit:** notification reschedule logic tested against schedule-change scenarios; every Pro feature has usage tracking.

### Phase 7 — Launch
Full accessibility pass, device/OS matrix testing, privacy/legal content finalized, real billing tests in production-adjacent environment, monitoring/budgets/kill-switches verified live, backup restore rehearsed, staged rollout plan, rollback plan.
**Exit:** `docs/release-gates.md` fully checked off.
