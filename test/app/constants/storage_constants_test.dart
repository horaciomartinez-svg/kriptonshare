import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/app/constants/storage_constants.dart';

void main() {
  group('StorageConstants', () {
    test('freemiumMaxFileBytes es 10 MB', () {
      expect(StorageConstants.freemiumMaxFileBytes, 10 * 1024 * 1024);
    });

    test('premiumMaxFileBytes es 100 MB', () {
      expect(StorageConstants.premiumMaxFileBytes, 100 * 1024 * 1024);
    });

    test('premiumBaseStorageBytes es 1 GB', () {
      expect(StorageConstants.premiumBaseStorageBytes, 1073741824);
    });

    test('storageAddonBytes es 1 GB', () {
      expect(StorageConstants.storageAddonBytes, 1073741824);
    });

    test('freemiumMaxLinkHours es 48', () {
      expect(StorageConstants.freemiumMaxLinkHours, 48);
    });

    test('premiumMaxLinkDays es 30', () {
      expect(StorageConstants.premiumMaxLinkDays, 30);
    });
  });
}
