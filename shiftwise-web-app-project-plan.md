# ShiftWise Web — Production Project Plan

**Version:** 1.0 Web Edition  
**Status:** Implementation blueprint  
**Product:** Responsive AI-assisted shift schedule, hours, and estimated gross-pay web application  
**Relationship:** Web-specific counterpart to the approved ShiftWise mobile plan

> This is a real web application plan, not a landing-page mock-up. It preserves the approved privacy, AI reliability, pay-calculation, entitlement, security, and product-validation boundaries while replacing mobile-only technology with a responsive Next.js architecture.

---

## 1. Product Definition

ShiftWise Web helps hourly and irregular-hours workers answer:

1. When is my next shift?
2. How many hours am I scheduled to work?
3. What is my estimated gross pay under the rules I configured?

The core workflow is:

~~~text
Manual entry or cropped schedule image
→ reviewable draft
→ user verifies every imported shift
→ confirmed calendar
→ deterministic hours/pay calculation
→ optional schedule concerns
~~~

AI is only an input shortcut. It never becomes the source of truth and never writes directly to confirmed shifts.

### 1.1 Launch decisions required

Before implementation beyond the manual prototype, the owner must approve:

- One initial worker segment.
- One launch country and, when applicable, state or province.
- Supported currency.
- Week-start and timezone defaults.
- Whether concern rules are user-configured only or include a legally reviewed jurisdiction pack.
- Merchant country and billing-provider eligibility.

Do not claim global labor-law support. Use “estimated gross pay” and “possible schedule concern,” not exact payroll, take-home pay, or confirmed legal violation.

### 1.2 Product validation gate

Before public AI import:

- Interview at least 20 workers from the selected segment.
- Collect at least 100 permission-safe, labeled schedule images across at least 10 recurring layouts.
- Measure employee-row selection, shift precision/recall, date exact match, and start/end-time exact match.
- Reach the approved critical-field benchmark target; proposed initial gate: 98% exact match.
- Require explicit review regardless of benchmark result.
- Demonstrate that assisted import is materially faster than manual entry.
- Test pricing; do not treat any price as validated in advance.

These are internal release criteria, not public guarantees.

---

## 2. Web Product Scope

### 2.1 Free tier

- Manual shift creation and editing
- One job
- Today and week calendar
- Basic scheduled-hours totals
- Basic estimated gross-pay calculation
- Limited monthly AI imports
- Browser/local reminders where reliable
- Responsive desktop and mobile-browser support
- Installable PWA after the core web app is stable

### 2.2 Pro tier

- Higher or fair-use AI-import allowance
- Multiple jobs and combined calendar
- Advanced rate differentials
- Longer history and exports
- Calendar export
- Advanced configurable schedule concerns

Basic pay estimation remains free. The marginal-cost feature—AI parsing—is limited.

### 2.3 Explicitly deferred

- Employer/team accounts
- Shift swapping
- Payroll-provider integrations
- Taxes and take-home pay
- Global legal-rule coverage
- Unlimited free scanning
- Native mobile packaging
- Social/community features
- Decorative AI chat
- Deep analytics dashboards

---

## 3. Web Architecture

### 3.1 Approved stack

| Layer | Choice | Boundary |
|---|---|---|
| Framework | Next.js App Router + strict TypeScript | Use a current supported release; do not hard-pin this plan to a stale major |
| Rendering | Server Components for public/static content; Client Components for the authenticated app | Private data is never embedded in public HTML |
| Styling | Tailwind CSS with project-owned tokens | No generic default theme or unexplained one-off styling |
| Accessible primitives | Radix UI primitives, selectively wrapped | Build a ShiftWise system; do not ship default library appearance |
| Icons | Phosphor Icons for React | One icon system; icons never replace required text |
| Forms | React Hook Form + Zod | Shared validation contracts where practical |
| Calendar | Purpose-built ShiftWise components | Avoid a heavy scheduler until requirements prove it necessary |
| Authentication | Firebase Authentication | Email auth for MVP; Google may be added later |
| Database | Cloud Firestore | Offline cache, range queries, rules, bounded live updates |
| Files | Cloud Storage for Firebase | Private, short-lived schedule images |
| Trusted backend | Cloud Functions for Firebase, 2nd generation | AI jobs, billing, entitlements, deletion, exports |
| Async jobs | Cloud Tasks or Firebase task queues | Durable, idempotent parsing |
| AI | Server-side provider adapter | Strict schema; no provider key in browser |
| Billing | Adapter chosen after merchant eligibility review | Stripe is only a candidate, not an assumption |
| Hosting | Vercel for Next.js | Firebase services remain the trusted backend |
| PWA | Service worker after core flows pass | Never cache raw images or private API payloads |
| Monitoring | Sentry | Sensitive-value redaction required |
| Analytics | Privacy-minimized Firebase Analytics or approved equivalent | Event allowlist; no sensitive values |
| Testing | Vitest, Testing Library, Playwright, Firebase Emulator Suite, axe | Security/accessibility are CI gates |
| CI/CD | GitHub Actions + Vercel preview/production environments | Production deploys only from approved commits |

