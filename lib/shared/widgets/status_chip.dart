/// Icon + label status chip — never color-only. Status colors are
/// icon/large-text pairings that must carry an ink label
/// (docs/design/tokens.md status-color rule).
library;

import 'package:flutter/material.dart';
import 'package:shiftwise/app/theme/tokens.dart';

enum StatusChipVariant { confirmed, concern, failed, syncing, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusChipVariant.neutral,
  });

  final String label;
  final StatusChipVariant variant;

  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    final colors = context.designColors;
    final type = context.designType;
    final (icon, iconColor) = switch (variant) {
      StatusChipVariant.confirmed => (Icons.check_circle, colors.confirmed),
      StatusChipVariant.concern => (
        Icons.warning_amber_rounded,
        colors.concern,
      ),
      StatusChipVariant.failed => (
        Icons.error_outline_rounded,
        colors.critical,
      ),
      StatusChipVariant.syncing => (Icons.sync_rounded, colors.primary),
      StatusChipVariant.neutral => (Icons.info_outline_rounded, colors.ink),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.spaceXs,
        vertical: Tokens.space2xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize, color: iconColor),
          const SizedBox(width: Tokens.space2xs),
          Text(label, style: type.label),
        ],
      ),
    );
  }
}
