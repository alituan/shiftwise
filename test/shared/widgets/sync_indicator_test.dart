library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/shared/widgets/sync_indicator.dart';

void main() {
  for (final state in SyncState.values) {
    testWidgets('shows the ${state.name} label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ShiftWiseThemes.light,
          home: Scaffold(body: SyncIndicator(state: state)),
        ),
      );
      final label = switch (state) {
        SyncState.synced => 'Synced',
        SyncState.syncing => 'Syncing',
        SyncState.offline => 'Offline',
        SyncState.conflict => 'Conflict',
      };
      expect(find.text(label), findsOneWidget);
    });
  }

  testWidgets('conflict state is tappable and fires the callback', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ShiftWiseThemes.light,
        home: Scaffold(
          body: SyncIndicator(
            state: SyncState.conflict,
            onTapConflict: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(SyncIndicator));
    await tester.pump();
    expect(taps, 1);
  });
}
