library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:shiftwise/app/theme/theme.dart';
import 'package:shiftwise/features/scan/image_source_gateway.dart';
import 'package:shiftwise/features/scan/scan_config.dart';
import 'package:shiftwise/features/scan/scan_screen.dart';
import 'package:shiftwise/features/scan/scan_state.dart';
import 'package:shiftwise/features/shift_edit/shift_edit_screen.dart';

class FakeImageSourceGateway implements ImageSourceGateway {
  FakeImageSourceGateway({this.pickResult, this.cropResult});

  PickedImage? pickResult;
  Uint8List? cropResult;

  @override
  Future<PickedImage?> pick({required bool fromCamera}) async => pickResult;

  @override
  Future<Uint8List?> crop(
    PickedImage image, {
    required BuildContext context,
  }) async => cropResult;
}

Uint8List _photo() {
  final image = img.Image(width: 240, height: 240);
  img.fill(image, color: img.ColorRgb8(120, 140, 160));
  return Uint8List.fromList(img.encodeJpg(image));
}

Widget pumpScan(FakeImageSourceGateway gateway) => ProviderScope(
  overrides: [imageSourceGatewayProvider.overrideWithValue(gateway)],
  child: MaterialApp.router(
    theme: ShiftWiseThemes.light,
    routerConfig: GoRouter(
      initialLocation: '/scan',
      routes: [
        GoRoute(
          path: '/shift-edit',
          builder: (_, _) => const ShiftEditScreen(),
        ),
        GoRoute(path: '/scan', builder: (_, _) => const ScanScreen()),
      ],
    ),
  ),
);

Future<void> _pickFlow(
  WidgetTester tester,
  FakeImageSourceGateway gateway,
) async {
  gateway
    ..pickResult = PickedImage(_photo(), '/tmp/schedule.jpg')
    ..cropResult = _photo();
  await tester.tap(find.text('Choose a photo'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('idle shows both sources and the manual fallback', (
    tester,
  ) async {
    await tester.pumpWidget(pumpScan(FakeImageSourceGateway()));
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose a photo'), findsOneWidget);
    expect(find.text('Enter a shift manually instead'), findsOneWidget);
    expect(find.textContaining('without your confirmation'), findsOneWidget);
  });

  testWidgets('consent shows the exact image and names the processor', (
    tester,
  ) async {
    final gateway = FakeImageSourceGateway();
    await tester.pumpWidget(pumpScan(gateway));
    await _pickFlow(tester, gateway);

    expect(find.text('Check your photo'), findsOneWidget);
    expect(find.textContaining('metadata removed'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Consent needed'), findsOneWidget);
    expect(
      find.textContaining(aiProcessorName),
      findsOneWidget,
      reason: 'consent copy must name the AI processor',
    );
    expect(
      find.textContaining('deleted after you confirm, or within 24 hours'),
      findsOneWidget,
      reason: 'consent copy must state the retention policy',
    );
  });

  testWidgets('declining consent discards and returns to idle', (tester) async {
    final gateway = FakeImageSourceGateway();
    await tester.pumpWidget(pumpScan(gateway));
    await _pickFlow(tester, gateway);

    await tester.tap(find.text('Discard the photo'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('consent leads to the ready state with the artifact', (
    tester,
  ) async {
    final gateway = FakeImageSourceGateway();
    await tester.pumpWidget(pumpScan(gateway));
    await _pickFlow(tester, gateway);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Ready to import'), findsOneWidget);
    expect(find.text('Prepared'), findsOneWidget);
    expect(
      find.textContaining('nothing has been sent anywhere'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a rejected image shows friendly copy plus fallbacks', (
    tester,
  ) async {
    final gateway = FakeImageSourceGateway()
      ..pickResult = PickedImage(
        Uint8List.fromList([0x47, 0x49, 0x46, 0x38]),
        '/tmp/schedule.gif',
      )
      ..cropResult = Uint8List.fromList([0x47, 0x49, 0x46, 0x38]);
    await tester.pumpWidget(pumpScan(gateway));

    await tester.tap(find.text('Choose a photo'));
    await tester.pumpAndSettle();
    expect(find.textContaining("isn't supported"), findsOneWidget);
    expect(find.text('Try another photo'), findsOneWidget);
    expect(find.text('Enter a shift manually instead'), findsOneWidget);
  });

  testWidgets('manual fallback opens the shift form', (tester) async {
    await tester.pumpWidget(pumpScan(FakeImageSourceGateway()));
    await tester.tap(find.text('Enter a shift manually instead'));
    await tester.pumpAndSettle();
    expect(find.text('Add shift'), findsOneWidget);
  });
}
