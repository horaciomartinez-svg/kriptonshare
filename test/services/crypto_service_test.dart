import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/services/crypto_service.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    cryptoService = CryptoService();
  });

  group('CryptoService', () {
    test('should generate unique salts and nonces', () {
      // Act
      final salt1 = cryptoService.generateSalt();
      final salt2 = cryptoService.generateSalt();
      final nonce1 = cryptoService.generateNonce();
      final nonce2 = cryptoService.generateNonce();

      // Assert
      expect(salt1, isNot(equals(salt2)));
      expect(nonce1, isNot(equals(nonce2)));
      expect(salt1.length, 16);
      expect(nonce1.length, 12);
    });

    test('should derive deterministic key from password and salt', () {
      // Arrange
      final salt = cryptoService.generateSalt();
      const password = 'kripton-secure-password';

      // Act
      final key1 = cryptoService.deriveKey(password, salt);
      final key2 = cryptoService.deriveKey(password, salt);

      // Assert
      expect(key1, equals(key2));
      expect(key1.length, 32);
    });

    test('should derive different keys for different salts', () {
      // Arrange
      final salt1 = cryptoService.generateSalt();
      final salt2 = cryptoService.generateSalt();
      const password = 'kripton-secure-password';

      // Act
      final key1 = cryptoService.deriveKey(password, salt1);
      final key2 = cryptoService.deriveKey(password, salt2);

      // Assert
      expect(key1, isNot(equals(key2)));
    });

    test('should encrypt and decrypt small plaintext', () {
      // Arrange
      final plaintext = utf8.encode('Documento confidencial de KRIPTONSHARE');
      final salt = cryptoService.generateSalt();
      final nonce = cryptoService.generateNonce();
      final key = cryptoService.deriveKey('user-password', salt);

      // Act
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

      // Assert
      expect(encrypted['ciphertext']!.isNotEmpty, true);
      expect(encrypted['authTag']!.length, 16);
      expect(decrypted.toList(), plaintext);
    });

    test('should encrypt and decrypt a 1 MB random payload', () {
      // Arrange
      final random = Random.secure();
      final oneMegabyte = Uint8List(1024 * 1024);
      for (var i = 0; i < oneMegabyte.length; i++) {
        oneMegabyte[i] = random.nextInt(256);
      }

      final salt = cryptoService.generateSalt();
      final nonce = cryptoService.generateNonce();
      final key = cryptoService.deriveKey('heavy-file-password', salt);

      // Act
      final encrypted = cryptoService.encrypt(
        plaintext: oneMegabyte,
        key: key,
        nonce: nonce,
      );
      final decrypted = cryptoService.decrypt(
        ciphertext: encrypted['ciphertext']!,
        key: key,
        nonce: nonce,
        authTag: encrypted['authTag']!,
      );

      // Assert
      expect(decrypted, equals(oneMegabyte));
    });

    test('should encrypt and decrypt via encryptFile/decryptFile', () async {
      // Arrange
      final plaintext = utf8.encode('Contrato de confidencialidad NDA');
      const password = 'file-password';

      // Act
      final encryptedFile = await cryptoService.encryptFile(
        fileBytes: Uint8List.fromList(plaintext),
        password: password,
      );
      final decrypted = await cryptoService.decryptFile(
        ciphertext: encryptedFile['ciphertext'] as List<int>,
        key: encryptedFile['key'] as List<int>,
        nonce: encryptedFile['nonce'] as List<int>,
        authTag: encryptedFile['authTag'] as List<int>,
      );

      // Assert
      expect(encryptedFile['salt'], isNotEmpty);
      expect(encryptedFile['nonce'], isNotEmpty);
      expect(encryptedFile['authTag'], isNotEmpty);
      expect(encryptedFile['key'], isNotEmpty);
      expect(decrypted.toList(), plaintext);
    });

    test('should fail decryption when ciphertext is tampered', () {
      // Arrange
      final plaintext = utf8.encode('Mensaje crítico');
      final salt = cryptoService.generateSalt();
      final nonce = cryptoService.generateNonce();
      final key = cryptoService.deriveKey('tamper-password', salt);

      final encrypted = cryptoService.encrypt(
        plaintext: Uint8List.fromList(plaintext),
        key: key,
        nonce: nonce,
      );

      // Tamper with the first byte of ciphertext
      final tamperedCiphertext = List<int>.from(encrypted['ciphertext']!);
      tamperedCiphertext[0] = (tamperedCiphertext[0] + 1) % 256;

      // Act & Assert
      expect(
        () => cryptoService.decrypt(
          ciphertext: tamperedCiphertext,
          key: key,
          nonce: nonce,
          authTag: encrypted['authTag']!,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should fail decryption when authTag is tampered', () {
      // Arrange
      final plaintext = utf8.encode('Mensaje crítico');
      final salt = cryptoService.generateSalt();
      final nonce = cryptoService.generateNonce();
      final key = cryptoService.deriveKey('tamper-password', salt);

      final encrypted = cryptoService.encrypt(
        plaintext: Uint8List.fromList(plaintext),
        key: key,
        nonce: nonce,
      );

      // Tamper with the first byte of authTag
      final tamperedAuthTag = List<int>.from(encrypted['authTag']!);
      tamperedAuthTag[0] = (tamperedAuthTag[0] + 1) % 256;

      // Act & Assert
      expect(
        () => cryptoService.decrypt(
          ciphertext: encrypted['ciphertext']!,
          key: key,
          nonce: nonce,
          authTag: tamperedAuthTag,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should fail decryption with wrong key', () {
      // Arrange
      final plaintext = utf8.encode('Mensaje secreto');
      final salt = cryptoService.generateSalt();
      final nonce = cryptoService.generateNonce();
      final key = cryptoService.deriveKey('correct-password', salt);
      final wrongKey = cryptoService.deriveKey('wrong-password', salt);

      final encrypted = cryptoService.encrypt(
        plaintext: Uint8List.fromList(plaintext),
        key: key,
        nonce: nonce,
      );

      // Act & Assert
      expect(
        () => cryptoService.decrypt(
          ciphertext: encrypted['ciphertext']!,
          key: wrongKey,
          nonce: nonce,
          authTag: encrypted['authTag']!,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw on invalid key size', () {
      expect(
        () => cryptoService.encrypt(
          plaintext: Uint8List.fromList([1, 2, 3]),
          key: [1, 2, 3], // invalid key size
          nonce: cryptoService.generateNonce(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw on invalid nonce size', () {
      expect(
        () => cryptoService.encrypt(
          plaintext: Uint8List.fromList([1, 2, 3]),
          key: cryptoService.deriveKey('pw', cryptoService.generateSalt()),
          nonce: [1, 2, 3], // invalid nonce size
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
