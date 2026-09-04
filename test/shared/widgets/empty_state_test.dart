library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/shared/widgets/empty_state.dart';

void main() {
  testWidgets('shows message and action, and the action fires', (tester) async {
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ShiftWiseThemes.light,
        home: Scaffold(
          body: EmptyState(
            icon: Icons.event_busy,
            message: 'No shifts yet',
            actionLabel: 'Add a shift',
            onAction: () => fired++,
          ),
        ),
      ),
    );
    expect(find.text('No shifts yet'), findsOneWidget);
    await tester.tap(find.text('Add a shift'));
    expect(fired, 1);
  });
}
