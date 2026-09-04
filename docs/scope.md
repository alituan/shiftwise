# Scope & Tier Boundaries

## Free tier

- Manual shift creation and editing.
- One job.
- Today and week calendar views.
- Basic scheduled-hours totals.
- Basic estimated gross-pay calculation.
- Limited monthly AI imports.
- Local/scheduled reminders (`flutter_local_notifications`).
- Installable as a real app on iOS/Android (this replaces the original web plan's "PWA" tier gate — native install is available from day one, not gated behind stability milestones the way a PWA manifest was).

## Pro tier

- Higher or fair-use AI-import allowance.
- Multiple jobs with a combined calendar view.
- Advanced rate differentials.
- Longer history retention and exports.
- Calendar export (ICS or platform calendar integration).
- Advanced configurable schedule concerns.

Basic pay estimation stays free in both tiers — the AI-import allowance is the metered/paid dimension, since that's the feature with real marginal cost (AI provider calls).

## Explicitly deferred (do not build without an explicit scope change)

- Employer/team accounts.
- Shift swapping between workers.
- Payroll-provider integrations.
- Taxes and take-home pay calculation.
- Global legal-rule coverage (only reviewed, versioned jurisdiction packs — see `docs/architecture/pay-engine.md`).
- Unlimited free AI scanning.
- Social/community features.
- Decorative AI chat interface.
- Deep analytics dashboards.

## Hard content/claims rules

- Never claim global labor-law support.
- Use "estimated gross pay" and "possible schedule concern" — never "exact payroll," "take-home pay," or "confirmed legal violation."
- These rules apply to UI copy, app store listing copy, and any marketing content equally.

## Launch decisions still required from the owner

Before implementation goes beyond the manual prototype: initial worker segment, launch country (and state/province if relevant), supported currency, week-start and timezone defaults, whether concern rules are user-configured-only or include a legally reviewed jurisdiction pack, and app-store/billing eligibility for the chosen accounts.
