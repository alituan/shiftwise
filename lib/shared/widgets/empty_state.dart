/// Empty-state block: icon, one line of copy, one primary action — always a
/// path forward, never a bare illustration (docs/design/screens.md).
library;

import 'package:flutter/material.dart';
import 'package:shiftwise/app/theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  static const double _iconSize = 32;

  @override
  Widget build(BuildContext context) {
    final type = context.designType;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize, color: context.designColors.ink),
          const SizedBox(height: Tokens.spaceSm),
          Text(message, style: type.body, textAlign: TextAlign.center),
          const SizedBox(height: Tokens.spaceMd),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
