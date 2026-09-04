/// Loads the bundled Inter OTFs so goldens render real glyphs and real
/// tabular figures instead of a fallback face.
library;

import 'dart:io';

import 'package:flutter/services.dart';

Future<ByteData> _loadFont(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

Future<void> loadInterFonts() async {
  final loader = FontLoader('Inter')
    ..addFont(_loadFont('assets/fonts/Inter-Regular.otf'))
    ..addFont(_loadFont('assets/fonts/Inter-SemiBold.otf'));
  await loader.load();
}
