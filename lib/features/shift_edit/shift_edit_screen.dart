/// Add/edit shift form — a full route, not a sheet: the user is committing
/// to a multi-field flow (docs/design/screens.md bottom-sheet-vs-route rule).
///
/// Built on plain Material form fields: flutter_form_builder 11 sits on the
/// material_ui component fork, whose InputDecoration diverges from the
/// token-driven ThemeData this app maps everything through.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/schedule/state/shifts.dart';
import 'package:shiftwise/features/shift_edit/compose_shift.dart';
import 'package:shiftwise/shared/time_format.dart';
import 'package:uuid/uuid.dart';

class ShiftEditScreen extends ConsumerStatefulWidget {
  const ShiftEditScreen({super.key, this.editing, this.now});

  /// Null creates a new shift; non-null edits that shift.
  final Shift? editing;

  /// Injectable clock so tests land default dates on the schedule's frozen
  /// day; production leaves it null and uses the wall clock.
  final DateTime? now;

  @override
  ConsumerState<ShiftEditScreen> createState() => _ShiftEditScreenState();
}

class _ShiftEditScreenState extends ConsumerState<ShiftEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _jobName;
  late final TextEditingController _breakMinutes;
  late final TextEditingController _rate;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    final base = editing?.start ?? widget.now ?? DateTime.now();
    _jobName = TextEditingController(text: editing?.jobName);
    _breakMinutes = TextEditingController(
      text: (editing?.breakMinutes ?? 0).toString(),
    );
    _rate = TextEditingController(text: editing?.ratePerHour.toString());
    _date = DateTime(base.year, base.month, base.day);
    _startTime = TimeOfDay(hour: base.hour, minute: base.minute);
    _endTime = editing == null
        ? const TimeOfDay(hour: 17, minute: 0)
        : TimeOfDay(hour: editing.end.hour, minute: editing.end.minute);
  }

  @override
  void dispose() {
    _jobName.dispose();
    _breakMinutes.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = context.designType;
    final editing = widget.editing;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Add shift' : 'Edit shift'),
        actions: [
          if (editing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete shift',
              onPressed: () => _confirmDelete(editing),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Tokens.spaceMd),
          children: [
            TextFormField(
              controller: _jobName,
              decoration: const InputDecoration(labelText: 'Job name'),
              style: type.body,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a job name'
                  : null,
            ),
            const SizedBox(height: Tokens.spaceMd),
            FormField<DateTime>(
              initialValue: _date,
              validator: (value) => value == null ? 'Pick a date' : null,
              builder: (field) => InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(_date.year - 1),
                    lastDate: DateTime(_date.year + 2),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                    field.didChange(picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    errorText: field.errorText,
                  ),
                  child: Text(formatMonthDay(_date), style: type.body),
                ),
              ),
            ),
            const SizedBox(height: Tokens.spaceMd),
            FormField<TimeOfDay>(
              initialValue: _startTime,
              validator: (value) => value == null ? 'Pick a start time' : null,
              builder: (field) => InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null) {
                    setState(() => _startTime = picked);
                    field.didChange(picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Start time',
                    errorText: field.errorText,
                  ),
                  child: Text(_formatTime(_startTime), style: type.body),
                ),
              ),
            ),
            const SizedBox(height: Tokens.spaceMd),
            FormField<TimeOfDay>(
              initialValue: _endTime,
              validator: (value) => value == null ? 'Pick an end time' : null,
              builder: (field) => InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (picked != null) {
                    setState(() => _endTime = picked);
                    field.didChange(picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End time',
                    helperText: 'Earlier than start means overnight',
                    errorText: field.errorText,
                  ),
                  child: Text(_formatTime(_endTime), style: type.body),
                ),
              ),
            ),
            const SizedBox(height: Tokens.spaceMd),
            TextFormField(
              controller: _breakMinutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Unpaid break minutes',
              ),
              style: type.body,
              validator: (value) {
                final minutes = int.tryParse(value?.trim() ?? '');
                return minutes == null || minutes < 0
                    ? 'Enter 0 or more minutes'
                    : null;
              },
            ),
            const SizedBox(height: Tokens.spaceMd),
            TextFormField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Hourly rate (USD)'),
              style: type.body,
              validator: (value) {
                try {
                  return Decimal.parse((value ?? '').trim()) < Decimal.zero
                      ? 'Enter a rate like 16.50'
                      : null;
                } catch (_) {
                  return 'Enter a rate like 16.50';
                }
              },
            ),
            const SizedBox(height: Tokens.spaceLg),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(time);

  DateTime _at(TimeOfDay time) => DateTime(2000, 1, 1, time.hour, time.minute);

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final shift = composeShift(
        id: widget.editing?.id ?? const Uuid().v4(),
        jobName: _jobName.text,
        date: _date,
        start: _at(_startTime),
        end: _at(_endTime),
        breakMinutes: int.parse(_breakMinutes.text.trim()),
        ratePerHour: Decimal.parse(_rate.text.trim()),
      );
      final notifier = ref.read(shiftsProvider.notifier);
      if (widget.editing == null) {
        notifier.add(shift);
      } else {
        notifier.update(shift);
      }
      context.go('/');
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
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
      if (mounted) context.go('/');
    }
  }
}
