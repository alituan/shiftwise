/// Golden baselines for the populated Schedule screen in both palettes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/schedule/schedule_screen.dart';
import 'package:shiftwise/features/schedule/state/shifts.dart';
import 'package:shiftwise/features/shift_edit/shift_edit_screen.dart';

import '../support/golden_fonts.dart';
import '../support/test_shifts.dart';

void main() {
  setUpAll(loadInterFonts);

  testGoldens('schedule screen — light palette', (tester) async {
    await tester.pumpWidgetBuilder(
      _app(ThemeMode.light),
      surfaceSize: const Size(412, 900),
    );
    await screenMatchesGolden(tester, 'schedule_light');
  });

  testGoldens('schedule screen — dark palette', (tester) async {
    await tester.pumpWidgetBuilder(
      _app(ThemeMode.dark),
      surfaceSize: const Size(412, 900),
    );
    await screenMatchesGolden(tester, 'schedule_dark');
  });
}

Widget _app(ThemeMode mode) => ProviderScope(
  overrides: [
    shiftsProvider.overrideWith(
      () => SeededShifts([cafeShift(), hospitalShift()]),
    ),
  ],
  child: MaterialApp.router(
    theme: ShiftWiseThemes.light,
    darkTheme: ShiftWiseThemes.dark,
    themeMode: mode,
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => ScheduleScreen(now: testNow),
        ),
        GoRoute(
          path: '/shift-edit',
          builder: (_, state) =>
              ShiftEditScreen(editing: state.extra as Shift?),
        ),
      ],
    ),
  ),
);
