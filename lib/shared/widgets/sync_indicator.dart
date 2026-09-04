/// Small persistent sync-state indicator — never a modal or toast
/// (docs/design/screens.md component inventory). Guest mode is local-only,
/// so `offline` is the normal Phase-1 state.
library;

import 'package:flutter/material.dart';
import 'package:shiftwise/app/theme/tokens.dart';

enum SyncState { synced, syncing, offline, conflict }

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key, required this.state, this.onTapConflict});

  final SyncState state;

  /// Opens the conflict resolution prompt — Phase 2 wires this.
  final VoidCallback? onTapConflict;

  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    final colors = context.designColors;
    final type = context.designType;
    final (icon, iconColor, label) = switch (state) {
      SyncState.synced => (
        Icons.cloud_done_outlined,
        colors.confirmed,
        'Synced',
      ),
      SyncState.syncing => (Icons.sync_rounded, colors.primary, 'Syncing'),
      SyncState.offline => (Icons.cloud_off_outlined, colors.ink, 'Offline'),
      SyncState.conflict => (
        Icons.warning_amber_rounded,
        colors.concern,
        'Conflict',
      ),
    };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _iconSize, color: iconColor),
        const SizedBox(width: Tokens.space2xs),
        Text(label, style: type.label),
      ],
    );
    if (state == SyncState.conflict && onTapConflict != null) {
      // Interactive elements keep the 44pt accessibility floor.
      return InkWell(
        onTap: onTapConflict,
        borderRadius: BorderRadius.circular(Tokens.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Tokens.spaceXs),
          child: content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.spaceXs),
      child: content,
    );
  }
}
