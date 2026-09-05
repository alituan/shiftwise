library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/auth/state/auth.dart';
import 'package:shiftwise/features/schedule/schedule_screen.dart';
import 'package:shiftwise/features/schedule/state/shifts.dart';
import 'package:shiftwise/features/shift_edit/shift_edit_screen.dart';

import '../../support/fake_auth_gateway.dart';
import '../../support/test_shifts.dart';

Widget pumpApp({List<Shift> seeds = const []}) {
  return ProviderScope(
    overrides: [shiftsProvider.overrideWith(() => SeededShifts(seeds))],
    child: MaterialApp.router(
      theme: ShiftWiseThemes.light,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => ScheduleScreen(now: testNow),
          ),
          GoRoute(
            path: '/shift-edit',
            builder: (_, state) =>
                ShiftEditScreen(editing: state.extra as Shift?, now: testNow),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('empty state shows the add CTA and offline indicator', (
    tester,
  ) async {
    await tester.pumpWidget(pumpApp());
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('No shifts yet'), findsOneWidget);
    expect(find.text('Add a shift'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('add CTA opens the edit route', (tester) async {
    await tester.pumpWidget(pumpApp());
    await tester.tap(find.text('Add a shift'));
    await tester.pumpAndSettle();
    expect(find.text('Add shift'), findsOneWidget);
  });

  testWidgets('seeded shifts show hero, summary, and today rows', (
    tester,
  ) async {
    await tester.pumpWidget(pumpApp(seeds: [cafeShift(), hospitalShift()]));
    expect(find.text('Fri · 2:00 PM–10:00 PM'), findsOneWidget);
    expect(find.text('in 3h 0m'), findsOneWidget);
    expect(find.text("Today's hours: 7.5"), findsOneWidget);
    expect(find.text('Estimated gross pay: \$123.75'), findsOneWidget);
    expect(find.text('Cafe'), findsOneWidget);
    expect(find.text('30m break'), findsOneWidget);
  });

  testWidgets('week strip reflects other days and selects them', (
    tester,
  ) async {
    await tester.pumpWidget(pumpApp(seeds: [cafeShift(), hospitalShift()]));
    // Saturday's cell carries the overnight hospital range.
    expect(find.text('10:00 PM–6:00 AM'), findsOneWidget);

    await tester.tap(find.text('Sat'));
    await tester.pumpAndSettle();
    expect(find.text('Hospital'), findsOneWidget);
    expect(find.text('No break'), findsOneWidget);
    expect(find.text('Sep 5'), findsOneWidget);
  });

  testWidgets('days without shifts show the empty-day note', (tester) async {
    await tester.pumpWidget(pumpApp(seeds: [cafeShift()]));
    await tester.tap(find.text('Wed'));
    await tester.pumpAndSettle();
    expect(find.text('No shift this day'), findsOneWidget);
  });

  testWidgets('end-to-end create: form save adds the shift', (tester) async {
    await tester.pumpWidget(pumpApp());
    await tester.tap(find.text('Add a shift'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name'),
      'Cafe',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hourly rate (USD)'),
      '16.50',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('No shifts yet'), findsNothing);
    expect(find.text('Cafe'), findsOneWidget);
    expect(find.textContaining('Estimated gross pay:'), findsOneWidget);
  });

  testWidgets('swipe reveal edit opens the form prefilled and saves', (
    tester,
  ) async {
    await tester.pumpWidget(pumpApp(seeds: [cafeShift()]));
    await tester.drag(find.text('Cafe'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit shift'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name'),
      'Cafe East',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Cafe East'), findsOneWidget);
    expect(find.text('Cafe'), findsNothing);
  });

  testWidgets('delete asks for confirmation and removes the shift', (
    tester,
  ) async {
    await tester.pumpWidget(pumpApp(seeds: [cafeShift()]));
    await tester.drag(find.text('Cafe'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete shift?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('No shifts yet'), findsOneWidget);
  });

  testWidgets('cancel keeps the shift', (tester) async {
    await tester.pumpWidget(pumpApp(seeds: [cafeShift()]));
    await tester.drag(find.text('Cafe'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Cafe'), findsOneWidget);
  });

  testWidgets('account action opens the account sheet', (tester) async {
    final fakeAuth = FakeAuthGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authGatewayProvider.overrideWithValue(fakeAuth)],
        child: MaterialApp.router(
          theme: ShiftWiseThemes.light,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => ScheduleScreen(now: testNow),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
  });
}
