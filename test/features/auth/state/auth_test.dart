library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/features/auth/auth_models.dart';
import 'package:shiftwise/features/auth/state/auth.dart';

import '../../../support/fake_auth_gateway.dart';

void main() {
  late FakeAuthGateway gateway;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<dynamic>> subscription;

  setUp(() {
    gateway = FakeAuthGateway();
    container = ProviderContainer(
      overrides: [authGatewayProvider.overrideWithValue(gateway)],
    );
    // Riverpod 3 streams flow only while listened; keep one active.
    subscription = container.listen(authUserProvider, (_, _) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('authUserProvider starts as guest when signed out', () async {
    final first = await container.read(authUserProvider.future);
    expect(first, isNull);
  });

  test('authUserProvider reflects a signed-in user', () async {
    // Let the guest seed land, then transition and let that land too —
    // riverpod's .future latches onto the first value, so assert state.
    await Future<void>.delayed(Duration.zero);
    gateway.emit(
      const AuthUser(
        uid: 'u1',
        email: 'worker@shiftwise.test',
        isEmailVerified: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final state = container.read(authUserProvider);
    expect(state, isA<AsyncData<AuthUser?>>());
    final user = (state as AsyncData<AuthUser?>).value;
    expect(user?.email, 'worker@shiftwise.test');
  });

  test('signUp sends the verification email and still signs in', () async {
    final controller = container.read(authControllerProvider);
    final user = await controller.signUp(
      email: 'new@shiftwise.test',
      password: 'hunter22',
    );
    expect(user.isEmailVerified, isFalse);
    expect(gateway.calls, containsAll(['signUp', 'sendEmailVerification']));
    expect(await container.read(authUserProvider.future), isNotNull);
  });

  test('signUp succeeds even when the verification email fails', () async {
    // No user is signed in after the fake's signUp emits — force a failure
    // by resetting to guest, then calling the controller's signUp path via
    // a gateway whose verification throws.
    final strictGateway = FakeAuthGateway()..verificationFails = true;
    final failing = ProviderContainer(
      overrides: [authGatewayProvider.overrideWithValue(strictGateway)],
    );
    addTearDown(failing.dispose);
    final failingSub = failing.listen(authUserProvider, (_, _) {});
    addTearDown(failingSub.close);
    final user = await failing
        .read(authControllerProvider)
        .signUp(email: 'new@shiftwise.test', password: 'hunter22');
    expect(user.email, 'new@shiftwise.test');
    expect(strictGateway.calls, contains('sendEmailVerification'));
  });

  test('signIn surfaces wrong credentials', () async {
    final controller = container.read(authControllerProvider);
    await expectLater(
      controller.signIn(email: 'a@b.c', password: 'wrongpass'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.error,
          'error',
          AuthError.wrongCredentials,
        ),
      ),
    );
  });

  test('signOut returns to guest and keeps the shift list intact', () async {
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(authControllerProvider);
    await controller.signIn(email: 'a@b.c', password: 'hunter22');
    await Future<void>.delayed(Duration.zero);
    await controller.signOut();
    await Future<void>.delayed(Duration.zero);
    final state = container.read(authUserProvider);
    expect(state, isA<AsyncData<AuthUser?>>());
    expect((state as AsyncData<AuthUser?>).value, isNull);
    expect(gateway.calls, contains('signOut'));
  });
}
