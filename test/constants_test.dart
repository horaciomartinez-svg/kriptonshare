import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/core/utils/constants.dart';

void main() {
  group('Constants', () {
    test('AppConstants has correct values', () {
      expect(AppConstants.aesKeySize, 32);
      expect(AppConstants.aesNonceSize, 12);
      expect(AppConstants.aesTagSize, 16);
      expect(AppConstants.chunkSize, 256 * 1024);
    });
  });
}