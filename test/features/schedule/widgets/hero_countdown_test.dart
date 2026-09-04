library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/features/schedule/widgets/hero_countdown.dart';

import '../../../support/test_shifts.dart';

void main() {
  testWidgets('shows next-shift label, range, and countdown', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ShiftWiseThemes.light,
        home: Scaffold(
          body: HeroCountdown(shift: cafeShift(), now: testNow),
        ),
      ),
    );
    expect(find.text('Next shift'), findsOneWidget);
    expect(find.text('Fri · 2:00 PM–10:00 PM'), findsOneWidget);
    expect(find.text('in 3h 0m'), findsOneWidget);
  });

  testWidgets('countdown uses the injected clock', (tester) async {
    final soon = testNow.add(const Duration(hours: 2));
    await tester.pumpWidget(
      MaterialApp(
        theme: ShiftWiseThemes.light,
        home: Scaffold(
          body: HeroCountdown(shift: cafeShift(), now: soon),
        ),
      ),
    );
    expect(find.text('in 1h 0m'), findsOneWidget);
  });
}
