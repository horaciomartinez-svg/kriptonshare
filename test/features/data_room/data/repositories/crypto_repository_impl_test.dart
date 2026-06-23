import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/features/data_room/data/repositories/crypto_repository_impl.dart';
import 'package:kriptonshare/services/crypto_service.dart';

void main() {
  late CryptoService cryptoService;
  late CryptoRepositoryImpl repository;

  setUp(() {
    cryptoService = CryptoService();
    repository = CryptoRepositoryImpl(cryptoService);
  });

  group('CryptoService direct', () {
    test('should encrypt and decrypt directly', () {
      final plaintext = utf8.encode('hello world');
      final salt = cryptoService.generateSalt();
      final key = cryptoService.deriveKey('password', salt);
      final nonce = cryptoService.generateNonce();
      final encrypted = cryptoService.encrypt(
        plaintext: Uint8List.fromList(plaintext),
        key: key,
        nonce: nonce,
      );
      final decrypted = cryptoService.decrypt(
        ciphertext: encrypted['ciphertext']!,
        key: key,
        nonce: nonce,
        authTag: encrypted['authTag']!,
      );
      expect(decrypted.toList(), plaintext);
    });
  });

  group('CryptoRepositoryImpl', () {
    test('should encrypt and decrypt data successfully', () async {
      // Arrange
      final plaintext = utf8.encode('Documento confidencial de KRIPTONSHARE');
      final salt = cryptoService.generateSalt();
      final key = cryptoService.deriveKey('user-password', salt);

      // Act
      final encryptResult = await repository.encrypt(
        data: plaintext,
        key: key,
      );

      // Assert encryption success
      expect(encryptResult.isRight(), true);
      final encryptedData = encryptResult.getOrElse(() => []);
      expect(encryptedData.isNotEmpty, true);
      expect(encryptedData.length, greaterThan(plaintext.length));

      // Act decrypt
      final decryptResult = await repository.decrypt(
        encryptedData: encryptedData,
        key: key,
      );

      // Assert decryption success
      expect(decryptResult.isRight(), true);
      final decrypted = decryptResult.getOrElse(() => []);
      expect(decrypted, plaintext);
    });

    test('should return CryptoFailure when decrypting with wrong key', () async {
      // Arrange
      final plaintext = utf8.encode('Documento confidencial de KRIPTONSHARE');
      final correctSalt = cryptoService.generateSalt();
      final correctKey = cryptoService.deriveKey('correct-password', correctSalt);
      final wrongSalt = cryptoService.generateSalt();
      final wrongKey = cryptoService.deriveKey('wrong-password', wrongSalt);

      final encryptResult = await repository.encrypt(
        data: plaintext,
        key: correctKey,
      );
      final encryptedData = encryptResult.getOrElse(() => []);

      // Act
      final decryptResult = await repository.decrypt(
        encryptedData: encryptedData,
        key: wrongKey,
      );

      // Assert
      expect(decryptResult.isLeft(), true);
    });

    test('should generate and parse secure fragment', () async {
      // Act
      final fragmentResult = await repository.generateSecureFragment();

      // Assert
      expect(fragmentResult.isRight(), true);
      final fragment = fragmentResult.getOrElse(() => '');
      expect(fragment.startsWith('key='), true);

      // Act parse
      final keyResult = await repository.deriveKeyFromFragment(fragment);

      // Assert
      expect(keyResult.isRight(), true);
      expect(keyResult.getOrElse(() => []).isNotEmpty, true);
    });

    test('should return CryptoFailure for invalid fragment format', () async {
      // Act
      final result = await repository.deriveKeyFromFragment('invalid');

      // Assert
      expect(result.isLeft(), true);
    });

    test('should hash data consistently', () async {
      // Arrange
      final data = utf8.encode('test data');

      // Act
      final result1 = await repository.hash(data);
      final result2 = await repository.hash(data);

      // Assert
      expect(result1.isRight(), true);
      expect(result2.isRight(), true);
      expect(result1.getOrElse(() => []), result2.getOrElse(() => []));
    });
  });
}
