import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/models/kripton_file.dart';

void main() {
  group('KriptonFile', () {
    final baseJson = {
      'id': '00000000-0000-0000-0000-000000000001',
      'owner_id': '00000000-0000-0000-0000-000000000002',
      'original_filename': 'report.pdf',
      'file_size_bytes': 1024,
      'mime_type': 'application/pdf',
      'storage_provider': 'r2',
      'bucket_name': 'kriptonshare-ephemeral',
      'storage_object_key': '00000000-0000-0000-0000-000000000003',
      'aes_key_encrypted': '[1, 2, 3]',
      'salt': r'\x040506',
      'nonce': null,
      'mac_tag': null,
      'created_at': '2026-07-27T00:00:00.000Z',
      'expires_at': '2026-07-28T00:00:00.000Z',
    };

    test('round-trip base json', () {
      final file = KriptonFile.fromJson(baseJson);
      expect(file.id, '00000000-0000-0000-0000-000000000001');
      expect(file.originalFilename, 'report.pdf');
      expect(file.fileSizeBytes, 1024);
      expect(file.status, 'active');
      expect(file.maxDownloads, isNull);
      expect(file.downloadsCount, 0);
      expect(file.linkId, isNull);

      final json = file.toJson();
      expect(json['id'], file.id);
      expect(json['created_at'], '2026-07-27T00:00:00.000Z');
      expect(json['link_id'], isNull);
      expect(json['status'], 'active');
    });

    test('parses bytea as JSON array, hex and keeps nulls empty', () {
      final file = KriptonFile.fromJson(baseJson);
      expect(file.aesKeyEncrypted, [1, 2, 3]);
      expect(file.salt, [4, 5, 6]);
      expect(file.nonce, isEmpty);
      expect(file.macTag, isEmpty);
    });

    test('parses bytea as base64 string', () {
      final json = {...baseJson, 'aes_key_encrypted': 'TE0='};
      final file = KriptonFile.fromJson(json);
      expect(file.aesKeyEncrypted, [76, 77]);
    });

    test('parses bytea as a native int list', () {
      final json = {
        ...baseJson,
        'aes_key_encrypted': <int>[9, 8, 7],
      };
      final file = KriptonFile.fromJson(json);
      expect(file.aesKeyEncrypted, [9, 8, 7]);
    });

    test('rejects malformed bytea hex with odd length', () {
      final json = {...baseJson, 'salt': r'\x040'};
      expect(() => KriptonFile.fromJson(json), throwsFormatException);
    });

    test('round-trip with recipient link context', () {
      final json = {
        ...baseJson,
        'link_id': '00000000-0000-0000-0000-00000000000a',
        'link_expires_at': '2026-07-29T00:00:00.000Z',
        'recipient_email': 'friend@example.com',
        'is_active': true,
        'max_downloads': 3,
        'downloads_count': 1,
      };
      final file = KriptonFile.fromJson(json);
      expect(file.linkId, '00000000-0000-0000-0000-00000000000a');
      expect(file.recipientEmail, 'friend@example.com');
      expect(file.linkIsActive, isTrue);
      expect(file.maxDownloads, 3);
      expect(file.downloadsCount, 1);

      final out = file.toJson();
      expect(out['link_expires_at'], '2026-07-29T00:00:00.000Z');
      expect(out['is_active'], isTrue);
    });
  });

  group('ShareLink', () {
    final json = {
      'id': '00000000-0000-0000-0000-00000000000b',
      'file_id': '00000000-0000-0000-0000-000000000001',
      'created_by': '00000000-0000-0000-0000-000000000002',
      'pre_signed_url_hash': null,
      'expires_at': '2026-12-31T00:00:00.000Z',
      'access_count': 3,
      'last_accessed_at': null,
      'recipient_email': null,
      'is_active': false,
      'created_at': '2026-06-01T00:00:00.000Z',
    };

    test('round-trip', () {
      final link = ShareLink.fromJson(json);
      expect(link.id, json['id']);
      expect(link.fileId, json['file_id']);
      expect(link.accessCount, 3);
      expect(link.isActive, isFalse);

      final out = link.toJson();
      expect(out['is_active'], isFalse);
      expect(out['access_count'], 3);
      expect(out['expires_at'], json['expires_at']);
    });
  });

  group('EncryptedPayload', () {
    test('round-trip', () {
      final payload = EncryptedPayload(
        salt: const [1, 2],
        nonce: const [3, 4],
        ciphertext: const [5, 6, 7],
        authTag: const [8, 9],
        aesKeyEncrypted: const [10, 11],
      );

      final json = payload.toJson();
      final back = EncryptedPayload.fromJson(json);
      expect(back.salt, payload.salt);
      expect(back.nonce, payload.nonce);
      expect(back.ciphertext, payload.ciphertext);
      expect(back.authTag, payload.authTag);
      expect(back.aesKeyEncrypted, payload.aesKeyEncrypted);
    });
  });
}
