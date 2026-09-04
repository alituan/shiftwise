library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/app/theme/tokens.dart';
import 'package:shiftwise/shared/widgets/status_chip.dart';

void main() {
  for (final variant in StatusChipVariant.values) {
    testWidgets('renders icon and ink label for ${variant.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ShiftWiseThemes.light,
          home: Scaffold(
            body: StatusChip(label: 'Confirmed', variant: variant),
          ),
        ),
      );
      expect(find.text('Confirmed'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      final expected = switch (variant) {
        StatusChipVariant.confirmed => DesignColors.light.confirmed,
        StatusChipVariant.concern => DesignColors.light.concern,
        StatusChipVariant.failed => DesignColors.light.critical,
        StatusChipVariant.syncing => DesignColors.light.primary,
        StatusChipVariant.neutral => DesignColors.light.ink,
      };
      expect(icon.color, expected);
    });
  }
}
