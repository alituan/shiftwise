/// Configurable in-memory AuthGateway for widget and state tests.
library;

import 'dart:async';

import 'package:shiftwise/features/auth/auth_gateway.dart';
import 'package:shiftwise/features/auth/auth_models.dart';

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({AuthUser? initialUser}) : _user = initialUser {
    // Broadcast + onListen seed: a fresh subscription receives the current
    // state on a microtask — synchronously-during-init delivery gets lost
    // by riverpod's StreamProvider, async delivery does not.
    _changes = StreamController<AuthUser?>.broadcast(
      onListen: () => scheduleMicrotask(() => _changes.add(_user)),
    );
  }

  AuthUser? _user;
  late final StreamController<AuthUser?> _changes;

  /// Recorded action names, in call order.
  final List<String> calls = <String>[];

  /// Test seam: make sendEmailVerification throw to exercise the
  /// best-effort sign-up path.
  bool verificationFails = false;

  @override
  Stream<AuthUser?> get authStateChanges => _changes.stream;

  /// Test seam: push a new session state to listeners.
  void emit(AuthUser? user) {
    _user = user;
    _changes.add(user);
  }

  AuthUser? get user => _user;

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    calls.add('signUp');
    if (email.contains('taken')) {
      throw const AuthFailure(AuthError.emailInUse);
    }
    final user = AuthUser(
      uid: 'u-$email',
      email: email,
      isEmailVerified: false,
    );
    emit(user);
    return user;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn');
    if (password == 'wrongpass') {
      throw const AuthFailure(AuthError.wrongCredentials);
    }
    final user = AuthUser(uid: 'u-$email', email: email, isEmailVerified: true);
    emit(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('sendPasswordReset:$email');
    if (email.contains('invalid')) {
      throw const AuthFailure(AuthError.invalidEmail);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    calls.add('sendEmailVerification');
    if (_user == null || verificationFails) {
      throw const AuthFailure(AuthError.unknown);
    }
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    emit(null);
  }
}
