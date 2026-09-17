// lib/services/secure_encrypt_service.dart
//
// Streaming AES-256-GCM encryption for large payloads.
//
// Why this exists: the legacy path (`CryptoService.encryptFile` +
// `encryptFileInIsolate`) received the whole file as a `Uint8List`, produced a
// second full ciphertext buffer, boxed it into a `List<int>` and finally built
// yet another `Uint8List` with `[...salt, ...nonce, ...ciphertext, ...authTag]`.
// For a 90 MB video that is >300 MB of transient memory and caused OOM crashes
// on the Android upload flow. This service reads the plaintext from disk,
// encrypts chunk by chunk inside a background isolate and writes the payload
// straight to an output file, so memory stays flat.
//
// Payload format (unchanged, byte-for-byte compatible with the decrypt path):
//   salt(16) || nonce(12) || ciphertext(N) || authTag(16)

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';

import '../utils/constants.dart';
import 'crypto_service.dart';

/// Result of a completed streaming encryption.
class SecureEncryptResult {
  /// Path of the written `salt || nonce || ciphertext || authTag` payload.
  final String filePath;

  /// Original plaintext size in bytes.
  final int plaintextBytes;

  /// Size of the encrypted payload in bytes.
  final int encryptedBytes;

  /// SHA-256 (hex) of the encrypted payload, ready for AWS SigV4 signing.
  final String payloadHash;

  final List<int> salt;
  final List<int> nonce;
  final List<int> authTag;

  /// Derived AES-256 key. Must be stored securely (never uploaded).
  final List<int> key;

  final int elapsedMs;

  const SecureEncryptResult({
    required this.filePath,
    required this.plaintextBytes,
    required this.encryptedBytes,
    required this.payloadHash,
    required this.salt,
    required this.nonce,
    required this.authTag,
    required this.key,
    required this.elapsedMs,
  });

  double get megabytesPerSecond {
    if (elapsedMs <= 0) return 0;
    return (plaintextBytes / (1024 * 1024)) / (elapsedMs / 1000);
  }
}

/// Encrypts a plaintext file into a `salt || nonce || ciphertext || authTag`
/// payload file without ever holding the whole file in memory.
class SecureEncryptService {
  SecureEncryptService();

  static const int _ioChunkSize = 1024 * 1024; // 1 MB I/O chunks (multiple of 16)

  /// Encrypts [plaintextPath] into [outputPath].
  ///
  /// Runs on a background isolate. Peak memory is a few MB regardless of the
  /// file size.
  Future<SecureEncryptResult> encryptPayloadFileToFile({
    required String plaintextPath,
    required String outputPath,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();

    final result = await Isolate.run(
      () => _encryptPayloadWorker(
        plaintextPath: plaintextPath,
        outputPath: outputPath,
        password: password,
        chunkSize: _ioChunkSize,
      ),
    );

    stopwatch.stop();
    return SecureEncryptResult(
      filePath: outputPath,
      plaintextBytes: result['plaintextBytes'] as int,
      encryptedBytes: result['encryptedBytes'] as int,
      payloadHash: result['payloadHash'] as String,
      salt: result['salt'] as List<int>,
      nonce: result['nonce'] as List<int>,
      authTag: result['authTag'] as List<int>,
      key: result['key'] as List<int>,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Collects the single [crypto.Digest] emitted by a chunked hash sink.
class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? digest;

  @override
  void add(crypto.Digest data) => digest = data;

  @override
  void close() {}
}

/// Streaming encryption isolate entry point.
///
/// Intermediate chunks are always a multiple of the AES block size so
/// pointycastle's GCM never starts a `processBytes` call with a pending partial
/// block (that path is buggy); the remainder is processed as the final call
/// before `doFinal`, which also emits the authentication tag.
Future<Map<String, dynamic>> _encryptPayloadWorker({
  required String plaintextPath,
  required String outputPath,
  required String password,
  required int chunkSize,
}) async {
  final input = File(plaintextPath);
  final plaintextBytes = await input.length();

  final cryptoService = CryptoService();
  final salt = cryptoService.generateSalt();
  final nonce = cryptoService.generateNonce();
  final key = cryptoService.deriveKey(password, salt);

  final cipher = GCMBlockCipher(AESEngine());
  cipher.init(
    true,
    AEADParameters(
      KeyParameter(Uint8List.fromList(key)),
      AppConstants.aesTagSize * 8, // 128-bit tag
      Uint8List.fromList(nonce),
      Uint8List(0), // no additional authenticated data (AAD)
    ),
  );

  final digestSink = _DigestSink();
  final hashSink = crypto.sha256.startChunkedConversion(digestSink);

  RandomAccessFile? raf;
  IOSink? sink;
  try {
    raf = await input.open();
    sink = File(outputPath).openWrite();

    final header = Uint8List.fromList([...salt, ...nonce]);
    sink.add(header);
    hashSink.add(header);

    final outBuffer = Uint8List(chunkSize + 64);
    var remaining = plaintextBytes;

    while (remaining > chunkSize) {
      final chunk = await raf.read(chunkSize);
      if (chunk.length != chunkSize) {
        throw Exception(
          'truncated read: expected $chunkSize bytes, got ${chunk.length}',
        );
      }
      final written =
          cipher.processBytes(chunk, 0, chunk.length, outBuffer, 0);
      if (written > 0) {
        final block = outBuffer.sublist(0, written);
        sink.add(block);
        hashSink.add(block);
      }
      remaining -= chunk.length;
    }

    if (remaining > 0) {
      final tail = await raf.read(remaining);
      if (tail.length != remaining) {
        throw Exception(
          'truncated read: expected $remaining bytes, got ${tail.length}',
        );
      }
      final written = cipher.processBytes(tail, 0, tail.length, outBuffer, 0);
      if (written > 0) {
        final block = outBuffer.sublist(0, written);
        sink.add(block);
        hashSink.add(block);
      }
    }

    // doFinal emite el bloque final pendiente + el authTag de 16 bytes.
    final finalWritten = cipher.doFinal(outBuffer, 0);
    final finalBlock = outBuffer.sublist(0, finalWritten);
    sink.add(finalBlock);
    hashSink.add(finalBlock);

    final authTag =
        finalBlock.sublist(finalBlock.length - AppConstants.aesTagSize).toList();

    await sink.flush();
    await sink.close();
    sink = null;
    await raf.close();
    raf = null;

    hashSink.close();
    final payloadHash = digestSink.digest?.toString() ?? '';

    final encryptedBytes = AppConstants.saltSize +
        AppConstants.aesNonceSize +
        plaintextBytes +
        AppConstants.aesTagSize;

    return {
      'plaintextBytes': plaintextBytes,
      'encryptedBytes': encryptedBytes,
      'payloadHash': payloadHash,
      'salt': salt,
      'nonce': nonce,
      'authTag': authTag,
      'key': key,
    };
  } finally {
    await _safeCloseSink(sink);
    await _safeCloseRaf(raf);
  }
}

Future<void> _safeCloseSink(IOSink? sink) async {
  try {
    await sink?.close();
  } catch (_) {}
}

Future<void> _safeCloseRaf(RandomAccessFile? raf) async {
  try {
    await raf?.close();
  } catch (_) {}
}
