/// Phase-1 routes. Scan, Pay, and Settings screens land in later phases.
library;

import 'package:go_router/go_router.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/schedule/schedule_screen.dart';
import 'package:shiftwise/features/shift_edit/shift_edit_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ScheduleScreen()),
    GoRoute(
      path: '/shift-edit',
      builder: (context, state) =>
          ShiftEditScreen(editing: state.extra as Shift?),
    ),
  ],
);
