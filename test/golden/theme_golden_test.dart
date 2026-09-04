/// Golden baseline for the token system itself — type scale, hairline
/// divider, surfaceDim fills, and status icon+label pairing — in both
/// palettes, so design-system drift is caught from Phase 1 onward.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/app/theme/tokens.dart';

Future<ByteData> _loadFont(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

void main() {
  // Bundled OTFs loaded straight from disk so the goldens render real Inter
  // glyphs — including real tabular figures — instead of a fallback face.
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(_loadFont('assets/fonts/Inter-Regular.otf'))
      ..addFont(_loadFont('assets/fonts/Inter-SemiBold.otf'));
    await loader.load();
  });

  testGoldens('token showcase — light palette', (tester) async {
    await tester.pumpWidgetBuilder(
      MaterialApp(theme: ShiftWiseThemes.light, home: const _TokenShowcase()),
      surfaceSize: const Size(412, 640),
    );
    await screenMatchesGolden(tester, 'tokens_light');
  });

  testGoldens('token showcase — dark palette', (tester) async {
    await tester.pumpWidgetBuilder(
      MaterialApp(
        theme: ShiftWiseThemes.light,
        darkTheme: ShiftWiseThemes.dark,
        themeMode: ThemeMode.dark,
        home: const _TokenShowcase(),
      ),
      surfaceSize: const Size(412, 640),
    );
    await screenMatchesGolden(tester, 'tokens_dark');
  });
}

class _TokenShowcase extends StatelessWidget {
  const _TokenShowcase();

  @override
  Widget build(BuildContext context) {
    final colors = context.designColors;
    final type = context.designType;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tue · 2:00–10:00 PM', style: type.hero),
              Text(
                'in 3h 12m',
                style: type.hero.copyWith(color: colors.primary),
              ),
              const SizedBox(height: Tokens.spaceMd),
              Text('Screen title', style: type.title),
              const SizedBox(height: Tokens.spaceSm),
              Text('Body row 0123456789', style: type.body),
              Text('Helper label 0123456789', style: type.label),
              const SizedBox(height: Tokens.spaceLg),
              const Divider(),
              const SizedBox(height: Tokens.spaceLg),
              Container(
                width: double.infinity,
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
                    const SizedBox(height: Tokens.spaceSm),
                    _StatusRow(colors: colors, type: type),
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.colors, required this.type});

  final DesignColors colors;
  final DesignType type;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Tokens.spaceSm,
      runSpacing: Tokens.spaceSm,
      children: [
        _status(Icons.check_circle, colors.confirmed, 'Confirmed', type.label),
        _status(
          Icons.warning_amber_rounded,
          colors.concern,
          'Concern',
          type.label,
        ),
        _status(
          Icons.error_outline_rounded,
          colors.critical,
          'Error',
          type.label,
        ),
      ],
    );
  }

  Widget _status(IconData icon, Color color, String label, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Tokens.space2xs),
        Text(label, style: style),
      ],
    );
  }
}
