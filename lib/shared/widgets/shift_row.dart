/// List row for one shift: time range, job, break duration. Swipe-left
/// reveals Edit + Delete as two separate actions — deleting needs a
/// confirmed tap after the reveal, never a bare swipe
/// (docs/design/screens.md gesture rules).
library;

import 'package:flutter/material.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/shared/time_format.dart';

class ShiftRow extends StatefulWidget {
  const ShiftRow({
    super.key,
    required this.shift,
    required this.onEdit,
    required this.onDelete,
  });

  final Shift shift;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<ShiftRow> createState() => _ShiftRowState();
}

class _ShiftRowState extends State<ShiftRow> {
  static const double _revealExtent = 144;
  double _offset = 0;

  bool get _revealed => _offset <= -_revealExtent / 2;

  void _onDrag(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + (details.primaryDelta ?? 0)).clamp(
        -_revealExtent,
        0,
      );
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _offset = _revealed ? -_revealExtent : 0);
  }

  void _collapse() => setState(() => _offset = 0);

  @override
  Widget build(BuildContext context) {
    final colors = context.designColors;
    final type = context.designType;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                const Spacer(),
                _Action(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () {
                    _collapse();
                    widget.onEdit();
                  },
                ),
                _Action(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: () {
                    _collapse();
                    widget.onDelete();
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _onDrag,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              transform: Matrix4.translationValues(_offset, 0, 0),
              color: colors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: Tokens.spaceSm,
                vertical: Tokens.spaceXs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatShiftRange(
                            widget.shift.start,
                            widget.shift.end,
                          ),
                          style: type.body,
                        ),
                        Text(
                          widget.shift.breakMinutes > 0
                              ? '${widget.shift.breakMinutes}m break'
                              : 'No break',
                          style: type.label,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Tokens.spaceSm),
                  Text(
                    widget.shift.jobName,
                    style: type.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const double _width = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.designColors;
    final type = context.designType;
    return SizedBox(
      width: _width,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: colors.ink),
              const SizedBox(height: Tokens.space2xs),
              Text(
                label,
                style: type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