### 3.2 Rendering and security boundary

Public marketing/help content benefits from server rendering. Authenticated areas depend on Firebase Auth, Firestore listeners, offline cache, and browser file processing, so their interactive surfaces are Client Components.

Route guards improve UX but are not security. Firestore/Storage rules and authenticated functions enforce authorization even if the UI is bypassed. Private user data must not be placed in static generation, public caches, public metadata, or search-indexable HTML.

### 3.3 Repository structure

~~~text
/
├── src/
│   ├── app/
│   │   ├── (marketing)/
│   │   ├── (auth)/
│   │   ├── app/{schedule,scan,pay,jobs,settings}/
│   │   ├── legal/
│   │   ├── help/
│   │   ├── layout.tsx
│   │   ├── robots.ts
│   │   └── sitemap.ts
│   ├── components/{ui,calendar,forms,feedback}/
│   ├── features/{auth,jobs,shifts,scan,pay,billing,privacy}/
│   ├── lib/{firebase,analytics,monitoring,browser}/
│   ├── domain/{money,time,pay,concerns}/
│   ├── contracts/
│   └── styles/
├── functions/
│   └── src/{callable,http,workers,billing,privacy,observability}/
├── firebase/{firestore.rules,firestore.indexes.json,storage.rules}
├── tests/{e2e,fixtures,security,accessibility}/
├── docs/{decisions,privacy,runbooks}/
├── docs/threat-model.md
├── public/{icons,manifest.webmanifest,safe-static-assets}/
├── AGENTS.md
└── PROJECT_PLAN.md
~~~

Time and money logic remains pure and independent of React, Firestore, and UI components.

### 3.4 Environments

Maintain separate development, staging, and production:

- Firebase projects and buckets
- Vercel projects/environments
- App Check configuration
- AI keys and budgets
- Billing test/live credentials and webhooks
- Sentry environments
- Analytics streams
- Domains and allowed origins

Secrets belong in Vercel encrypted configuration, Firebase Secret Manager, or approved CI secrets. Never expose admin credentials through browser-visible environment variables.

---

## 4. Responsive Information Architecture

### 4.1 Public routes

~~~text
/
/features
/pricing
/privacy
/terms
/help
/login
/signup
~~~

### 4.2 Private routes

~~~text
/app/schedule
/app/schedule/[shiftId]
/app/scan
/app/pay
/app/jobs
/app/settings/profile
/app/settings/notifications
/app/settings/subscription
/app/settings/privacy
~~~

Private routes use noindex metadata and never appear in the public sitemap.

### 4.3 Desktop

Use a restrained three-region workspace:

~~~text
Fixed left navigation
Main schedule/pay workspace
Context panel for selected day or shift
~~~

- Left navigation: Schedule, Scan, Pay, Settings.
- Main workspace: week calendar by default.
- Context panel: next shift, selected shift, concern explanation, or edit form.
- Do not turn every element into a floating card.
- Give the calendar the largest area.

### 4.4 Tablet

- Collapsible navigation rail.
- Calendar remains primary.
- Context panel becomes a sheet or split pane based on width.
- Touch and pointer interactions both work.

### 4.5 Mobile web/PWA

- Compact header with date/week controls.
- Bottom navigation: Schedule, Scan, Pay, Settings.
- Day-focused default with horizontal week strip.
- Shift detail/edit opens as a bottom sheet or full route.
- File capture uses camera/file picker with manual upload fallback.
- No hover-only interaction.

### 4.6 Core screens

