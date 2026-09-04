# Threat Model & Security Controls

## Why this matters more in a client-only Flutter app

There is no server-rendered layer between the app and Firebase. Firestore/Storage rules plus Cloud Functions are the *entire* security boundary — not one layer among several. A hole in the rules is directly exploitable by anyone who inspects the app's Firebase config (which is not secret) and issues direct SDK calls.

## Controls

- Deny-by-default Firestore/Storage rules.
- Auth + App Check required on private and cost-incurring operations.
- Client and server schema validation (client for UX speed, server as the actual gate).
- Per-user and global AI budgets, enforced server-side.
- Atomic quota reservation/consumption/refund (no race condition allowing quota bypass via concurrent requests).
- Least-privilege service accounts for Cloud Functions.
- Secrets in Firebase Secret Manager or CI secrets — never in the Flutter app bundle, never in `--dart-define` values that end up in a shipped binary if they're sensitive.
- Redacted logs — never log schedule content, pay values, or tokens.
- Backup/restore tested, not assumed to work.
- AI and billing kill switches — a remote-config-driven way to disable AI import or billing calls in an incident without an app store release cycle.

## Threats to explicitly test against

Compromised dependencies, stolen/leaked Firebase tokens, shared-device data leakage, modified/tampered app builds (e.g. rooted device, patched APK), valid-App-Check-but-malicious-client abuse, AI-cost attacks (spamming parse requests), image prompt injection, malformed images, cross-user data access attempts, billing spoofing, webhook replay attacks, local cache/storage leakage on shared devices, log/crash-report leakage of sensitive fields, deletion/backup edge cases.

## Testing requirement

Firestore/Storage rule changes require an emulator test proving the intended denial/allow behavior, in the same commit as the rule change — see `docs/testing.md`. Tests must prove denial through direct Firebase SDK calls (bypassing the app UI entirely), not just confirm the UI doesn't expose a forbidden action.
