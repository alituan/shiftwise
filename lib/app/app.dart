/// Root widget for ShiftWise.
library;

import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/theme.dart';

/// Theme source is the system default on first launch (docs/design/tokens.md);
/// the manual Settings override and its persistence land later in Phase 1.
class ShiftWiseApp extends StatelessWidget {
  const ShiftWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShiftWise',
      debugShowCheckedModeBanner: false,
      theme: ShiftWiseThemes.light,
      darkTheme: ShiftWiseThemes.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
