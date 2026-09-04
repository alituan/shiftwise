library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/shared/widgets/shift_row.dart';

import '../../support/test_shifts.dart';

void main() {
  late bool edited;
  late bool deleted;

  Widget pumpRow() => MaterialApp(
    theme: ShiftWiseThemes.light,
    home: Scaffold(
      body: Center(
        child: ShiftRow(
          shift: cafeShift(),
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
        ),
      ),
    ),
  );

  setUp(() {
    edited = false;
    deleted = false;
  });

  testWidgets('shows range, break, and job name', (tester) async {
    await tester.pumpWidget(pumpRow());
    expect(find.text('2:00 PM–10:00 PM'), findsOneWidget);
    expect(find.text('30m break'), findsOneWidget);
    expect(find.text('Cafe'), findsOneWidget);
  });

  testWidgets('actions stay hidden until swiped left', (tester) async {
    await tester.pumpWidget(pumpRow());
    // Covered by the row surface: present in the tree, not tappable.
    expect(find.text('Edit').hitTestable(), findsNothing);
    expect(find.text('Delete').hitTestable(), findsNothing);
  });

  testWidgets('swipe reveals Edit and Delete; tapping Edit fires', (
    tester,
  ) async {
    await tester.pumpWidget(pumpRow());
    await tester.drag(find.text('Cafe'), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(find.text('Edit').hitTestable(), findsOneWidget);
    expect(find.text('Delete').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
    // Row collapses back after acting.
    expect(find.text('Edit').hitTestable(), findsNothing);
  });

  testWidgets('delete is a confirmed tap after the reveal, not a swipe', (
    tester,
  ) async {
    await tester.pumpWidget(pumpRow());
    await tester.drag(find.text('Cafe'), const Offset(-120, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('short swipe snaps closed', (tester) async {
    await tester.pumpWidget(pumpRow());
    await tester.drag(find.text('Cafe'), const Offset(-30, 0));
    await tester.pumpAndSettle();
    expect(find.text('Edit').hitTestable(), findsNothing);
    expect(find.text('Delete').hitTestable(), findsNothing);
  });
}
