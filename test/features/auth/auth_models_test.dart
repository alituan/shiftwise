library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/features/auth/auth_models.dart';

void main() {
  test('every auth error has friendly copy', () {
    for (final error in AuthError.values) {
      expect(authErrorMessage(error), isNotEmpty);
    }
  });

  test('wrong email and wrong password share one message', () {
    // User-enumeration hygiene: the UI must not reveal which one was wrong.
    expect(authErrorMessage(AuthError.wrongCredentials), contains('Incorrect'));
    expect(
      authErrorMessage(AuthError.invalidEmail),
      isNot(contains('password')),
    );
  });

  test('AuthFailure carries its error', () {
    const failure = AuthFailure(AuthError.emailInUse);
    expect(failure.error, AuthError.emailInUse);
    expect(failure.toString(), contains('emailInUse'));
  });
}
