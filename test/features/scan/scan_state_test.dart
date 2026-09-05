library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shiftwise/features/scan/image_pipeline.dart';
import 'package:shiftwise/features/scan/image_source_gateway.dart';
import 'package:shiftwise/features/scan/scan_state.dart';

class FakeImageSourceGateway implements ImageSourceGateway {
  FakeImageSourceGateway({this.pickResult, this.cropResult});

  PickedImage? pickResult;
  Uint8List? cropResult;
  bool pickCancelled = false;
  bool cropCancelled = false;
  final List<String> calls = <String>[];

  @override
  Future<PickedImage?> pick({required bool fromCamera}) async {
    calls.add('pick:$fromCamera');
    return pickCancelled ? null : pickResult;
  }

  @override
  Future<Uint8List?> crop(
    PickedImage image, {
    required BuildContext context,
  }) async {
    calls.add('crop');
    return cropCancelled ? null : cropResult;
  }
}

Uint8List _photo() {
  final image = img.Image(width: 240, height: 240);
  img.fill(image, color: img.ColorRgb8(120, 140, 160));
  return Uint8List.fromList(img.encodeJpg(image));
}

PickedImage get _picked => PickedImage(_photo(), '/tmp/schedule.jpg');

/// Pumps a minimal tree to hand the state machine a real BuildContext.
Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        captured = context;
        return const SizedBox();
      },
    ),
  );
  return captured;
}

void main() {
  late FakeImageSourceGateway gateway;
  late ProviderContainer container;

  setUp(() {
    gateway = FakeImageSourceGateway();
    container = ProviderContainer(
      overrides: [imageSourceGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
  });

  Future<void> run(WidgetTester tester) async {
    final context = await _context(tester);
    await container
        .read(scanSessionProvider.notifier)
        .pickAndPrepare(fromCamera: false, context: context);
  }

  test('starts idle', () {
    expect(container.read(scanSessionProvider).phase, ScanPhase.idle);
  });

  testWidgets('pick → crop → clean lands on consent with the artifact', (
    tester,
  ) async {
    gateway
      ..pickResult = _picked
      ..cropResult = _photo();
    await run(tester);
    final state = container.read(scanSessionProvider);
    expect(state.phase, ScanPhase.consent);
    expect(state.artifact, isNotNull);
    expect(state.artifact!.width, 240);
    expect(gateway.calls, ['pick:false', 'crop']);
  });

  testWidgets('cancelling the picker returns to idle', (tester) async {
    gateway.pickCancelled = true;
    await run(tester);
    final state = container.read(scanSessionProvider);
    expect(state.phase, ScanPhase.idle);
    expect(state.artifact, isNull);
  });

  testWidgets('cancelling the crop returns to idle', (tester) async {
    gateway
      ..pickResult = _picked
      ..cropCancelled = true;
    await run(tester);
    expect(container.read(scanSessionProvider).phase, ScanPhase.idle);
  });

  testWidgets('a rejected image lands on failed with its reason', (
    tester,
  ) async {
    gateway
      ..pickResult = _picked
      ..cropResult = Uint8List.fromList([0x47, 0x49, 0x46, 0x38]);
    await run(tester);
    final state = container.read(scanSessionProvider);
    expect(state.phase, ScanPhase.failed);
    expect(state.rejection, ScanRejection.unsupportedType);
    expect(state.artifact, isNull);
  });

  testWidgets('declining consent discards the artifact immediately', (
    tester,
  ) async {
    gateway
      ..pickResult = _picked
      ..cropResult = _photo();
    await run(tester);
    container.read(scanSessionProvider.notifier).discard();
    final state = container.read(scanSessionProvider);
    expect(state.phase, ScanPhase.idle);
    expect(state.artifact, isNull);
  });

  testWidgets('consent moves the prepared artifact to ready', (tester) async {
    gateway
      ..pickResult = _picked
      ..cropResult = _photo();
    await run(tester);
    container.read(scanSessionProvider.notifier).consent();
    final state = container.read(scanSessionProvider);
    expect(state.phase, ScanPhase.ready);
    expect(state.artifact, isNotNull);
  });

  testWidgets('restart from failed returns to idle', (tester) async {
    gateway
      ..pickResult = _picked
      ..cropResult = Uint8List.fromList([0x47, 0x49, 0x46, 0x38]);
    await run(tester);
    container.read(scanSessionProvider.notifier).restart();
    expect(container.read(scanSessionProvider).phase, ScanPhase.idle);
  });
}
