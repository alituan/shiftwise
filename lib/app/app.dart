/// Root widget for ShiftWise.
library;

import 'package:flutter/material.dart';

import 'theme/theme.dart';
import 'theme/tokens.dart';

/// Theme source is the system default on first launch (docs/design/tokens.md);
/// the manual Settings override and its persistence land later in Phase 1.
class ShiftWiseApp extends StatelessWidget {
  const ShiftWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftWise',
      debugShowCheckedModeBanner: false,
      theme: ShiftWiseThemes.light,
      darkTheme: ShiftWiseThemes.dark,
      themeMode: ThemeMode.system,
      home: const _ThemeSmokeHome(),
    );
  }
}

/// Temporary Phase-1 placeholder: exercises every token family and gives the
/// preview something to render. Replaced by the Schedule screen later in
/// Phase 1.
class _ThemeSmokeHome extends StatelessWidget {
  const _ThemeSmokeHome();

  @override
  Widget build(BuildContext context) {
    final colors = context.designColors;
    final type = context.designType;
    return Scaffold(
      appBar: AppBar(title: const Text('ShiftWise')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next shift', style: type.label),
              const SizedBox(height: Tokens.spaceXs),
              Text('Tue · 2:00–10:00 PM', style: type.hero),
              Text(
                'in 3h 12m',
                style: type.hero.copyWith(color: colors.primary),
              ),
              const SizedBox(height: Tokens.spaceLg),
              const Divider(),
              const SizedBox(height: Tokens.spaceLg),
              Container(
                padding: const EdgeInsets.all(Tokens.spaceMd),
                decoration: BoxDecoration(
                  color: colors.surfaceDim,
                  borderRadius: BorderRadius.circular(Tokens.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's hours: 8.0", style: type.body),
                    Text(r'Estimated gross pay: $124.00', style: type.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
