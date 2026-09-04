/// One day in the week strip: weekday, date, shift time range or the empty
/// variant, plus a concern chip when the day needs attention
/// (docs/design/screens.md component inventory).
library;

import 'package:flutter/material.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/shared/time_format.dart';
import 'package:shiftwise/shared/widgets/status_chip.dart';

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.day,
    required this.selected,
    required this.onTap,
    this.shiftTimeRange,
    this.hasConcern = false,
    this.isToday = false,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  /// Null when the day has no shift (empty variant).
  final String? shiftTimeRange;
  final bool hasConcern;
  final bool isToday;

  static const double _cellWidth = 112;

  @override
  Widget build(BuildContext context) {
    final colors = context.designColors;
    final type = context.designType;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      child: Container(
        width: _cellWidth,
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.space2xs,
          vertical: Tokens.spaceXs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.surfaceDim : null,
          borderRadius: BorderRadius.circular(Tokens.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatWeekdayShort(day),
              style: type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${day.day}',
              style: type.body.copyWith(
                color: isToday ? colors.primary : type.body.color,
              ),
            ),
            if (shiftTimeRange != null)
              Text(
                shiftTimeRange!,
                style: type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text('—', style: type.label),
            if (hasConcern) ...[
              const SizedBox(height: Tokens.space2xs),
              // scaleDown: the chip must fit a week-strip cell on any font.
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: StatusChip(
                  label: 'Concern',
                  variant: StatusChipVariant.concern,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
