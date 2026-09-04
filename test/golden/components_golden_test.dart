/// Golden baselines for the design-system components — status chips, sync
/// indicator, day cells, shift row — in both palettes (docs/testing.md).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/shared/widgets/day_cell.dart';
import 'package:shiftwise/shared/widgets/status_chip.dart';
import 'package:shiftwise/shared/widgets/shift_row.dart';
import 'package:shiftwise/shared/widgets/sync_indicator.dart';

import '../support/golden_fonts.dart';
import '../support/test_shifts.dart';

void main() {
  setUpAll(loadInterFonts);

  testGoldens('shared components — light palette', (tester) async {
    await tester.pumpWidgetBuilder(
      _showcase(ThemeMode.light),
      surfaceSize: const Size(412, 900),
    );
    await screenMatchesGolden(tester, 'components_light');
  });

  testGoldens('shared components — dark palette', (tester) async {
    await tester.pumpWidgetBuilder(
      _showcase(ThemeMode.dark),
      surfaceSize: const Size(412, 900),
    );
    await screenMatchesGolden(tester, 'components_dark');
  });
}

Widget _showcase(ThemeMode mode) => MaterialApp(
  theme: ShiftWiseThemes.light,
  darkTheme: ShiftWiseThemes.dark,
  themeMode: mode,
  home: const _ComponentsShowcase(),
);

class _ComponentsShowcase extends StatelessWidget {
  const _ComponentsShowcase();

  @override
  Widget build(BuildContext context) {
    final type = context.designType;
    final friday = DateTime(2026, 9, 4);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('StatusChip', style: type.title),
              const SizedBox(height: Tokens.spaceXs),
              const Wrap(
                spacing: Tokens.spaceSm,
                runSpacing: Tokens.spaceSm,
                children: [
                  StatusChip(
                    label: 'Confirmed',
                    variant: StatusChipVariant.confirmed,
                  ),
                  StatusChip(
                    label: 'Concern',
                    variant: StatusChipVariant.concern,
                  ),
                  StatusChip(
                    label: 'Failed',
                    variant: StatusChipVariant.failed,
                  ),
                  StatusChip(
                    label: 'Syncing',
                    variant: StatusChipVariant.syncing,
                  ),
                  StatusChip(
                    label: 'Local',
                    variant: StatusChipVariant.neutral,
                  ),
                ],
              ),
              const SizedBox(height: Tokens.spaceLg),
              Text('SyncIndicator', style: type.title),
              const SizedBox(height: Tokens.spaceXs),
              const Wrap(
                spacing: Tokens.spaceSm,
                runSpacing: Tokens.spaceSm,
                children: [
                  SyncIndicator(state: SyncState.synced),
                  SyncIndicator(state: SyncState.syncing),
                  SyncIndicator(state: SyncState.offline),
                  SyncIndicator(state: SyncState.conflict),
                ],
              ),
              const SizedBox(height: Tokens.spaceLg),
              Text('DayCell', style: type.title),
              const SizedBox(height: Tokens.spaceXs),
              Row(
                children: [
                  DayCell(
                    day: friday,
                    selected: true,
                    isToday: true,
                    shiftTimeRange: '2:00 PM–10:00 PM',
                    onTap: () {},
                  ),
                  const SizedBox(width: Tokens.spaceXs),
                  DayCell(
                    day: friday.add(const Duration(days: 1)),
                    selected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: Tokens.spaceXs),
                  DayCell(
                    day: friday.add(const Duration(days: 2)),
                    selected: false,
                    hasConcern: true,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: Tokens.spaceLg),
              Text('ShiftRow', style: type.title),
              const SizedBox(height: Tokens.spaceXs),
              SizedBox(
                width: 320,
                child: ShiftRow(
                  shift: cafeShift(),
                  onEdit: () {},
                  onDelete: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
