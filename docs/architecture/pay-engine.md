# Pay Engine

## Scope

Calculate **estimated gross pay only.** Never imply take-home pay, tax withholding, or exact payroll accuracy anywhere — in code, copy, or marketing. Tips, bonuses, taxes, deductions, commissions, and employer adjustments are excluded until separately designed and approved.

## Money — non-negotiable

Use the `decimal.js` package or integer minor-units (cents) throughout. **Never a raw JS `number` for any currency value.** JavaScript's `number` is IEEE 754 binary float — `hours * rate` as raw numbers will eventually produce values like `$47.999999999996`. Write one `Money` wrapper type in `src/domain/money/` and route everything through it. Configure ESLint (a custom rule, e.g. `no-restricted-syntax`) to flag raw arithmetic operators on numeric currency values inside `domain/money/` and `domain/pay/`.

## Required inputs to any calculation

Currency, effective rate, pay-week start + timezone, paid/unpaid break minutes, overtime basis, differentials, supported premiums, rounding policy, overnight-shift attribution.

## Engine properties

- Pure and deterministic — same inputs always produce the same output, no hidden state, no wall-clock reads inside the calculation itself.
- Version every rate and every rule set applied. Store which version was used with each calculation snapshot (`docs/architecture/data-model.md`) so past pay estimates remain explainable even after rules change.
- Lives in `src/domain/pay/` — no React Native or Firebase imports. Testable as plain TypeScript.

## Required test cases

- Midnight and pay-week boundary crossings.
- Daylight-saving transitions: missing hour (spring forward) and repeated hour (fall back).
- Timezone changes mid-shift (e.g. user travels).
- Overlapping or split shifts.
- Missing shift end time.
- Invalid break configuration (break longer than shift, negative values).
- Mid-period rate changes (rate updated while a pay period is in progress).
- Deterministic recomputation — running the same snapshot inputs twice must produce identical output.

## Schedule concerns

Default concerns are **user-configured only**: rest interval below a threshold, overlapping shifts, weekly hours above a threshold, incomplete or unusually long shifts. Only a legally reviewed, versioned jurisdiction rule pack may describe an actual statutory rule — never invent or assume legal compliance logic without that review. Surface concerns as "possible schedule concern," never "violation."

## Display rules (ties to `docs/design/screens.md`)

The Pay screen always shows: hours, base estimate, applied differentials, and the rule/rate version used — full traceability, not just a final number.
