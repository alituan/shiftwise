library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/features/auth/account_sheet.dart';
import 'package:shiftwise/features/auth/auth_models.dart';
import 'package:shiftwise/features/auth/state/auth.dart';

import '../../support/fake_auth_gateway.dart';

Widget pumpSheet(FakeAuthGateway gateway) => ProviderScope(
  overrides: [authGatewayProvider.overrideWithValue(gateway)],
  child: MaterialApp(
    theme: ShiftWiseThemes.light,
    home: const Scaffold(body: AccountSheet()),
  ),
);

void main() {
  testWidgets('guest content explains local-only mode', (tester) async {
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(pumpSheet(gateway));
    await tester.pump();
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    expect(
      find.textContaining('Your shifts stay on this device'),
      findsOneWidget,
    );
    expect(find.text('Sign in or create an account'), findsOneWidget);
    // The design's single shadow lives on the sheet itself.
    final sheet = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          (widget.decoration as BoxDecoration).boxShadow != null,
    );
    expect(sheet, findsOneWidget);
    final decorated = tester.widget<DecoratedBox>(sheet);
    expect(
      (decorated.decoration as BoxDecoration).boxShadow,
      same(Tokens.elevationSheet),
    );
  });

  testWidgets('verified account shows the confirmed chip', (tester) async {
    final gateway = FakeAuthGateway(
      initialUser: const AuthUser(
        uid: 'u1',
        email: 'worker@shiftwise.test',
        isEmailVerified: true,
      ),
    );
    await tester.pumpWidget(pumpSheet(gateway));
    await tester.pump();
    expect(find.text('worker@shiftwise.test'), findsOneWidget);
    expect(find.text('Email verified'), findsOneWidget);
    expect(find.text('Resend verification email'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('unverified account offers resend', (tester) async {
    final gateway = FakeAuthGateway(
      initialUser: const AuthUser(
        uid: 'u1',
        email: 'worker@shiftwise.test',
        isEmailVerified: false,
      ),
    );
    await tester.pumpWidget(pumpSheet(gateway));
    await tester.pump();
    expect(find.text('Email not verified'), findsOneWidget);

    await tester.tap(find.text('Resend verification email'));
    await tester.pump();
    expect(gateway.calls, contains('sendEmailVerification'));
    expect(find.text('Verification email sent'), findsOneWidget);
  });

  testWidgets('resend failure surfaces friendly copy', (tester) async {
    final gateway = FakeAuthGateway(
      initialUser: const AuthUser(
        uid: 'u1',
        email: 'worker@shiftwise.test',
        isEmailVerified: false,
      ),
    )..verificationFails = true;
    await tester.pumpWidget(pumpSheet(gateway));
    await tester.pump();

    await tester.tap(find.text('Resend verification email'));
    await tester.pump();
    expect(gateway.calls, contains('sendEmailVerification'));
    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
  });

  testWidgets('signing out switches to guest content live', (tester) async {
    final gateway = FakeAuthGateway(
      initialUser: const AuthUser(
        uid: 'u1',
        email: 'worker@shiftwise.test',
        isEmailVerified: true,
      ),
    );
    await tester.pumpWidget(pumpSheet(gateway));
    await tester.pump();

    await tester.tap(find.text('Sign out'));
    await tester.pump();
    expect(gateway.calls, contains('signOut'));
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('worker@shiftwise.test'), findsNothing);
  });
}
