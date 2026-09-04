library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/features/auth/auth_models.dart';

import 'fake_auth_gateway.dart';

void main() {
  test('onListen seed delivers the current state', () async {
    const user = AuthUser(
      uid: 'u1',
      email: 'worker@shiftwise.test',
      isEmailVerified: false,
    );
    final fake = FakeAuthGateway(initialUser: user);
    final received = <Object?>[];
    final sub = fake.authStateChanges.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    expect(received, [user], reason: 'seed missing');
    await sub.cancel();
  });

  test('guest seed delivers null', () async {
    final fake = FakeAuthGateway();
    final received = <Object?>[];
    final sub = fake.authStateChanges.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    expect(received, [null]);
    await sub.cancel();
  });
}
