/// Auth session state. Guest mode is the default and stays fully usable —
/// auth is additive, not a gate (docs/architecture/sync-and-auth.md).
///
/// Manual providers (not codegen) so tests override the gateway seam
/// directly: `authGatewayProvider.overrideWithValue(fakeGateway)`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shiftwise/features/auth/auth_gateway.dart';
import 'package:shiftwise/features/auth/auth_models.dart';
import 'package:shiftwise/features/auth/firebase_auth_gateway.dart';

final authGatewayProvider = Provider<AuthGateway>(
  (ref) => FirebaseAuthGateway(),
);

/// Live signed-in user, or null in guest mode.
final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authGatewayProvider).authStateChanges,
);

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref.watch(authGatewayProvider)),
);

class AuthController {
  AuthController(this._gateway);

  final AuthGateway _gateway;

  /// Creates the account (Firebase signs it in) and sends the verification
  /// email. Verification is best-effort at sign-up and never blocks
  /// sign-in — the account sheet keeps a resend action.
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    final user = await _gateway.signUp(email: email, password: password);
    try {
      await _gateway.sendEmailVerification();
    } on AuthFailure {
      // Surfaced later via the sheet's resend action.
    }
    return user;
  }

  Future<AuthUser> signIn({required String email, required String password}) =>
      _gateway.signIn(email: email, password: password);

  Future<void> sendPasswordReset(String email) =>
      _gateway.sendPasswordReset(email);

  Future<void> sendEmailVerification() => _gateway.sendEmailVerification();

  /// Sign-out intentionally keeps guest shifts: nothing account-scoped
  /// exists yet. Clearing user caches (and the unsynced-changes warning)
  /// belongs to the sync step per sync-and-auth.md.
  Future<void> signOut() => _gateway.signOut();
}
