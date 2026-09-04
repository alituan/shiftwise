library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/app/app.dart';
import 'package:shiftwise/app/theme/tokens.dart';

void main() {
  testWidgets('boots to the Schedule screen in guest mode', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShiftWiseApp()));
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('No shifts yet'), findsOneWidget);
    expect(find.text('Add a shift'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('follows system brightness with the matching palette', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(
      () => tester.platformDispatcher.clearPlatformBrightnessTestValue(),
    );
    await tester.pumpWidget(const ProviderScope(child: ShiftWiseApp()));
    final context = tester.element(find.text('No shifts yet'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      Theme.of(context).extension<DesignColors>(),
      same(DesignColors.dark),
    );
    expect(Theme.of(context).extension<DesignType>(), same(DesignType.dark));
  });
}
