import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/features/data_room/domain/entities/file_entity.dart';
import 'package:kriptonshare/features/data_room/domain/entities/folder_entity.dart';

void main() {
  group('FolderEntity', () {
    final file = FileEntity(
      id: '1',
      ownerId: 'u1',
      originalFilename: 'a.pdf',
      fileSizeBytes: 100 * 1024 * 1024,
      mimeType: 'application/pdf',
      storageObjectKey: 'k1',
      salt: const {'bytes': <int>[]},
      nonce: const {'bytes': <int>[]},
      macTag: const {'bytes': <int>[]},
      aesKeyEncrypted: const {'bytes': <int>[]},
      createdAt: DateTime.now(),
    );

    final folder = FolderEntity(
      id: 'f1',
      ownerId: 'u1',
      name: 'Carpeta',
      files: [file],
      totalSizeBytes: file.fileSizeBytes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('totalSizeInMB calcula correctamente', () {
      expect(folder.totalSizeInMB, closeTo(100.0, 0.01));
    });

    test('storagePercentage se clamp entre 0 y 1', () {
      expect(folder.storagePercentage, closeTo(0.093, 0.001));
    });
  });
}
