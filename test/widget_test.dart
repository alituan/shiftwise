library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/app.dart';
import 'package:shiftwise/app/theme/tokens.dart';

void main() {
  testWidgets('boots to the Phase-1 theme placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShiftWiseApp()));
    expect(find.text('ShiftWise'), findsOneWidget);
    expect(find.text('Tue · 2:00–10:00 PM'), findsOneWidget);
    expect(find.text(r'Estimated gross pay: $124.00'), findsOneWidget);
  });

  testWidgets('follows system brightness with the matching palette', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(
      () => tester.platformDispatcher.clearPlatformBrightnessTestValue(),
    );
    await tester.pumpWidget(const ProviderScope(child: ShiftWiseApp()));
    final context = tester.element(find.text('Tue · 2:00–10:00 PM'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      Theme.of(context).extension<DesignColors>(),
      same(DesignColors.dark),
    );
    expect(Theme.of(context).extension<DesignType>(), same(DesignType.dark));
  });
}
