library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/shift_edit/shift_edit_screen.dart';

void main() {
  // Full app shell: a valid save reads the riverpod notifier and navigates.
  Widget pumpForm() => ProviderScope(
    child: MaterialApp.router(
      theme: ShiftWiseThemes.light,
      routerConfig: GoRouter(
        initialLocation: '/shift-edit',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: SizedBox()),
          ),
          GoRoute(
            path: '/shift-edit',
            builder: (_, _) => const ShiftEditScreen(),
          ),
        ],
      ),
    ),
  );

  testWidgets('prefills defaults so only job and rate are required', (
    tester,
  ) async {
    await tester.pumpWidget(pumpForm());
    expect(find.text('Add shift'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // default break minutes
  });

  testWidgets('empty job name shows an error', (tester) async {
    await tester.pumpWidget(pumpForm());
    await tester.enterText(find.widgetWithText(TextFormField, 'Job name'), '');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a job name'), findsOneWidget);
  });

  testWidgets('unparseable rate shows an error', (tester) async {
    await tester.pumpWidget(pumpForm());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name'),
      'Cafe',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hourly rate (USD)'),
      'abc',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a rate like 16.50'), findsOneWidget);
  });

  testWidgets('negative break shows an error', (tester) async {
    await tester.pumpWidget(pumpForm());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name'),
      'Cafe',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unpaid break minutes'),
      '-5',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter 0 or more minutes'), findsOneWidget);
  });

  testWidgets('accepts a decimal rate', (tester) async {
    await tester.pumpWidget(pumpForm());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name'),
      'Cafe',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hourly rate (USD)'),
      '16.50',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a rate like 16.50'), findsNothing);
    expect(find.text('Enter a job name'), findsNothing);
  });

  testWidgets('negative rate shows an error', (tester) async {
    await tester.pumpWidget(pumpForm());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Job name'),
      'Cafe',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hourly rate (USD)'),
      '-1',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a rate like 16.50'), findsOneWidget);
  });

  testWidgets('edit mode shows the edit title', (tester) async {
    final shift = Shift.create(
      id: 'cafe',
      jobName: 'Cafe',
      start: DateTime(2026, 9, 4, 14),
      end: DateTime(2026, 9, 4, 22),
      breakMinutes: 30,
      ratePerHour: Decimal.parse('16.50'),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ShiftWiseThemes.light,
        home: ShiftEditScreen(editing: shift),
      ),
    );
    expect(find.text('Edit shift'), findsOneWidget);
    expect(find.text('30'), findsOneWidget); // break minutes prefilled
  });
}
