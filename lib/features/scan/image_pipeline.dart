/// Pure client-side cleaning of a schedule photo: sniff the type, cap the
/// size, decode, validate dimensions, and re-encode. Re-encoding
/// re-serializes pixels, so EXIF/location metadata cannot survive it —
/// that is the strip step from docs/architecture/ai-import.md. No plugin
/// or platform imports: everything here is unit-testable in plain Dart.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'scan_config.dart';

enum ScanRejection {
  unsupportedType,
  tooLarge,
  tooManyPixels,
  tooSmall,
  unreadable,
}

String scanRejectionMessage(ScanRejection rejection) => switch (rejection) {
  ScanRejection.unsupportedType =>
    "That file type isn't supported — use a JPEG or PNG photo.",
  ScanRejection.tooLarge => 'That photo is too large to import.',
  ScanRejection.tooManyPixels => 'That photo has too many pixels to import.',
  ScanRejection.tooSmall =>
    'That photo is too small to read — try a closer shot.',
  ScanRejection.unreadable => "That photo couldn't be read. Try retaking it.",
};

/// The cleaned, upload-ready artifact. JPEG by construction, which is what
/// the consent preview shows and what a later step uploads.
class ScanArtifact {
  const ScanArtifact({
    required this.cleanJpegBytes,
    required this.width,
    required this.height,
  });

  final Uint8List cleanJpegBytes;
  final int width;
  final int height;
}

sealed class ScheduleImageResult {
  const ScheduleImageResult();
}

final class CleanScheduleImage extends ScheduleImageResult {
  const CleanScheduleImage(this.artifact);

  final ScanArtifact artifact;
}

final class RejectedScheduleImage extends ScheduleImageResult {
  const RejectedScheduleImage(this.reason);

  final ScanRejection reason;
}

bool _isJpeg(Uint8List bytes) =>
    bytes.length > 3 &&
    bytes[0] == 0xFF &&
    bytes[1] == 0xD8 &&
    bytes[2] == 0xFF;

bool _isPng(Uint8List bytes) =>
    bytes.length > 8 &&
    bytes[0] == 0x89 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x4E &&
    bytes[3] == 0x47 &&
    bytes[4] == 0x0D &&
    bytes[5] == 0x0A &&
    bytes[6] == 0x1A &&
    bytes[7] == 0x0A;

ScheduleImageResult cleanScheduleImage(
  Uint8List bytes, {
  ScanLimits limits = const ScanLimits(),
}) {
  if (!_isJpeg(bytes) && !_isPng(bytes)) {
    return const RejectedScheduleImage(ScanRejection.unsupportedType);
  }
  if (bytes.length > limits.maxBytes) {
    return const RejectedScheduleImage(ScanRejection.tooLarge);
  }
  final image = img.decodeImage(bytes);
  if (image == null) {
    return const RejectedScheduleImage(ScanRejection.unreadable);
  }
  final width = image.width;
  final height = image.height;
  if (width * height > limits.maxPixels) {
    return const RejectedScheduleImage(ScanRejection.tooManyPixels);
  }
  if (width < limits.minSide || height < limits.minSide) {
    return const RejectedScheduleImage(ScanRejection.tooSmall);
  }
  final clean = img.encodeJpg(image, quality: 85);
  return CleanScheduleImage(
    ScanArtifact(
      cleanJpegBytes: Uint8List.fromList(clean),
      width: width,
      height: height,
    ),
  );
}
