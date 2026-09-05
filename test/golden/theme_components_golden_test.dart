/// Golden baselines for the pinned theme itself — the themed framework
/// widgets (stage A). Screens and the custom App* library are NOT here:
/// their goldens return with stages B and C. Light and dark palettes, per
/// docs/design/tokens.md's golden requirement.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/app/theme/tokens.dart';

import '../support/golden_fonts.dart';

void main() {
  setUpAll(loadInterFonts);

  testGoldens('pinned theme components — light palette', (tester) async {
    await tester.pumpWidgetBuilder(
      _showcase(ThemeMode.light),
      surfaceSize: const Size(412, 1200),
    );
    await screenMatchesGolden(tester, 'theme_components_light');
  });

  testGoldens('pinned theme components — dark palette', (tester) async {
    await tester.pumpWidgetBuilder(
      _showcase(ThemeMode.dark),
      surfaceSize: const Size(412, 1200),
    );
    await screenMatchesGolden(tester, 'theme_components_dark');
  });
}

Widget _showcase(ThemeMode mode) => MaterialApp(
  theme: ShiftWiseThemes.light,
  darkTheme: ShiftWiseThemes.dark,
  themeMode: mode,
  home: const _ThemeComponentsShowcase(),
);

class _ThemeComponentsShowcase extends StatefulWidget {
  const _ThemeComponentsShowcase();

  @override
  State<_ThemeComponentsShowcase> createState() =>
      _ThemeComponentsShowcaseState();
}

class _ThemeComponentsShowcaseState extends State<_ThemeComponentsShowcase>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final type = context.designType;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themed app bar'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'One'),
            Tab(text: 'Two'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Tokens.spaceMd),
        children: [
          Text('Buttons', style: type.title),
          const SizedBox(height: Tokens.spaceXs),
          FilledButton(onPressed: () {}, child: const Text('Filled')),
          const SizedBox(height: Tokens.spaceXs),
          ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
          const SizedBox(height: Tokens.spaceXs),
          OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
          const SizedBox(height: Tokens.spaceXs),
          TextButton(onPressed: () {}, child: const Text('Text')),
          const SizedBox(height: Tokens.spaceXs),
          FloatingActionButton.small(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: Tokens.spaceLg),
          Text('Input', style: type.title),
          const SizedBox(height: Tokens.spaceXs),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Underline field',
              helperText: 'helper text',
            ),
          ),
          const SizedBox(height: Tokens.spaceXs),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Error field',
              errorText: 'error text',
            ),
          ),
          const SizedBox(height: Tokens.spaceLg),
          Text('Selection', style: type.title),
          const SizedBox(height: Tokens.spaceXs),
          const Row(
            children: [
              Switch(value: true, onChanged: null),
              SizedBox(width: Tokens.spaceMd),
              Switch(value: false, onChanged: null),
            ],
          ),
          const SizedBox(height: Tokens.spaceXs),
          Row(
            children: [
              const Checkbox(value: true, onChanged: null),
              const Checkbox(value: false, onChanged: null),
              const SizedBox(width: Tokens.spaceMd),
              RadioGroup<bool>(
                groupValue: true,
                onChanged: (_) {},
                child: const Row(
                  children: [
                    Radio<bool>(value: true),
                    Radio<bool>(value: false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceLg),
          Text('Surfaces', style: type.title),
          const SizedBox(height: Tokens.spaceXs),
          Card(
            child: Padding(
              padding: EdgeInsets.all(Tokens.spaceMd),
              child: Text('Card', style: type.body),
            ),
          ),
          const SizedBox(height: Tokens.spaceXs),
          Chip(
            avatar: const Icon(Icons.check, size: 18),
            label: Text('Chip', style: type.label),
          ),
          const SizedBox(height: Tokens.spaceXs),
          const Divider(),
          const SizedBox(height: Tokens.spaceLg),
          Text('Feedback', style: type.title),
          const SizedBox(height: Tokens.spaceXs),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(value: 0.6),
          ),
          const SizedBox(height: Tokens.spaceXs),
          const SizedBox(
            width: 40,
            height: 40,
            // Determinate so the golden capture can settle — an animating
            // spinner would make pumpAndSettle time out.
            child: CircularProgressIndicator(value: 0.7, strokeWidth: 3),
          ),
          const SizedBox(height: Tokens.spaceXs),
          Tooltip(
            message: 'Tooltip',
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: Tokens.spaceLg),
          Text('Sheet & dialog', style: type.title),
          const SizedBox(height: Tokens.spaceXs),
          Dialog(
            child: Padding(
              padding: EdgeInsets.all(Tokens.spaceMd),
              child: Text('Dialog', style: type.body),
            ),
          ),
        ],
      ),
    );
  }
}
