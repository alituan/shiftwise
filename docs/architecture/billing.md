# Billing & Entitlements

## Provider decision — not automatic

Do not default to Stripe without checking eligibility. Compare direct-processor eligibility, merchant-of-record alternatives, supported customer countries/currencies, payout support, subscription/refund/tax/invoice handling, webhook security, and total fees against your actual merchant country and business setup. Keep provider specifics behind an internal billing contract, not hardcoded assumptions in this doc.

## Trusted flow

```
App requests checkout
→ Cloud Function verifies user and approved price
→ provider-hosted checkout (never in-app custom payment UI)
→ authenticated webhook to a Cloud Function
→ idempotent event record written
→ provider reconciliation
→ Cloud Function writes entitlement
→ app reads entitlement (read-only)
```

**The React Native app never chooses an arbitrary price, never marks a purchase as successful client-side, and never writes entitlement state.** This is enforced by Firestore rules (`docs/architecture/data-model.md` — entitlements collection is server-owned) plus Cloud Functions re-verification, not just by the app's UI not offering the option.

Handle explicitly: purchase, renewal, expiry, cancellation, refund, failed payment, grace period (if the provider supports one), plan change, duplicate/out-of-order webhook events, and identity mapping between provider customer ID and Firebase UID.

## Entitlement document shape

```
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
```

Server-write only. The app's paywall UI explains access and gates *presentation* — actual enforcement lives in Firestore rules and Cloud Functions, so a tampered/patched client build cannot unlock paid features. Test this explicitly: attempt to bypass the paywall via direct Firestore calls in an emulator test, confirm it's denied.

## Tier boundaries

See `docs/scope.md` for what's free vs. Pro — this doc covers the mechanism, not the product tiers.
