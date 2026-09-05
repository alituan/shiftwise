library;

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftwise/domain/schedule/shift.dart';
import 'package:shiftwise/features/schedule/data/shift_document.dart';

/// Builds a full 16-key document like the server would store — mirrors the
/// rules-tests and functions-test fixtures so all three suites stay in
/// sync on the shift schema.
Map<String, Object?> fullDocument({Object? overrides}) {
  final doc = <String, Object?>{
    'jobId': 'job-1',
    'startUtc': DateTime.utc(2026, 9, 4, 14),
    'endUtc': DateTime.utc(2026, 9, 4, 22),
    'timeZone': 'Africa/Kigali',
    'localWorkDate': '2026-09-04',
    'role': null,
    'location': null,
    'paidBreakMinutes': 0,
    'unpaidBreakMinutes': 30,
    'source': 'manual',
    'sourceParseJobId': null,
    'reviewStatus': 'confirmed',
    'revision': 1,
    'createdAt': DateTime.utc(2026, 9, 4, 9),
    'updatedAt': DateTime.utc(2026, 9, 4, 9),
    'updatedBy': 'device-test',
  };
  if (overrides is Map<String, Object?>) {
    doc.addAll(overrides);
  }
  return doc;
}

void main() {
  final shift = Shift.create(
    id: 'cafe',
    jobName: 'Cafe',
    start: DateTime.parse('2026-09-04T14:00:00+02:00'),
    end: DateTime.parse('2026-09-04T22:00:00+02:00'),
    breakMinutes: 30,
    ratePerHour: Decimal.parse('16.50'),
  );

  group('shiftToDocument', () {
    test('emits exactly the 13 client-written fields', () {
      final doc = shiftToDocument(
        shift,
        jobId: 'job-1',
        timeZone: 'Africa/Kigali',
        localWorkDate: '2026-09-04',
        revision: 1,
      );
      expect(doc.keys.toSet(), {
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
      });
    });

    test('maps the domain values with UTC conversion', () {
      final doc = shiftToDocument(
        shift,
        jobId: 'job-1',
        timeZone: 'Africa/Kigali',
        localWorkDate: '2026-09-04',
        revision: 3,
      );
      expect(doc['startUtc'], DateTime.utc(2026, 9, 4, 12));
      expect(doc['endUtc'], DateTime.utc(2026, 9, 4, 20));
      expect(doc['unpaidBreakMinutes'], 30);
      expect(doc['paidBreakMinutes'], 0);
      expect(doc['source'], 'manual');
      expect(doc['sourceParseJobId'], isNull);
      expect(doc['reviewStatus'], 'confirmed');
      expect(doc['revision'], 3);
    });

    test('client fields plus server fields cover the full schema', () {
      final clientPart = shiftToDocument(
        shift,
        jobId: 'job-1',
        timeZone: 'Africa/Kigali',
        localWorkDate: '2026-09-04',
        revision: 1,
      );
      final serverPart = {
        'createdAt': DateTime.utc(2026, 9, 4, 9),
        'updatedAt': DateTime.utc(2026, 9, 4, 9),
        'updatedBy': 'device-test',
      };
      expect(
        {...clientPart, ...serverPart}.keys.toSet(),
        shiftDocumentKeys.toSet(),
      );
    });
  });

  group('ShiftDocumentData.fromMap', () {
    test('parses a valid document', () {
      final data = ShiftDocumentData.fromMap(fullDocument());
      expect(data.jobId, 'job-1');
      expect(data.startUtc, DateTime.utc(2026, 9, 4, 14));
      expect(data.timeZone, 'Africa/Kigali');
      expect(data.unpaidBreakMinutes, 30);
      expect(data.revision, 1);
      expect(data.updatedBy, 'device-test');
    });

    test('round-trips unpaid break and revision', () {
      final doc = shiftToDocument(
        shift,
        jobId: 'job-1',
        timeZone: 'Africa/Kigali',
        localWorkDate: '2026-09-04',
        revision: 2,
      );
      final parsed = ShiftDocumentData.fromMap(
        fullDocument(overrides: {'revision': 2, 'unpaidBreakMinutes': 30}),
      );
      expect(parsed.unpaidBreakMinutes, doc['unpaidBreakMinutes']);
      expect(parsed.revision, doc['revision']);
    });

    test('rejects an unknown key', () {
      final doc = fullDocument(overrides: {'quota': 999});
      expect(() => ShiftDocumentData.fromMap(doc), throwsArgumentError);
    });

    test('rejects a missing key', () {
      final doc = fullDocument()..remove('timeZone');
      expect(() => ShiftDocumentData.fromMap(doc), throwsArgumentError);
    });

    test('rejects end at or before start', () {
      for (final end in [
        DateTime.utc(2026, 9, 4, 14),
        DateTime.utc(2026, 9, 4, 13),
      ]) {
        expect(
          () => ShiftDocumentData.fromMap(
            fullDocument(overrides: {'endUtc': end}),
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects unknown source or review status', () {
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(overrides: {'source': 'magic'}),
        ),
        throwsArgumentError,
      );
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(overrides: {'reviewStatus': 'draft'}),
        ),
        throwsArgumentError,
      );
    });

    test('rejects revision below 1 and non-int breaks', () {
      expect(
        () =>
            ShiftDocumentData.fromMap(fullDocument(overrides: {'revision': 0})),
        throwsArgumentError,
      );
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(overrides: {'unpaidBreakMinutes': -1}),
        ),
        throwsArgumentError,
      );
    });

    test('rejects scanned shifts without a parse job reference', () {
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(overrides: {'source': 'scanned'}),
        ),
        throwsArgumentError,
      );
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(
            overrides: {'source': 'scanned', 'sourceParseJobId': 'job-9'},
          ),
        ),
        returnsNormally,
      );
    });

    test('rejects malformed timezone and local date', () {
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(overrides: {'timeZone': ''}),
        ),
        throwsArgumentError,
      );
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(overrides: {'localWorkDate': '09/04/2026'}),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a missing or empty updatedBy device id', () {
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(overrides: {'updatedBy': null}),
        ),
        throwsArgumentError,
      );
      expect(
        () => ShiftDocumentData.fromMap(
          fullDocument(overrides: {'updatedBy': ''}),
        ),
        throwsArgumentError,
      );
    });
  });
}
