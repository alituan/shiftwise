/// Real Firebase Auth SDK flows against the Auth emulator.
///
/// Run on a device or web target — NOT plain `flutter test`, which has no
/// Firebase platform channels:
///
///     firebase emulators:start --only auth
///     flutter test integration_test -d <device-id> \
///       --dart-define=USE_FIREBASE_EMULATOR=true
///
/// On web, use flutter drive (needs chromedriver) — see README. The whole
/// suite is hermetic against the emulator: it creates unique throwaway
/// accounts in demo-shiftwise, never a real project.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiftwise/features/auth/auth_models.dart';
import 'package:shiftwise/features/auth/firebase_auth_gateway.dart';
import 'package:shiftwise/shared/firebase/firebase_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late FirebaseAuthGateway gateway;

  setUpAll(() async {
    assert(
      useFirebaseEmulator,
      'Run with --dart-define=USE_FIREBASE_EMULATOR=true so these flows '
      'hit the emulator, never a real project.',
    );
    if (Firebase.apps.isEmpty) {
      await initializeFirebase();
    }
    gateway = FirebaseAuthGateway();
  });

  String uniqueEmail() =>
      'it-${DateTime.now().microsecondsSinceEpoch}@shiftwise.test';

  testWidgets('sign-up signs in unverified and verification sends', (
    tester,
  ) async {
    final email = uniqueEmail();
    final user = await gateway.signUp(email: email, password: 'hunter22');
    expect(user.email, email);
    expect(user.isEmailVerified, isFalse);
    await gateway.sendEmailVerification();
    await gateway.signOut();
    final back = await gateway.signIn(email: email, password: 'hunter22');
    expect(back.email, email);
  });

  testWidgets('wrong password maps to wrongCredentials', (tester) async {
    final email = uniqueEmail();
    await gateway.signUp(email: email, password: 'hunter22');
    await gateway.signOut();
    await expectLater(
      gateway.signIn(email: email, password: 'wrongpass'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.error,
          'error',
          AuthError.wrongCredentials,
        ),
      ),
    );
  });

  testWidgets('duplicate sign-up maps to emailInUse', (tester) async {
    final email = uniqueEmail();
    await gateway.signUp(email: email, password: 'hunter22');
    await gateway.signOut();
    await expectLater(
      gateway.signUp(email: email, password: 'hunter22'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.error,
          'error',
          AuthError.emailInUse,
        ),
      ),
    );
  });

  testWidgets('password reset email sends for existing account', (
    tester,
  ) async {
    final email = uniqueEmail();
    await gateway.signUp(email: email, password: 'hunter22');
    await gateway.signOut();
    await gateway.sendPasswordReset(email);
  });

  testWidgets('authStateChanges follows sign-in and sign-out', (tester) async {
    final email = uniqueEmail();
    await gateway.signUp(email: email, password: 'hunter22');
    final signedIn = await gateway.authStateChanges.first;
    expect(signedIn?.email, email);
    await gateway.signOut();
    expect(await gateway.authStateChanges.first, isNull);
  });
}
