import { defineConfig } from 'vitest/config';

// Genuinely-parallel-call tests (quota/entitlement race tests) fire several
// concurrent Firestore transactions against the emulator; under CPU
// contention (e.g. a burstable sandbox) they can take 3-4s, close to
// Vitest's 5000ms default. Raised here so CI/sandboxes don't flake on
// timing alone -- these tests assert on outcome, not speed.
export default defineConfig({
  test: {
    testTimeout: 20000,
  },
});
