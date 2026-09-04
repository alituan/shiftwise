library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shiftwise/features/auth/auth_models.dart';
import 'package:shiftwise/features/auth/firebase_auth_gateway.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockCredential extends Mock implements UserCredential {}

void main() {
  late _MockAuth auth;
  late _MockUser user;
  late _MockCredential credential;
  late FirebaseAuthGateway gateway;

  setUpAll(() {
    registerFallbackValue(Uri.parse('x'));
  });

  setUp(() {
    auth = _MockAuth();
    user = _MockUser();
    credential = _MockCredential();
    gateway = FirebaseAuthGateway(auth);
    when(() => user.uid).thenReturn('uid-1');
    when(() => user.email).thenReturn('worker@shiftwise.test');
    when(() => user.emailVerified).thenReturn(false);
    when(() => credential.user).thenReturn(user);
  });

  test('authStateChanges maps a firebase user onto AuthUser', () async {
    when(() => auth.authStateChanges())
        .thenAnswer((_) => Stream<User?>.value(user));
    final emitted = await gateway.authStateChanges.first;
    expect(emitted, isNotNull);
    expect(emitted!.email, 'worker@shiftwise.test');
    expect(emitted.isEmailVerified, isFalse);
    expect(emitted.uid, 'uid-1');
  });

  test('authStateChanges maps a null user to guest mode', () async {
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(null));
    expect(await gateway.authStateChanges.first, isNull);
  });

  test('signUp returns the created user', () async {
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email', that: isNotNull),
        password: any(named: 'password', that: isNotNull),
      ),
    ).thenAnswer((_) async => credential);
    final created = await gateway.signUp(
      email: 'worker@shiftwise.test',
      password: 'hunter22',
    );
    expect(created.email, 'worker@shiftwise.test');
  });

  for (final entry in {
    'invalid-email': AuthError.invalidEmail,
    'invalid-credential': AuthError.wrongCredentials,
    'wrong-password': AuthError.wrongCredentials,
    'user-not-found': AuthError.wrongCredentials,
    'email-already-in-use': AuthError.emailInUse,
    'weak-password': AuthError.weakPassword,
    'too-many-requests': AuthError.tooManyRequests,
    'network-request-failed': AuthError.networkError,
    'something-never-seen': AuthError.unknown,
  }.entries) {
    test('maps FirebaseAuthException ${entry.key} to ${entry.value.name}', () {
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email', that: isNotNull),
          password: any(named: 'password', that: isNotNull),
        ),
      ).thenThrow(FirebaseAuthException(code: entry.key, message: 'test'));
      expect(
        () => gateway.signUp(email: 'a@b.c', password: 'hunter22'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.error,
            'error',
            entry.value,
          ),
        ),
      );
    });
  }

  test('sendPasswordReset maps failures', () async {
    when(
      () => auth.sendPasswordResetEmail(email: any(named: 'email')),
    ).thenThrow(FirebaseAuthException(code: 'user-not-found', message: 'test'));
    expect(
      () => gateway.sendPasswordReset('a@b.c'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.error,
          'error',
          AuthError.wrongCredentials,
        ),
      ),
    );
  });

  test('sendEmailVerification is a no-op without a user', () async {
    when(() => auth.currentUser).thenReturn(null);
    await gateway.sendEmailVerification();
    verifyNever(() => user.sendEmailVerification());
  });

  test('sendEmailVerification is a no-op when already verified', () async {
    when(() => user.emailVerified).thenReturn(true);
    when(() => auth.currentUser).thenReturn(user);
    await gateway.sendEmailVerification();
    verifyNever(() => user.sendEmailVerification());
  });

  test('sendEmailVerification forwards to the user', () async {
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    await gateway.sendEmailVerification();
    verify(() => user.sendEmailVerification()).called(1);
  });

  test('signOut forwards to firebase auth', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});
    await gateway.signOut();
    verify(() => auth.signOut()).called(1);
  });
}