#### Schedule

- Current day and next shift are immediately visible.
- Week navigation and quick manual entry.
- Day cells show time, job marker, and concern marker.
- Defined empty, loading, offline, sync, and error states.

#### Scan

- Camera/file selection.
- Crop to the user’s own row.
- Privacy warning and AI consent.
- Local preview and quality checks.
- Explicit uploading, queued, processing, review, and failed states.
- Side-by-side crop/result on wide screens; sequential review on narrow screens.

#### Pay

- “Estimated gross pay” everywhere.
- Hours, base estimate, supported differentials, and rule explanation.
- Calculation inputs and rule version.
- No tax/take-home estimate unless separately implemented.

#### Settings

- Profile, locale, timezone, week start.
- Jobs and effective-dated rates.
- Notifications and billing.
- Export, consent, per-schedule deletion, account deletion, support.

---

## 5. Visual and Interaction System

ShiftWise is calm, high-trust, and utilitarian. Avoid generic SaaS gradients, glass effects, giant empty heroes, excessive rounded cards, and decorative animation.

| Role | Token | Initial value |
|---|---|---|
| Ink | --color-ink | #12161C |
| Surface | --color-surface | #F7F8FA |
| Primary | --color-primary | #3D5A80 |
| Concern | --color-warning | #E8590C |
| Confirmation | --color-success | #2F9E44 |

Define foreground pairs, hover/focus/pressed/disabled states, borders, spacing, type scale, elevation, and motion. Color is never the only status indicator.

### 5.1 Typography and data

- One legible sans-serif.
- Tabular numerals for time, hours, and money.
- Left-aligned body text.
- Plain labels such as “Confirm 6 shifts.”
- Locale-aware date, time, number, and currency formatting.
- Never format currency with string concatenation.

### 5.2 Accessibility

Target WCAG 2.2 AA:

- Semantic headings and landmarks
- Keyboard access to every action
- Visible focus
- Logical focus after dialogs/routes
- Accessible names for icon buttons
- At least 4.5:1 normal-text contrast
- Reduced motion
- No color-only states
- Restrained parse-progress announcements
- Error summaries linked to fields
- Mobile-sized touch targets
- 200% zoom/text support
- Automated axe checks plus manual keyboard/screen-reader tests

---

## 6. Authentication and Browser State

### 6.1 MVP auth

- First-party email sign-up/sign-in.
- Email verification where risk policy requires it.
- Password reset.
- Optional local guest use for manual schedules.
- Authenticated account required for cloud sync, AI, billing, export, and cross-device history.

Google login may be added only after onboarding evidence supports it.

### 6.2 Authority

- Firebase ID tokens authenticate Firestore, Storage, and callable functions.
- Rules remain authoritative for direct browser SDK calls.
- App Check protects supported Firebase resources.
- Functions re-check UID, entitlement, job ownership, quota, and schema.
- Never trust UID, entitlement, price, rate, or path submitted by the browser.
- Next.js middleware is never the only private-data protection.

### 6.3 Browser storage

- Keep sensitive state out of localStorage.
- Use Firebase persistence deliberately.
- Clear user-scoped caches on logout.
- Warn about unsynced changes.
- Never store secrets or privileged tokens in IndexedDB, localStorage, service-worker caches, or bundles.

---

## 7. Firestore Model

~~~text
/users/{uid}                              # validated profile
/users/{uid}/jobs/{jobId}
/users/{uid}/jobs/{jobId}/rateVersions/{rateId}
/users/{uid}/shifts/{shiftId}
/users/{uid}/parseJobs/{parseJobId}        # readable; server controls authority
/users/{uid}/calculationSnapshots/{id}     # server-owned
/entitlements/{uid}                        # server-owned
/usage/{uid_period}                        # server-owned
/rulePacks/{jurisdiction_ruleVersion}      # admin/server-owned
/webhookEvents/{provider_eventId}          # server-only
~~~

### 7.1 Shift

~~~text
jobId
startUtc
endUtc
timeZone
localWorkDate
role
location
paidBreakMinutes
unpaidBreakMinutes
source: manual | scanned
sourceParseJobId
reviewStatus: confirmed
revision
createdAt
updatedAt
~~~

Require end after start, IANA timezone, owned job, overnight support, server audit timestamps, known fields/types only. Derive upcoming/completed rather than storing stale status.

