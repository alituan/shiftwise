library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/features/auth/auth_screen.dart';
import 'package:shiftwise/features/auth/state/auth.dart';
import 'package:shiftwise/features/schedule/schedule_screen.dart';

import '../../support/fake_auth_gateway.dart';

Widget pumpAuth(FakeAuthGateway gateway) => ProviderScope(
  overrides: [authGatewayProvider.overrideWithValue(gateway)],
  child: MaterialApp.router(
    theme: ShiftWiseThemes.light,
    routerConfig: GoRouter(
      initialLocation: '/auth',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ScheduleScreen()),
        GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      ],
    ),
  ),
);

Future<void> _fill(
  WidgetTester tester, {
  String email = 'worker@shiftwise.test',
  String password = 'hunter22',
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    password,
  );
}

void main() {
  late FakeAuthGateway gateway;

  setUp(() => gateway = FakeAuthGateway());

  testWidgets('starts in sign-in mode with guest note', (tester) async {
    await tester.pumpWidget(pumpAuth(gateway));
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(
      find.text('Guest mode keeps working without an account.'),
      findsOneWidget,
    );
  });

  testWidgets('empty form shows validation errors', (tester) async {
    await tester.pumpWidget(pumpAuth(gateway));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
  });

  testWidgets('sign-up mode enforces the confirmation match', (tester) async {
    await tester.pumpWidget(pumpAuth(gateway));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await _fill(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'different',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text("Passwords don't match"), findsOneWidget);
  });

  testWidgets('wrong credentials surface friendly copy, not codes', (
    tester,
  ) async {
    await tester.pumpWidget(pumpAuth(gateway));
    await _fill(tester, password: 'wrongpass');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password.'), findsOneWidget);
    // Still on the auth screen — no navigation.
    expect(find.text('Forgot your password?'), findsOneWidget);
  });

  testWidgets('successful sign-in returns to the schedule', (tester) async {
    await tester.pumpWidget(pumpAuth(gateway));
    await _fill(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Schedule'), findsOneWidget);
    expect(gateway.calls, contains('signIn'));
  });

  testWidgets('sign-up signs in and sends the verification email', (
    tester,
  ) async {
    await tester.pumpWidget(pumpAuth(gateway));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await _fill(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'hunter22',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(gateway.calls, containsAll(['signUp', 'sendEmailVerification']));
    expect(
      find.text('Account created. Check your email to verify.'),
      findsOneWidget,
    );
    expect(find.text('Schedule'), findsOneWidget);
  });

  testWidgets('sign-up failure stays on the form with friendly copy', (
    tester,
  ) async {
    await tester.pumpWidget(pumpAuth(gateway));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await _fill(tester, email: 'taken@shiftwise.test');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'hunter22',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(
      find.text('An account already exists for this email.'),
      findsOneWidget,
    );
  });

  testWidgets('reset mode sends the email and confirms', (tester) async {
    await tester.pumpWidget(pumpAuth(gateway));
    await tester.tap(find.text('Forgot your password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'worker@shiftwise.test',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
    await tester.pumpAndSettle();

    expect(gateway.calls, contains('sendPasswordReset:worker@shiftwise.test'));
    expect(find.text('Check your email for a reset link.'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('reset failure shows friendly copy', (tester) async {
    await tester.pumpWidget(pumpAuth(gateway));
    await tester.tap(find.text('Forgot your password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'invalid@x',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
    await tester.pumpAndSettle();
    expect(find.text("That email address doesn't look right."), findsOneWidget);
  });
}
