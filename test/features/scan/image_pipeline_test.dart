library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shiftwise/features/scan/image_pipeline.dart';
import 'package:shiftwise/features/scan/scan_config.dart';

Uint8List _photo({int width = 240, int height = 240}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 140, 160));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

/// Splices an APP1 EXIF segment right after the JPEG SOI marker — the
/// shape a camera photo with GPS/EXIF metadata has.
Uint8List _withExif(Uint8List jpeg) {
  final exifPayload = <int>[
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
    0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // TIFF header
    0x00, 0x00, // no IFD entries
  ];
  final segmentLength = exifPayload.length + 2;
  return Uint8List.fromList([
    ...jpeg.sublist(0, 2),
    0xFF,
    0xE1,
    (segmentLength >> 8) & 0xFF,
    segmentLength & 0xFF,
    ...exifPayload,
    ...jpeg.sublist(2),
  ]);
}

void main() {
  test('accepts a photo and re-encodes it as JPEG', () {
    final result = cleanScheduleImage(_photo());
    expect(result, isA<CleanScheduleImage>());
    final artifact = (result as CleanScheduleImage).artifact;
    expect(artifact.width, 240);
    expect(artifact.height, 240);
    // JPEG magic on the artifact.
    expect(artifact.cleanJpegBytes[0], 0xFF);
    expect(artifact.cleanJpegBytes[1], 0xD8);
    expect(img.decodeImage(artifact.cleanJpegBytes), isNotNull);
  });

  test('re-encoding strips EXIF metadata (the privacy step)', () {
    final dirty = _withExif(_photo());
    expect(String.fromCharCodes(dirty).contains('Exif'), isTrue);

    final result = cleanScheduleImage(dirty);
    final artifact = (result as CleanScheduleImage).artifact;

    // Re-serialization cannot carry the APP1 payload: no Exif bytes, and
    // the marker right after SOI is not an EXIF APP1 (0xFFE1).
    expect(
      String.fromCharCodes(artifact.cleanJpegBytes).contains('Exif'),
      isFalse,
    );
    expect(artifact.cleanJpegBytes[2], isNot(0xE1));
    expect(img.decodeImage(artifact.cleanJpegBytes), isNotNull);
  });

  test('accepts PNG input and outputs cleaned JPEG', () {
    final image = img.Image(width: 300, height: 250);
    img.fill(image, color: img.ColorRgb8(10, 20, 30));
    final png = Uint8List.fromList(img.encodePng(image));

    final result = cleanScheduleImage(png);
    final artifact = (result as CleanScheduleImage).artifact;
    expect(artifact.width, 300);
    expect(artifact.height, 250);
    expect(artifact.cleanJpegBytes[0], 0xFF);
  });

  test('rejects unsupported file types before decoding', () {
    final gif = Uint8List.fromList([
      0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x02, // GIF89a
    ]);
    final result = cleanScheduleImage(gif);
    expect(
      result,
      isA<RejectedScheduleImage>().having(
        (it) => it.reason,
        'reason',
        ScanRejection.unsupportedType,
      ),
    );
  });

  test('rejects oversized files', () {
    final result = cleanScheduleImage(
      _photo(),
      limits: const ScanLimits(maxBytes: 100),
    );
    expect((result as RejectedScheduleImage).reason, ScanRejection.tooLarge);
  });

  test('rejects too many pixels', () {
    final result = cleanScheduleImage(
      _photo(),
      limits: const ScanLimits(maxPixels: 1000),
    );
    expect(
      (result as RejectedScheduleImage).reason,
      ScanRejection.tooManyPixels,
    );
  });

  test('rejects images too small to read', () {
    final result = cleanScheduleImage(
      _photo(width: 120, height: 240),
      limits: const ScanLimits(minSide: 200),
    );
    expect((result as RejectedScheduleImage).reason, ScanRejection.tooSmall);
  });

  test('rejects undecodable payloads with the right magic bytes', () {
    final corrupt = Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00,
      // ...and then garbage instead of a real scan.
      0x01, 0x02, 0x03, 0x04, 0x05,
    ]);
    final result = cleanScheduleImage(corrupt);
    expect((result as RejectedScheduleImage).reason, ScanRejection.unreadable);
  });

  test('every rejection has friendly copy', () {
    for (final rejection in ScanRejection.values) {
      expect(scanRejectionMessage(rejection), isNotEmpty);
    }
  });
}
