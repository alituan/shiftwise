/// Firebase Auth implementation of the gateway.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shiftwise/features/auth/auth_gateway.dart';
import 'package:shiftwise/features/auth/auth_models.dart';

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway([FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<AuthUser?> get authStateChanges => _auth.authStateChanges().map(
    (user) => user == null ? null : _toAuthUser(user),
  );

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAuthUser(credential.user!);
    } on FirebaseAuthException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAuthUser(credential.user!);
    } on FirebaseAuthException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthUser _toAuthUser(User user) => AuthUser(
    uid: user.uid,
    email: user.email ?? '',
    isEmailVerified: user.emailVerified,
  );

  AuthFailure _mapException(FirebaseAuthException error) =>
      AuthFailure(switch (error.code) {
        'invalid-email' => AuthError.invalidEmail,
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'user-disabled' => AuthError.wrongCredentials,
        'email-already-in-use' => AuthError.emailInUse,
        'weak-password' => AuthError.weakPassword,
        'too-many-requests' => AuthError.tooManyRequests,
        'network-request-failed' => AuthError.networkError,
        _ => AuthError.unknown,
      });
}
