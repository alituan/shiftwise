/// App routes. Scan, Pay, and Settings screens land in later phases.
library;

import 'package:go_router/go_router.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/auth/auth_screen.dart';
import 'package:shiftwise/features/schedule/schedule_screen.dart';
import 'package:shiftwise/features/scan/scan_screen.dart';
import 'package:shiftwise/features/shift_edit/shift_edit_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ScheduleScreen()),
    GoRoute(
      path: '/shift-edit',
      builder: (context, state) =>
          ShiftEditScreen(editing: state.extra as Shift?),
    ),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
  ],
);