### 7.2 Queries

- Query visible range plus small prefetch.
- Unsubscribe on route/range change.
- Paginate history.
- Add indexes from actual queries.
- Never listen to all history.
- Run large exports as bounded server jobs.

### 7.3 Client-prohibited writes

- Entitlements
- Usage counters
- Billing/webhook records
- Authoritative parse transitions
- Calculation snapshots
- Published rule packs

Tests must prove denial through direct Firebase calls, not hidden UI.

---

## 8. Image Handling and AI Jobs

### 8.1 Browser preprocessing

Before upload:

- Crop to the user’s own row.
- Re-encode to remove EXIF/location metadata.
- Validate type, size, dimensions, pixel count.
- Offer blur/contrast/readability guidance.
- Show the exact outgoing crop.
- Obtain explicit third-party AI consent.

Client processing improves privacy and speed but is not trusted security validation. The backend repeats validation.

### 8.2 Secure flow

~~~text
Request parse job
→ verify Auth, App Check, entitlement, quota
→ reserve quota and create job transactionally
→ upload only to authorized private path
→ validate object and queue task
→ idempotent worker calls AI
→ strict schema validates response
→ write reviewable draft
→ user edits and confirms
→ commit confirmed shifts
→ delete input
~~~

### 8.3 States

~~~text
created → uploaded → queued → processing → review_required → confirmed
                                      └──→ failed
created/uploaded/failed → expired
~~~

Store UID, object hash/path, timestamps, idempotency key, attempt/lease data, provider/model/prompt/schema versions, safe error, quota state, duration/cost, draft reference, expiry, and deletion state.

Retries never duplicate shifts, quota consumption, or drafts.

### 8.4 AI rules

- Treat image text as untrusted data, not instructions.
- Require an allowlisted schema.
- Reject unexpected fields and invalid dates/times.
- Track uncertainty per field.
- Do not trust model self-confidence.
- Never write directly to confirmed shifts.
- Require confirmation for every import.
- Never fabricate unreadable fields.
- Always provide manual entry.

---

## 9. Pay and Schedule Concerns

- Calculate estimated gross pay only.
- Use fixed-point integers or decimal arithmetic, never binary floating-point money.
- Define rounding policy and stage.
- Version rates and rules.
- Preserve calculation inputs and version.
- Keep the engine pure and deterministic.

Required inputs: currency, effective rate, pay-week start/timezone, paid/unpaid breaks, overtime basis, differentials, supported premiums, rounding, and overnight attribution.

Test midnight/week boundaries, daylight-saving missing/repeated hours, timezone changes, overlaps/split shifts, missing end, invalid breaks, mid-period rate changes, and deterministic recomputation.

Tips, bonuses, taxes, deductions, commissions, and employer adjustments remain excluded until designed.

Default concerns are user-configured: rest interval below threshold, overlaps, weekly hours above threshold, and incomplete/unusually long shifts. Only a reviewed/versioned jurisdiction pack may describe statutory rules.

---

## 10. Billing and Entitlements

### 10.1 Provider decision

Do not automatically select Stripe. Merchant availability, payouts, currencies, taxes, and business-country eligibility differ. Compare:

- Direct processor eligibility
- Merchant-of-record alternative
- Customer countries/currencies
- Payout support
- Subscription/refund/tax/invoice requirements
- Webhook security and reconciliation
- Total fees and operational burden

Keep provider details behind internal billing contracts.

### 10.2 Trusted flow

~~~text
Browser requests checkout
→ backend verifies user and approved price
→ provider-hosted checkout
→ authenticated webhook
→ idempotent event record
→ provider reconciliation
→ server writes entitlement
→ client reads entitlement
~~~

The browser never chooses arbitrary price, marks success, or writes entitlement. Handle purchase, renewal, expiry, cancellation, refund, failure, grace period if supported, plan change, duplicates/out-of-order events, and identity mapping.

### 10.3 Entitlement

~~~text
active
provider
customerId
productId
environment
expiresAt
willRenew
billingState
lastProviderEventId
verifiedAt
updatedAt
~~~

Server-write only. UI gates explain access; backend/rules enforce it.

---

## 11. Offline and PWA

### 11.1 Offline baseline

