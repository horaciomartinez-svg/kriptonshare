import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kriptonshare/services/crypto_service.dart';
import 'package:kriptonshare/services/secure_decrypt_service.dart';
import 'package:kriptonshare/utils/constants.dart';
import 'package:path/path.dart' as p;

/// Bytes pseudoaleatorios baratos (evita `Random.secure()` por byte, que es
/// lentísimo para payloads grandes).
Uint8List _patternBytes(int length) {
  final bytes = Uint8List(length);
  var x = 0x12345678;
  for (var i = 0; i < length; i++) {
    x = (1103515245 * x + 12345) & 0x7fffffff;
    bytes[i] = x & 0xff;
  }
  return bytes;
}

/// Construye y persiste un payload `salt || nonce || ciphertext || authTag`.
Future<String> _writeEncryptedPayload(
  Directory dir,
  Uint8List plaintext,
  String password, {
  String name = 'payload',
}) async {
  final crypto = CryptoService();
  final encrypted = await crypto.encryptFile(
    fileBytes: plaintext,
    password: password,
  );
  final payload = Uint8List.fromList([
    ...(encrypted['salt']! as List<int>),
    ...(encrypted['nonce']! as List<int>),
    ...(encrypted['ciphertext']! as List<int>),
    ...(encrypted['authTag']! as List<int>),
  ]);
  final file = File(p.join(dir.path, '$name.enc'));
  await file.writeAsBytes(payload, flush: true);
  return file.path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ks_decrypt_test');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  // Cubre los dos motores: fast path (one-shot AES-GCM) y streaming
  // (pointycastle). `fastPathMaxBytes: 0` fuerza siempre el streaming.
  for (final engine in <({String label, int fastPathMaxBytes})>[
    (label: 'fast path', fastPathMaxBytes: 1 << 30),
    (label: 'streaming', fastPathMaxBytes: 0),
  ]) {
    group('SecureDecryptService (${engine.label})', () {
      late SecureDecryptService service;

      setUp(() {
        service =
            SecureDecryptService(fastPathMaxBytes: engine.fastPathMaxBytes);
      });

      test(
        'writes plaintext byte-for-byte identical to the legacy in-memory decrypt',
        () async {
          // Arrange
          final plaintext = _patternBytes(1024 * 1024 + 137);
          const password = 'compat-password';
          final encryptedPath =
              await _writeEncryptedPayload(tempDir, plaintext, password);
          final outputPath = p.join(tempDir.path, 'out.bin');

          // Act
          final result = await service.decryptPayloadFileToFile(
            encryptedPath: encryptedPath,
            outputPath: outputPath,
            password: password,
          );

          // Assert: mismo resultado que el descifrado mono-bloque existente.
          final legacy = await CryptoService().decryptFileBytes(
            encryptedBytes: await File(encryptedPath).readAsBytes(),
            password: password,
          );

          expect(result.plaintextBytes, plaintext.length);
          expect(await File(outputPath).readAsBytes(), equals(plaintext));
          expect(legacy, equals(plaintext));
          expect(File('$outputPath.part').existsSync(), isFalse);
        },
      );

      test('reports progress ending at the plaintext size', () async {
        // Arrange
        final plaintext = _patternBytes(3 * 1024 * 1024);
        const password = 'progress-password';
        final encryptedPath =
            await _writeEncryptedPayload(tempDir, plaintext, password);
        final outputPath = p.join(tempDir.path, 'progress.bin');
        final progressEvents = <int>[];
        final totals = <int>[];

        // Act
        await service.decryptPayloadFileToFile(
          encryptedPath: encryptedPath,
          outputPath: outputPath,
          password: password,
          onProgress: (processed, total) {
            progressEvents.add(processed);
            totals.add(total);
          },
        );

        // Assert
        expect(progressEvents, isNotEmpty);
        expect(progressEvents.last, plaintext.length);
        expect(totals.every((t) => t == plaintext.length), isTrue);
      });

      test('deletes the partial file and throws on tampered ciphertext',
          () async {
        // Arrange
        final plaintext = _patternBytes(512 * 1024);
        const password = 'tamper-password';
        final encryptedPath =
            await _writeEncryptedPayload(tempDir, plaintext, password);
        final payload = await File(encryptedPath).readAsBytes();
        const tamperIndex =
            AppConstants.saltSize + AppConstants.aesNonceSize + 64;
        payload[tamperIndex] = (payload[tamperIndex] + 1) % 256;
        await File(encryptedPath).writeAsBytes(payload, flush: true);
        final outputPath = p.join(tempDir.path, 'tampered.bin');

        // Act & Assert
        await expectLater(
          service.decryptPayloadFileToFile(
            encryptedPath: encryptedPath,
            outputPath: outputPath,
            password: password,
          ),
          throwsA(isA<FileIntegrityException>()),
        );
        expect(File(outputPath).existsSync(), isFalse);
        expect(File('$outputPath.part').existsSync(), isFalse);
      });

      test('deletes the partial file and throws on tampered auth tag',
          () async {
        // Arrange
        final plaintext = _patternBytes(256 * 1024);
        const password = 'tag-password';
        final encryptedPath =
            await _writeEncryptedPayload(tempDir, plaintext, password);
        final payload = await File(encryptedPath).readAsBytes();
        payload[payload.length - 1] = (payload[payload.length - 1] + 1) % 256;
        await File(encryptedPath).writeAsBytes(payload, flush: true);
        final outputPath = p.join(tempDir.path, 'tag.bin');

        // Act & Assert
        await expectLater(
          service.decryptPayloadFileToFile(
            encryptedPath: encryptedPath,
            outputPath: outputPath,
            password: password,
          ),
          throwsA(isA<FileIntegrityException>()),
        );
        expect(File(outputPath).existsSync(), isFalse);
        expect(File('$outputPath.part').existsSync(), isFalse);
      });

      test('treats a wrong password as an integrity failure', () async {
        // Arrange
        final plaintext = _patternBytes(128 * 1024);
        final encryptedPath =
            await _writeEncryptedPayload(tempDir, plaintext, 'right-password');
        final outputPath = p.join(tempDir.path, 'wrongpw.bin');

        // Act & Assert
        await expectLater(
          service.decryptPayloadFileToFile(
            encryptedPath: encryptedPath,
            outputPath: outputPath,
            password: 'wrong-password',
          ),
          throwsA(isA<FileIntegrityException>()),
        );
        expect(File(outputPath).existsSync(), isFalse);
      });

      test('rejects a truncated payload without producing an output file',
          () async {
        // Arrange
        final truncated = File(p.join(tempDir.path, 'truncated.enc'));
        await truncated.writeAsBytes(Uint8List(10), flush: true);
        final outputPath = p.join(tempDir.path, 'truncated.bin');

        // Act & Assert
        await expectLater(
          service.decryptPayloadFileToFile(
            encryptedPath: truncated.path,
            outputPath: outputPath,
            password: 'whatever',
          ),
          throwsA(isA<FileIntegrityException>()),
        );
        expect(File(outputPath).existsSync(), isFalse);
      });
    });
  }
}
