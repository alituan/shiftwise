/// Storage rules are deny-by-default until the Phase 3 AI-import pipeline
/// opens its scoped paths — prove the denial holds for authenticated and
/// unauthenticated clients alike, and that the harness itself works (the
/// rules-disabled context can upload), so failures are rule-driven.
import { beforeAll, afterAll, beforeEach, describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';

const rulesPath = fileURLToPath(
  new URL('../firebase/storage.rules', import.meta.url),
);
const rulesSource = readFileSync(rulesPath, 'utf8');

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-shiftwise',
    storage: { rules: rulesSource },
  });
});

afterAll(() => testEnv.cleanup());

beforeEach(() => testEnv.clearStorage());

describe('deny-by-default storage', () => {
  it('denies an authenticated upload', async () => {
    await assertFails(
      testEnv
        .authenticatedContext('alice')
        .storage()
        .ref('users/alice/scans/photo.jpg')
        .putString('bytes'),
    );
  });

  it('denies an authenticated download', async () => {
    await testEnv.withSecurityRulesDisabled((context) =>
      context
        .storage()
        .ref('users/alice/scans/photo.jpg')
        .putString('bytes'),
    );
    await assertFails(
      testEnv
        .authenticatedContext('alice')
        .storage()
        .ref('users/alice/scans/photo.jpg')
        .getDownloadURL(),
    );
  });

  it('denies an unauthenticated upload anywhere', async () => {
    await assertFails(
      testEnv.unauthenticatedContext().storage().ref('anything').putString('bytes'),
    );
  });

  it('harness control: rules-disabled context can upload', async () => {
    await testEnv.withSecurityRulesDisabled((context) =>
      context
        .storage()
        .ref('users/alice/scans/photo.jpg')
        .putString('bytes'),
    );
  });
});
