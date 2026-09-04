/// Seam over Firebase Auth so unit and widget tests never need the SDK or
/// an emulator (docs/testing.md — real flows run in the emulator suite).
library;

import 'package:shiftwise/features/auth/auth_models.dart';

abstract class AuthGateway {
  /// Emits the signed-in user, or null when in guest mode.
  Stream<AuthUser?> get authStateChanges;

  Future<AuthUser> signUp({required String email, required String password});

  Future<AuthUser> signIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> sendEmailVerification();

  Future<void> signOut();
}