- Cached confirmed shifts stay viewable.
- Manual drafts work offline.
- Pending writes show sync state.
- AI clearly requires connectivity.
- Interrupted upload restarts/resumes without duplicate jobs.
- Conflicts use revision and updatedAt; never silently overwrite newer data.

### 11.2 PWA rules

Add installability only after responsive core flows are stable:

- Valid manifest/icons
- HTTPS
- App-shell/static caching
- Versioned cache migration
- Offline fallback
- Update-available UX

Never service-worker-cache raw images, private HTML/data, Firestore responses, billing data, tokens, or AI payloads. Browser notifications are progressive enhancement; in-app next-shift visibility must work without them.

---

## 12. Web Security

### 12.1 Controls

- Deny-by-default Firestore/Storage rules
- Auth/App Check on private and costly operations
- Client and server schema validation
- Per-user/global AI budgets
- Atomic quota reservation/consumption/refund
- Least-privilege service accounts
- Secret Manager
- Strict origins/CORS
- Content Security Policy and HSTS
- Clickjacking protection
- Bounded image processing
- Dependency and secret scanning
- Redacted logs
- Backup/restore tests
- AI and billing kill switches

### 12.2 Threat model

Cover XSS, compromised dependencies, CSRF for any cookie endpoint, stolen tokens, shared-device/browser-extension leakage, modified clients, valid-App-Check abuse, AI-cost attacks, image prompt injection, malformed images, cross-user access, billing spoofing, webhook replay, service-worker leakage, private server-rendered HTML, analytics/log leakage, and deletion/backups.

Define/test security headers centrally. CSP uses only required origins; broad wildcards and unsafe directives require a documented, narrow exception.

---

## 13. Privacy and Retention

### 13.1 Controls

- Crop before upload.
- Show exactly what leaves the device.
- Name AI processor and purpose.
- Record consent version/time.
- Permit manual use without AI.
- Provide schedule deletion, export, consent withdrawal, and account deletion.

### 13.2 Recommended retention

| Data | Default |
|---|---|
| Raw cropped image | Delete after confirmation; otherwise within 24 hours after processing/failure |
| Working image | Delete immediately after parsing |
| Abandoned draft | Delete after 30 days |
| Confirmed shifts | Until user deletion/history removal |
| Pay snapshots | Until deletion/product history limit |
| Security logs | Minimum necessary; never schedule content |
| Deleted backup data | Disclose maximum backup expiration |

Account deletion covers Auth, Firestore, Storage, notification subscriptions, calculations, parse jobs, billing linkage where legally possible, and provider identifiers. Document financial/fraud retention exceptions.

Never send names, emails, schedule text, exact shift times, pay values, image paths/crops, tokens, or provider payloads to analytics or error monitoring.

---

## 14. SEO, AEO, and Discoverability

Only public pages are indexable:

- Unique titles/descriptions.
- Canonical URLs.
- Public-only sitemap.
- Noindex on auth/private routes.
- Truthful structured data matching visible content.
- Fast public pages with minimal client JavaScript.
- Accessible FAQ based on actual behavior.
- Clear privacy and AI-processing explanations.
- Safe Open Graph assets.
- Semantic, crawlable copy.

Never expose schedules for SEO, generate thin location pages, invent testimonials, or make unverified accuracy/legal claims.

---

## 15. Development Phases

### Phase 0 — Evidence and decisions

Approve segment, jurisdiction, currency, claims, benchmark, pay fixtures, retention, merchant country, billing criteria, and unit economics.

**Exit:** assumptions are visible; benchmark and hand calculations exist.

### Phase 1 — Manual responsive utility

Build foundation, tokens, public shell, app shell, responsive Schedule views, one job, manual shifts, basic pay, offline drafts, and accessibility.

**Exit:** manual flow works on mobile, tablet, and desktop without AI.

### Phase 2 — Auth and secure sync

Implement email auth, optional guest migration, Firestore model/indexes/rules, Storage rules, emulator tests, sync, deletion/export skeleton, redaction, and environments.

**Exit:** hostile direct-SDK tests fail closed; cross-device sync avoids silent overwrite.

### Phase 3 — AI import

Implement crop/re-encode/consent, jobs, quota, upload, queue/worker, schema, review, cleanup, benchmark, and cost/latency monitoring.

**Exit:** image-to-confirmed-shifts has no unreviewed writes or retry duplication.

