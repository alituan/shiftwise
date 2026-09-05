/// Pure-Dart mapping between the domain [Shift] and the Firestore shift
/// document schema (docs/architecture/data-model.md).
///
/// No Firestore SDK import: the sync step composes this with
/// cloud_firestore converters, keeping the schema unit-testable without
/// emulators. `shiftToDocument` emits the 13 client-provided fields —
/// `createdAt`/`updatedAt` are server-set (serverTimestamp) on the write
/// path, so they appear only in parsed documents.
///
/// This file mirrors the schema enforced by `firebase/firestore.rules`;
/// keep both in sync — the rules-tests suite and the Dart unit tests hold
/// them to the same shape.
library;

import 'package:shiftwise/domain/schedule/shift.dart';

const List<String> shiftDocumentKeys = [
  'jobId',
  'startUtc',
  'endUtc',
  'timeZone',
  'localWorkDate',
  'role',
  'location',
  'paidBreakMinutes',
  'unpaidBreakMinutes',
  'source',
  'sourceParseJobId',
  'reviewStatus',
  'revision',
  'createdAt',
  'updatedAt',
  'updatedBy',
];

/// Client-written fields for a manual shift. The device IANA zone and the
/// zone-derived local work date are explicit inputs — deciding the device
/// timezone source belongs to the sync step, where they are consumed.
Map<String, Object?> shiftToDocument(
  Shift shift, {
  required String jobId,
  required String timeZone,
  required String localWorkDate,
  required int revision,
}) {
  return {
    'jobId': jobId,
    'startUtc': shift.start.toUtc(),
    'endUtc': shift.end.toUtc(),
    'timeZone': timeZone,
    'localWorkDate': localWorkDate,
    'role': null,
    'location': null,
    'paidBreakMinutes': 0,
    'unpaidBreakMinutes': shift.breakMinutes,
    'source': 'manual',
    'sourceParseJobId': null,
    'reviewStatus': 'confirmed',
    'revision': revision,
  };
}

/// Typed, validated view of a persisted shift document. Throws
/// [ArgumentError] on anything the rules would reject — unknown or missing
/// fields, wrong types, `end` at or before `start`, bad enums, non-monotonic
/// revision — so malformed data fails at the app boundary instead of deep
/// in a screen.
class ShiftDocumentData {
  const ShiftDocumentData({
    required this.jobId,
    required this.startUtc,
    required this.endUtc,
    required this.timeZone,
    required this.localWorkDate,
    required this.role,
    required this.location,
    required this.paidBreakMinutes,
    required this.unpaidBreakMinutes,
    required this.source,
    required this.sourceParseJobId,
    required this.reviewStatus,
    required this.revision,
    required this.updatedBy,
  });

  final String jobId;
  final DateTime startUtc;
  final DateTime endUtc;
  final String timeZone;
  final String localWorkDate;
  final String? role;
  final String? location;
  final int paidBreakMinutes;
  final int unpaidBreakMinutes;
  final String source;
  final String? sourceParseJobId;
  final String reviewStatus;
  final int revision;

  /// Locally-generated device id that last wrote the shift — never shown
  /// to the user; powers "your other device changed this" copy.
  final String updatedBy;

  static ShiftDocumentData fromMap(Map<String, Object?> map) {
    final keys = map.keys.toSet();
    final missing = shiftDocumentKeys.where((key) => !keys.contains(key));
    if (missing.isNotEmpty) {
      throw ArgumentError.value(map, 'map', 'missing keys: $missing');
    }
    final unknown = keys.difference(shiftDocumentKeys.toSet());
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(map, 'map', 'unknown keys: $unknown');
    }

    final jobId = map['jobId'];
    if (jobId is! String || jobId.isEmpty) {
      throw ArgumentError.value(jobId, 'jobId', 'must be a non-empty string');
    }
    final startUtc = map['startUtc'];
    if (startUtc is! DateTime) {
      throw ArgumentError.value(startUtc, 'startUtc', 'must be a DateTime');
    }
    final endUtc = map['endUtc'];
    if (endUtc is! DateTime) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be a DateTime');
    }
    if (!endUtc.isAfter(startUtc)) {
      throw ArgumentError('endUtc must be after startUtc');
    }
    final timeZone = map['timeZone'];
    if (timeZone is! String ||
        !RegExp(r'^[A-Za-z0-9_+/-]+$').hasMatch(timeZone)) {
      throw ArgumentError.value(
        timeZone,
        'timeZone',
        'must be an IANA-style zone id',
      );
    }
    final localWorkDate = map['localWorkDate'];
    if (localWorkDate is! String ||
        !RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(localWorkDate)) {
      throw ArgumentError.value(
        localWorkDate,
        'localWorkDate',
        'must be YYYY-MM-DD',
      );
    }
    final role = map['role'];
    if (role != null && role is! String) {
      throw ArgumentError.value(role, 'role', 'must be a string or null');
    }
    final location = map['location'];
    if (location != null && location is! String) {
      throw ArgumentError.value(
        location,
        'location',
        'must be a string or null',
      );
    }
    final paidBreakMinutes = map['paidBreakMinutes'];
    if (paidBreakMinutes is! int || paidBreakMinutes < 0) {
      throw ArgumentError.value(
        paidBreakMinutes,
        'paidBreakMinutes',
        'must be an int >= 0',
      );
    }
    final unpaidBreakMinutes = map['unpaidBreakMinutes'];
    if (unpaidBreakMinutes is! int || unpaidBreakMinutes < 0) {
      throw ArgumentError.value(
        unpaidBreakMinutes,
        'unpaidBreakMinutes',
        'must be an int >= 0',
      );
    }
    final source = map['source'];
    if (source is! String || !['manual', 'scanned'].contains(source)) {
      throw ArgumentError.value(source, 'source', 'must be manual or scanned');
    }
    final sourceParseJobId = map['sourceParseJobId'];
    if (source == 'manual' && sourceParseJobId != null) {
      throw ArgumentError.value(
        sourceParseJobId,
        'sourceParseJobId',
        'must be null for manual shifts',
      );
    }
    if (source == 'scanned' && sourceParseJobId is! String) {
      throw ArgumentError.value(
        sourceParseJobId,
        'sourceParseJobId',
        'must reference the parse job for scanned shifts',
      );
    }
    final reviewStatus = map['reviewStatus'];
    if (reviewStatus != 'confirmed') {
      throw ArgumentError.value(
        reviewStatus,
        'reviewStatus',
        "user shift documents are always 'confirmed'",
      );
    }
    final revision = map['revision'];
    if (revision is! int || revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be an int >= 1');
    }
    final updatedBy = map['updatedBy'];
    if (updatedBy is! String || updatedBy.isEmpty) {
      throw ArgumentError.value(
        updatedBy,
        'updatedBy',
        'must be a non-empty device id string',
      );
    }
    return ShiftDocumentData(
      jobId: jobId,
      startUtc: startUtc,
      endUtc: endUtc,
      timeZone: timeZone,
      localWorkDate: localWorkDate,
      role: role as String?,
      location: location as String?,
      paidBreakMinutes: paidBreakMinutes,
      unpaidBreakMinutes: unpaidBreakMinutes,
      source: source,
      sourceParseJobId: sourceParseJobId as String?,
      reviewStatus: reviewStatus as String,
      revision: revision,
      updatedBy: updatedBy,
    );
  }
}
