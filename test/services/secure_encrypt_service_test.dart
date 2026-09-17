import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/services/crypto_service.dart';
import 'package:kriptonshare/services/secure_decrypt_service.dart';
import 'package:kriptonshare/services/secure_encrypt_service.dart';
import 'package:kriptonshare/utils/constants.dart';
import 'package:path/path.dart' as p;

/// Bytes pseudoaleatorios baratos (evita `Random.secure()` por byte).
Uint8List _patternBytes(int length) {
  final bytes = Uint8List(length);
  var x = 0x12345678;
  for (var i = 0; i < length; i++) {
    x = (1103515245 * x + 12345) & 0x7fffffff;
    bytes[i] = x & 0xff;
  }
  return bytes;
}

void main() {
  late Directory tempDir;
  late SecureEncryptService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ks_encrypt_test');
    service = SecureEncryptService();
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Future<SecureEncryptResult> encrypt(Uint8List plaintext, String password) async {
    final plaintextPath = p.join(tempDir.path, 'plain.bin');
    await File(plaintextPath).writeAsBytes(plaintext, flush: true);
    return service.encryptPayloadFileToFile(
      plaintextPath: plaintextPath,
      outputPath: p.join(tempDir.path, 'payload.enc'),
      password: password,
    );
  }

  test('produces the salt || nonce || ciphertext || authTag layout', () async {
    // Arrange: 2 MB + remainder exercises multiple 1 MB chunks + the tail.
    final plaintext = _patternBytes(2 * 1024 * 1024 + 137);
    const password = 'layout-password';

    // Act
    final result = await encrypt(plaintext, password);
    final payload = await File(result.filePath).readAsBytes();

    // Assert
    const header = AppConstants.saltSize + AppConstants.aesNonceSize;
    const tag = AppConstants.aesTagSize;
    expect(result.encryptedBytes, plaintext.length + header + tag);
    expect(payload.length, result.encryptedBytes);
    expect(payload.sublist(0, AppConstants.saltSize), equals(result.salt));
    expect(
      payload.sublist(AppConstants.saltSize, header),
      equals(result.nonce),
    );
    expect(payload.sublist(payload.length - tag), equals(result.authTag));
    expect(result.salt.length, AppConstants.saltSize);
    expect(result.nonce.length, AppConstants.aesNonceSize);
    expect(result.authTag.length, AppConstants.aesTagSize);
    expect(result.key.length, AppConstants.aesKeySize);
    expect(result.plaintextBytes, plaintext.length);
  });

  test('payload hash matches the sha256 of the written file', () async {
    // Arrange
    final plaintext = _patternBytes(1024 * 1024 + 7);

    // Act
    final result = await encrypt(plaintext, 'hash-password');
    final bytes = await File(result.filePath).readAsBytes();

    // Assert
    expect(result.payloadHash, crypto.sha256.convert(bytes).toString());
  });

  // El formato debe seguir siendo descifrable por ambos motores existentes.
  for (final engine in <({String label, int fastPathMaxBytes})>[
    (label: 'fast path', fastPathMaxBytes: 1 << 30),
    (label: 'streaming', fastPathMaxBytes: 0),
  ]) {
    test('round-trips through SecureDecryptService (${engine.label})', () async {
      // Arrange
      final plaintext = _patternBytes(3 * 1024 * 1024 + 555);
      final password = 'round-trip-${engine.label}';
      final result = await encrypt(plaintext, password);
      final decryptor =
          SecureDecryptService(fastPathMaxBytes: engine.fastPathMaxBytes);

      // Act
      final decrypted = await decryptor.decryptPayloadFileToFile(
        encryptedPath: result.filePath,
        outputPath: p.join(tempDir.path, 'decrypted.bin'),
        password: password,
      );

      // Assert
      expect(decrypted.plaintextBytes, plaintext.length);
      expect(await File(decrypted.filePath).readAsBytes(), equals(plaintext));
    });
  }

  test('is byte-for-byte compatible with the legacy in-memory decrypt', () async {
    // Arrange
    final plaintext = _patternBytes(1024 * 1024 + 11);
    const password = 'legacy-compat';
    final result = await encrypt(plaintext, password);

    // Act
    final legacy = await CryptoService().decryptFileBytes(
      encryptedBytes: await File(result.filePath).readAsBytes(),
      password: password,
    );

    // Assert
    expect(legacy, equals(plaintext));
  });

  test('rejects a wrong password at decryption time', () async {
    // Arrange
    final plaintext = _patternBytes(256 * 1024);
    final result = await encrypt(plaintext, 'right-password');
    final decryptor = SecureDecryptService(fastPathMaxBytes: 0);

    // Act & Assert
    await expectLater(
      decryptor.decryptPayloadFileToFile(
        encryptedPath: result.filePath,
        outputPath: p.join(tempDir.path, 'wrong.bin'),
        password: 'wrong-password',
      ),
      throwsA(isA<FileIntegrityException>()),
    );
  });
}
