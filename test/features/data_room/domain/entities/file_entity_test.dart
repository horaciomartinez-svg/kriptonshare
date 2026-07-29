import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/features/data_room/domain/entities/file_entity.dart';

void main() {
  group('FileEntity', () {
    final entity = FileEntity(
      id: '1',
      ownerId: 'user-1',
      originalFilename: 'test.pdf',
      fileSizeBytes: 50 * 1024 * 1024,
      mimeType: 'application/pdf',
      storageObjectKey: 'key-1',
      salt: const {'bytes': <int>[]},
      nonce: const {'bytes': <int>[]},
      macTag: const {'bytes': <int>[]},
      aesKeyEncrypted: const {'bytes': <int>[]},
      createdAt: DateTime.now(),
    );

    test('isWithinPremiumLimit es true para 50 MB', () {
      expect(entity.isWithinPremiumLimit, isTrue);
    });

    test('isWithinPremiumLimit es false para 101 MB', () {
      final big = FileEntity(
        id: '2',
        ownerId: 'user-1',
        originalFilename: 'big.zip',
        fileSizeBytes: 101 * 1024 * 1024,
        mimeType: 'application/zip',
        storageObjectKey: 'key-2',
        salt: const {'bytes': <int>[]},
        nonce: const {'bytes': <int>[]},
        macTag: const {'bytes': <int>[]},
        aesKeyEncrypted: const {'bytes': <int>[]},
        createdAt: DateTime(2026),
      );
      expect(big.isWithinPremiumLimit, isFalse);
    });

    test('sizeInMB calcula correctamente', () {
      expect(entity.sizeInMB, closeTo(50.0, 0.01));
    });
  });
}
