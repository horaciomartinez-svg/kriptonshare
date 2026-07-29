import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/models/kripton_file.dart';

void main() {
  group('KriptonFile', () {
    final baseJson = {
      'id': '00000000-0000-0000-0000-000000000001',
      'owner_id': '00000000-0000-0000-0000-000000000002',
      'original_filename': 'report.docx',
      'file_size_bytes': 1024,
      'mime_type': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'storage_provider': 'r2',
      'bucket_name': 'kriptonshare-ephemeral',
      'storage_object_key': '00000000-0000-0000-0000-000000000003',
      'created_at': '2026-07-27T00:00:00.000Z',
      'expires_at': '2026-07-28T00:00:00.000Z',
    };

    test('round-trip without preview columns', () {
      final file = KriptonFile.fromJson(baseJson);
      expect(file.hasPdfPreview, isFalse);
      expect(file.conversionStatus, 'none');
      expect(file.viewerObjectKey, isNull);

      final json = file.toJson();
      expect(json['conversion_status'], 'none');
      expect(json['viewer_object_key'], isNull);
    });

    test('round-trip with ready preview', () {
      final json = {
        ...baseJson,
        'viewer_object_key': '00000000-0000-0000-0000-000000000004',
        'viewer_file_size_bytes': 512,
        'conversion_status': 'ready',
      };
      final file = KriptonFile.fromJson(json);
      expect(file.hasPdfPreview, isTrue);
      expect(file.viewerObjectKey, '00000000-0000-0000-0000-000000000004');
      expect(file.viewerFileSizeBytes, 512);

      final out = file.toJson();
      expect(out['conversion_status'], 'ready');
      expect(out['viewer_file_size_bytes'], 512);
    });

    test('hasPdfPreview is false for pending/failed/none', () {
      for (final status in ['none', 'pending', 'failed']) {
        final json = {
          ...baseJson,
          'viewer_object_key': '00000000-0000-0000-0000-000000000004',
          'conversion_status': status,
        };
        final file = KriptonFile.fromJson(json);
        expect(file.hasPdfPreview, isFalse, reason: 'status $status should not have preview');
      }
    });

    test('hasPdfPreview is false when viewer_object_key is null even if ready', () {
      final json = {
        ...baseJson,
        'viewer_object_key': null,
        'conversion_status': 'ready',
      };
      final file = KriptonFile.fromJson(json);
      expect(file.hasPdfPreview, isFalse);
    });
  });
}
