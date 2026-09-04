library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/shared/widgets/day_cell.dart';

void main() {
  final friday = DateTime(2026, 9, 4);

  Widget pumpCell(DayCell cell) => MaterialApp(
    theme: ShiftWiseThemes.light,
    home: Scaffold(body: Center(child: cell)),
  );

  testWidgets('shows weekday and date', (tester) async {
    await tester.pumpWidget(
      pumpCell(DayCell(day: friday, selected: false, onTap: () {})),
    );
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('empty variant shows an em dash, not a range', (tester) async {
    await tester.pumpWidget(
      pumpCell(DayCell(day: friday, selected: false, onTap: () {})),
    );
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('with a shift shows the time range', (tester) async {
    await tester.pumpWidget(
      pumpCell(
        DayCell(
          day: friday,
          selected: false,
          onTap: () {},
          shiftTimeRange: '2:00 PM–10:00 PM',
        ),
      ),
    );
    expect(find.text('2:00 PM–10:00 PM'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('concern marker renders a concern chip', (tester) async {
    await tester.pumpWidget(
      pumpCell(
        DayCell(day: friday, selected: false, onTap: () {}, hasConcern: true),
      ),
    );
    expect(find.text('Concern'), findsOneWidget);
  });

  testWidgets('tap fires the callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      pumpCell(DayCell(day: friday, selected: false, onTap: () => taps++)),
    );
    await tester.tap(find.byType(DayCell));
    expect(taps, 1);
  });
}