### Phase 4 — Production pay

Implement rates, breaks, timezone/DST, boundaries, differentials, rounding, explanations, user concerns, and reviewed packs only.

**Exit:** tests match approved fixtures and expose inputs/versions.

### Phase 5 — Billing

Select eligible provider; implement hosted checkout, webhooks, reconciliation, entitlements, lifecycle tests, paywall, and enforcement.

**Exit:** browser tampering cannot unlock data or operations.

### Phase 6 — PWA/evidence-backed features

Add safe installability, multi-job, exports, calendar integration, and notifications only with evidence.

**Exit:** cache/privacy tests pass and every feature has a metric.

### Phase 7 — Launch

Complete accessibility, browser/device matrix, privacy/legal content, real billing tests, monitoring/budgets/runbooks, backup restore, staged rollout, and rollback.

**Exit:** Section 17 passes.

---

## 16. Testing and CI

| Layer | Coverage |
|---|---|
| Domain | Vitest: time, money, breaks, rounding, rate versions, concerns |
| Properties | Nonnegative duration/pay, deterministic recomputation, interval validity |
| Components | Testing Library: forms, calendar, uncertainty, paywall, errors |
| Contracts | API/AI schema acceptance and rejection |
| Security | Firebase emulators: auth, cross-user, privileged, malformed writes |
| Functions | Quota, transitions, retry, cleanup, billing reconciliation |
| E2E | Playwright: auth, shift, scan review, offline recovery, billing, deletion |
| Accessibility | axe plus manual keyboard/screen-reader review |
| Responsive | Mobile, tablet, laptop, wide desktop, zoom/text scaling |
| Browser | Supported Chromium, Firefox, Safari/WebKit, mobile browsers |

Every pull request runs typecheck, lint/format, unit/component/contract tests, emulator rules tests, critical Playwright tests, accessibility checks, secret scanning, approved dependency review, and production build.

Vercel previews use non-production services and synthetic data. Production deploys require approved commits and passing checks.

---

## 17. Release Gates

- [ ] Segment, jurisdiction, currency, and claims approved
- [ ] Merchant/payment-provider eligibility verified
- [ ] Parsing benchmark meets target
- [ ] Every import requires confirmation
- [ ] Cross-user/privileged tests pass
- [ ] Pay time/break/rounding/rate suites pass
- [ ] AI tasks and billing webhooks are idempotent
- [ ] Raw-image cleanup verified
- [ ] Export/account deletion tested
- [ ] Offline and interrupted upload recovery tested
- [ ] Responsive matrix passes
- [ ] WCAG 2.2 AA audit completed for core flows
- [ ] CSP/security headers verified
- [ ] Private routes excluded from indexing/sitemap
- [ ] Service worker contains no private cached data
- [ ] Budgets/kill switches tested
- [ ] Privacy policy matches behavior
- [ ] Backup restore rehearsed
- [ ] Monitoring/runbooks active

---

## 18. Coding-Agent Governance

Maintain PROJECT_PLAN.md, AGENTS.md, CHANGELOG.md, docs/decisions, and docs/threat-model.md.

The agent must implement one approved phase at a time, state assumptions, ask before architectural/provider/security/privacy/monetization changes, preserve strict TypeScript/shared schemas, add tests, use Firebase emulators, and report files, migrations, tests, failures, and risks.

The agent must not treat AI output as confirmed; make the browser authoritative for entitlements, quota, calculations, or parse state; grant broad access; cache private data in a service worker; expose secrets to the client; add unjustified libraries; weaken tests; or introduce global legal claims without approved rule packs.

Done means criteria pass, success/failure/abuse/retry paths are tested, typecheck/lint/build pass, no sensitive fixtures exist, responsive/accessibility/offline behavior is handled, decisions/docs are updated, and the commit is focused.

---

## 19. Final Product Standard

The web release succeeds only if:

- Manual scheduling remains dependable without AI.
- Import saves measurable time.
- Users approve every extracted shift.
- Pay calculations are deterministic and explainable.
- Mobile web is not a squeezed desktop interface.
- Private data never leaks into HTML, logs, analytics, indexing, or caches.
- Billing and entitlements remain server-authoritative.
- The app degrades safely during AI, network, and billing outages.

Anything less is a polished demo, not a trustworthy production web application.
