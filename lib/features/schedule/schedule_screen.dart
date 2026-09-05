/// Schedule (home) screen: answers "when's my next shift" in one glance
/// (docs/design/screens.md). Phase 1 is guest mode — in-memory shifts,
/// sync indicator shows offline, no cloud states yet.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/domain/money/format.dart';
import 'package:shiftwise/domain/pay/estimate.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/auth/account_sheet.dart';
import 'package:shiftwise/features/schedule/state/shifts.dart';
import 'package:shiftwise/features/schedule/widgets/hero_countdown.dart';
import 'package:shiftwise/shared/time_format.dart';
import 'package:shiftwise/shared/widgets/day_cell.dart';
import 'package:shiftwise/shared/widgets/empty_state.dart';
import 'package:shiftwise/shared/widgets/shift_row.dart';
import 'package:shiftwise/shared/widgets/sync_indicator.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, this.now});

  /// Injectable clock so tests and goldens stay deterministic.
  final DateTime? now;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = widget.now ?? DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final shifts = ref.watch(shiftsProvider);
    final now = widget.now ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final week = [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];
    final dayShifts = [
      for (final shift in shifts)
        if (shift.startsOn(_selectedDay)) shift,
    ]..sort((a, b) => a.start.compareTo(b.start));
    final todayShifts = [
      for (final shift in shifts)
        if (shift.startsOn(today)) shift,
    ];
    final next = _nextUpcoming(shifts, now);
    final type = context.designType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined),
            tooltip: 'Scan schedule',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Account',
            onPressed: () => showAccountSheet(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: Tokens.spaceSm),
            child: SyncIndicator(state: SyncState.offline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/shift-edit'),
        icon: const Icon(Icons.add),
        label: const Text('Add shift'),
      ),
      body: shifts.isEmpty
          ? EmptyState(
              icon: Icons.event_busy,
              message: 'No shifts yet',
              actionLabel: 'Add a shift',
              onAction: () => context.push('/shift-edit'),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: Tokens.spaceXs),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.spaceMd,
                  ),
                  child: Row(
                    children: [
                      for (final day in week)
                        Padding(
                          padding: const EdgeInsets.only(right: Tokens.spaceXs),
                          child: DayCell(
                            day: day,
                            selected: day == _selectedDay,
                            isToday: day == today,
                            shiftTimeRange: _rangeFor(shifts, day),
                            onTap: () => setState(() => _selectedDay = day),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Tokens.spaceXl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.spaceMd,
                  ),
                  child: next != null
                      ? HeroCountdown(shift: next, now: now)
                      : Text('No upcoming shift', style: type.body),
                ),
                const SizedBox(height: Tokens.spaceLg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.spaceMd,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Tokens.spaceMd),
                    decoration: BoxDecoration(
                      color: context.designColors.surfaceDim,
                      borderRadius: BorderRadius.circular(Tokens.radiusMd),
                    ),
                    child: todayShifts.isEmpty
                        ? Text('No shift today', style: type.body)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's hours: "
                                '${formatHours(_totalHours(todayShifts))}',
                                style: type.body,
                              ),
                              Text(
                                'Estimated gross pay: '
                                '${formatUsd(_totalPay(todayShifts))}',
                                style: type.body,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: Tokens.spaceLg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.spaceMd,
                  ),
                  child: Text(formatMonthDay(_selectedDay), style: type.title),
                ),
                const SizedBox(height: Tokens.spaceXs),
                if (dayShifts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.spaceMd,
                      vertical: Tokens.spaceSm,
                    ),
                    child: Text('No shift this day', style: type.label),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.spaceMd,
                    ),
                    child: Column(
                      children: [
                        for (final shift in dayShifts)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: Tokens.spaceXs,
                            ),
                            child: ShiftRow(
                              shift: shift,
                              onEdit: () =>
                                  context.push('/shift-edit', extra: shift),
                              onDelete: () => _confirmDelete(shift),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  String? _rangeFor(List<Shift> shifts, DateTime day) {
    for (final shift in shifts) {
      if (shift.startsOn(day)) {
        return formatShiftRange(shift.start, shift.end);
      }
    }
    return null;
  }

  Future<void> _confirmDelete(Shift shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete shift?'),
        content: Text(
          'Delete the ${shift.jobName} shift? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      ref.read(shiftsProvider.notifier).remove(shift.id);
    }
  }
}

Shift? _nextUpcoming(List<Shift> shifts, DateTime now) {
  Shift? next;
  for (final shift in shifts) {
    if (shift.start.isAfter(now) &&
        (next == null || shift.start.isBefore(next.start))) {
      next = shift;
    }
  }
  return next;
}

Decimal _totalHours(List<Shift> shifts) =>
    shifts.fold(Decimal.zero, (sum, shift) => sum + workedHours(shift));

Decimal _totalPay(List<Shift> shifts) =>
    shifts.fold(Decimal.zero, (sum, shift) => sum + estimatedGrossPay(shift));
