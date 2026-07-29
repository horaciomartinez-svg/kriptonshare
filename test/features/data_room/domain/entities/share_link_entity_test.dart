import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/features/data_room/domain/entities/share_link_entity.dart';

void main() {
  group('ShareLinkEntity', () {
    final now = DateTime.now();

    test('publicUrl genera URL de carpeta', () {
      final link = ShareLinkEntity(
        id: 'abc',
        createdBy: 'u1',
        folderId: 'f1',
        linkType: ShareLinkType.fullFolder,
        isActive: true,
        requireRecipientEmail: true,
        enableWatermark: true,
        expiresAt: now.add(const Duration(days: 30)),
        accessCount: 0,
        createdAt: now,
      );
      expect(link.publicUrl('key=xyz'), 'https://kriptonshare.com/f/abc#key=xyz');
    });

    test('publicUrl genera URL de archivo individual', () {
      final link = ShareLinkEntity(
        id: 'def',
        createdBy: 'u1',
        fileId: 'file1',
        linkType: ShareLinkType.singleFile,
        isActive: true,
        requireRecipientEmail: true,
        enableWatermark: true,
        expiresAt: now.add(const Duration(days: 30)),
        accessCount: 0,
        createdAt: now,
      );
      expect(link.publicUrl('key=xyz'), 'https://kriptonshare.com/d/def#key=xyz');
    });

    test('isExpired detecta expiración', () {
      final expired = ShareLinkEntity(
        id: 'g',
        createdBy: 'u1',
        fileId: 'file1',
        linkType: ShareLinkType.singleFile,
        isActive: true,
        requireRecipientEmail: true,
        enableWatermark: true,
        expiresAt: now.subtract(const Duration(days: 1)),
        accessCount: 0,
        createdAt: now.subtract(const Duration(days: 2)),
      );
      expect(expired.isExpired, isTrue);
    });
  });
}
