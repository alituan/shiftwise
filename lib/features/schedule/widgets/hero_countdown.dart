/// The Schedule screen's hero: next-shift time range plus a colorPrimary
/// countdown. Screen-specific by design — not generalized prematurely
/// (docs/design/screens.md component inventory).
library;

import 'package:flutter/material.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/shared/time_format.dart';

class HeroCountdown extends StatelessWidget {
  const HeroCountdown({super.key, required this.shift, required this.now});

  final Shift shift;

  /// Injectable clock so tests and goldens stay deterministic.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.designColors;
    final type = context.designType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next shift', style: type.label),
        const SizedBox(height: Tokens.spaceXs),
        Text(
          '${formatWeekdayShort(shift.start)} · '
          '${formatShiftRange(shift.start, shift.end)}',
          style: type.hero,
        ),
        Text(
          formatCountdown(shift.start.difference(now)),
          style: type.hero.copyWith(color: colors.primary),
        ),
      ],
    );
  }
}
