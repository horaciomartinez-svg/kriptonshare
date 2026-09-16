// lib/services/secure_decrypt_service.dart
//
// Streaming AES-256-GCM decryption for large payloads.
//
// Why this exists: the original viewer path ran PBKDF2 (100k) + AES-GCM over
// the whole file synchronously on the UI isolate and made several full copies
// of the buffer in memory. For a 22 MB video that froze the UI for minutes and
// thrashed memory. This service decrypts on a background isolate and never
// surfaces unverified bytes: the plaintext is written to a `.part` file that is
// only renamed to its final name after GCM has validated the auth tag. If the
// tag does not match, the partial plaintext is deleted and
// [FileIntegrityException] is thrown.
//
// Two engines:
//   - Fast path (files <= [SecureDecryptService.defaultFastPathMaxBytes]): decrypts the
//     whole payload in one shot with `package:cryptography`'s AES-GCM, which is
//     ~12x faster than pointycastle. Runs inside `Isolate.run`.
//   - Streaming path (very large files): reads/decrypts chunk by chunk with
//     pointycastle so memory stays flat, also inside a background isolate.
//
// Payload format (unchanged, byte-for-byte compatible):
//   salt(16) || nonce(12) || ciphertext(N) || authTag(16)

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
// `Mac` (cryptography) y `Mac` (pointycastle/api.dart) colisionan.
import 'package:pointycastle/export.dart' hide Mac;

import '../utils/constants.dart';
import 'crypto_service.dart';

/// Phase of a secure transfer, used to drive localized progress UI.
enum SecureTransferPhase { downloading, decrypting }

/// Progress snapshot for a download or decrypt operation.
class SecureTransferProgress {
  final SecureTransferPhase phase;
  final int processedBytes;
  final int totalBytes;

  const SecureTransferProgress({
    required this.phase,
    required this.processedBytes,
    required this.totalBytes,
  });

  /// 0.0..1.0, or 0 when the total size is unknown.
  double get fraction {
    if (totalBytes <= 0) return 0;
    return (processedBytes / totalBytes).clamp(0.0, 1.0);
  }

  /// Integer percentage (0..100) for labels.
  int get percent => (fraction * 100).round();
}

/// Thrown when AES-GCM detects tampering/corruption (auth tag mismatch) or an
/// incomplete payload. The decrypted partial file is always removed first.
class FileIntegrityException implements Exception {
  final String message;
  const FileIntegrityException(this.message);

  @override
  String toString() => 'FileIntegrityException: $message';
}

/// Result of a completed streaming decryption.
class SecureDecryptResult {
  final String filePath;
  final int plaintextBytes;
  final int elapsedMs;

  const SecureDecryptResult({
    required this.filePath,
    required this.plaintextBytes,
    required this.elapsedMs,
  });

  double get megabytesPerSecond {
    if (elapsedMs <= 0) return 0;
    return (plaintextBytes / (1024 * 1024)) / (elapsedMs / 1000);
  }
}

/// Message passed to the streaming decrypt worker isolate.
class _DecryptJob {
  final SendPort sendPort;
  final String encryptedPath;
  final String outputPath;
  final String password;
  final int chunkSize;

  const _DecryptJob({
    required this.sendPort,
    required this.encryptedPath,
    required this.outputPath,
    required this.password,
    required this.chunkSize,
  });
}

/// Decrypts `salt || nonce || ciphertext || authTag` payloads without ever
/// exposing unverified plaintext, choosing between a fast one-shot engine and a
/// memory-flat streaming engine.
class SecureDecryptService {
  SecureDecryptService({int fastPathMaxBytes = defaultFastPathMaxBytes})
      : _fastPathMaxBytes = fastPathMaxBytes;

  /// Files up to this size use the fast one-shot AES-GCM engine (peak memory
  /// ~2x the payload). Larger files fall back to streaming so memory stays flat.
  static const int defaultFastPathMaxBytes = 128 * 1024 * 1024;

  static const int _ioChunkSize = 1024 * 1024; // 1 MB I/O chunks

  final int _fastPathMaxBytes;

  /// Decrypts [encryptedPath] into [outputPath].
  ///
  /// Plaintext is written to `$outputPath.part` and atomically renamed to
  /// [outputPath] only after the auth tag is verified. On failure the `.part`
  /// file is deleted and [FileIntegrityException] is thrown.
  ///
  /// [onProgress] receives `(processedBytes, totalBytes)` while decrypting.
  Future<SecureDecryptResult> decryptPayloadFileToFile({
    required String encryptedPath,
    required String outputPath,
    required String password,
    void Function(int processed, int total)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    const headerSize = AppConstants.saltSize + AppConstants.aesNonceSize;
    const tagSize = AppConstants.aesTagSize;

    final totalBytes = await File(encryptedPath).length();
    if (totalBytes < headerSize + tagSize) {
      throw const FileIntegrityException('incomplete payload');
    }
    final cipherLength = totalBytes - headerSize - tagSize;

    if (cipherLength <= _fastPathMaxBytes) {
      return _decryptFast(
        encryptedPath: encryptedPath,
        outputPath: outputPath,
        password: password,
        onProgress: onProgress,
        stopwatch: stopwatch,
        cipherLength: cipherLength,
      );
    }

    return _decryptStreaming(
      encryptedPath: encryptedPath,
      outputPath: outputPath,
      password: password,
      onProgress: onProgress,
      stopwatch: stopwatch,
    );
  }

  /// One-shot AES-GCM (package:cryptography) inside a background isolate.
  Future<SecureDecryptResult> _decryptFast({
    required String encryptedPath,
    required String outputPath,
    required String password,
    required void Function(int processed, int total)? onProgress,
    required Stopwatch stopwatch,
    required int cipherLength,
  }) async {
    final partPath = '$outputPath.part';
    onProgress?.call(0, cipherLength);

    final status = await Isolate.run(
      () => _decryptFastWorker(
        encryptedPath: encryptedPath,
        partPath: partPath,
        password: password,
      ),
    );

    final partFile = File(partPath);
    if (status != 'ok') {
      await _deleteQuietly(partFile);
      throw FileIntegrityException(
        status == 'incomplete'
            ? 'incomplete payload'
            : 'Authentication tag check failed',
      );
    }
    if (!await partFile.exists()) {
      throw const FileIntegrityException('decrypted file was not produced');
    }

    // Tag already verified: expose the plaintext under its final name.
    final finalFile = File(outputPath);
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await partFile.rename(outputPath);

    final plaintextBytes = await finalFile.length();
    onProgress?.call(cipherLength, cipherLength);
    stopwatch.stop();
    return SecureDecryptResult(
      filePath: outputPath,
      plaintextBytes: plaintextBytes,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Memory-flat streaming AES-GCM (pointycastle) inside a background isolate.
  Future<SecureDecryptResult> _decryptStreaming({
    required String encryptedPath,
    required String outputPath,
    required String password,
    required void Function(int processed, int total)? onProgress,
    required Stopwatch stopwatch,
  }) async {
    final partPath = '$outputPath.part';
    final receivePort = ReceivePort();
    final completer = Completer<void>();
    final errors = ReceivePort();

    void handleMessage(dynamic message) {
      if (message is Map) {
        switch (message['type']) {
          case 'progress':
            onProgress?.call(
                message['processed'] as int, message['total'] as int);
          case 'done':
            if (!completer.isCompleted) completer.complete();
          case 'error':
            if (!completer.isCompleted) {
              final isIntegrity = message['integrity'] as bool? ?? false;
              final detail = message['message'] as String? ?? 'decryption failed';
              completer.completeError(
                isIntegrity
                    ? FileIntegrityException(detail)
                    : Exception('Decryption failed: $detail'),
              );
            }
        }
      }
    }

    void handleError(dynamic error) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Decrypt isolate error: $error'));
      }
    }

    receivePort.listen(handleMessage);
    errors.listen(handleError);

    Isolate? isolate;
    try {
      isolate = await Isolate.spawn<_DecryptJob>(
        _decryptPayloadWorker,
        _DecryptJob(
          sendPort: receivePort.sendPort,
          encryptedPath: encryptedPath,
          outputPath: partPath,
          password: password,
          chunkSize: _ioChunkSize,
        ),
        onError: errors.sendPort,
        errorsAreFatal: true,
        debugName: 'ks-decrypt',
      );

      await completer.future;
    } finally {
      isolate?.kill(priority: Isolate.immediate);
      receivePort.close();
      errors.close();
    }

    final partFile = File(partPath);
    if (!await partFile.exists()) {
      throw const FileIntegrityException('decrypted file was not produced');
    }

    // Tag already verified: expose the plaintext under its final name.
    final finalFile = File(outputPath);
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await partFile.rename(outputPath);

    final plaintextBytes = await finalFile.length();
    stopwatch.stop();
    return SecureDecryptResult(
      filePath: outputPath,
      plaintextBytes: plaintextBytes,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
  }
}

/// Fast-path isolate entry point. Reads the whole (bounded) payload, decrypts
/// it with `package:cryptography`'s AES-GCM and writes the plaintext to
/// [partPath]. Returns `'ok'`, `'integrity'` or `'incomplete'` so no exception
/// has to cross the isolate boundary.
Future<String> _decryptFastWorker({
  required String encryptedPath,
  required String partPath,
  required String password,
}) async {
  final file = File(encryptedPath);
  final totalBytes = await file.length();
  const headerSize = AppConstants.saltSize + AppConstants.aesNonceSize;
  const tagSize = AppConstants.aesTagSize;

  if (totalBytes < headerSize + tagSize) return 'incomplete';

  final bytes = await file.readAsBytes();
  final salt = Uint8List.sublistView(bytes, 0, AppConstants.saltSize);
  final nonce =
      Uint8List.sublistView(bytes, AppConstants.saltSize, headerSize);
  final ciphertext =
      Uint8List.sublistView(bytes, headerSize, totalBytes - tagSize);
  final authTag =
      Uint8List.sublistView(bytes, totalBytes - tagSize, totalBytes);

  final key = CryptoService().deriveKey(password, salt);

  List<int> plaintext;
  try {
    plaintext = await AesGcm.with256bits().decrypt(
      SecretBox(ciphertext, nonce: nonce, mac: Mac(authTag)),
      secretKey: SecretKey(key),
    );
  } on SecretBoxAuthenticationError {
    return 'integrity';
  }

  final sink = File(partPath).openWrite();
  try {
    sink.add(plaintext);
    await sink.flush();
  } finally {
    await sink.close();
  }
  return 'ok';
}

/// Streaming isolate entry point: reads the encrypted file sequentially, runs
/// GCM `processBytes` per chunk, writes plaintext, then verifies the tag via
/// `doFinal` before reporting success.
Future<void> _decryptPayloadWorker(_DecryptJob job) async {
  final send = job.sendPort;
  final partFile = File(job.outputPath);
  RandomAccessFile? raf;
  IOSink? sink;

  try {
    final input = File(job.encryptedPath);
    final totalBytes = await input.length();
    const headerSize = AppConstants.saltSize + AppConstants.aesNonceSize;
    const tagSize = AppConstants.aesTagSize;

    if (totalBytes < headerSize + tagSize) {
      send.send({'type': 'error', 'integrity': true, 'message': 'incomplete payload'});
      return;
    }

    final cipherLength = totalBytes - headerSize - tagSize;

    raf = await input.open();
    final salt = await raf.read(AppConstants.saltSize);
    final nonce = await raf.read(AppConstants.aesNonceSize);
    await raf.setPosition(totalBytes - tagSize);
    final authTag = await raf.read(tagSize);

    if (salt.length != AppConstants.saltSize ||
        nonce.length != AppConstants.aesNonceSize ||
        authTag.length != tagSize) {
      send.send({'type': 'error', 'integrity': true, 'message': 'incomplete payload'});
      return;
    }

    final key = CryptoService().deriveKey(job.password, salt.toList());

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(
        KeyParameter(Uint8List.fromList(key)),
        AppConstants.aesTagSize * 8,
        Uint8List.fromList(nonce),
        Uint8List(0),
      ),
    );

    await raf.setPosition(headerSize);
    sink = partFile.openWrite();
    final outBuffer = Uint8List(job.chunkSize + 64);

    // Los chunks intermedios deben ser múltiplos de 16: pointycastle calcula
    // mal el offset restante cuando `processBytes` arranca con un bloque
    // parcial pendiente. El auth tag se entrega pegado al último chunk de
    // ciphertext en una sola llamada, que es además la forma canónica de GCM.
    var remaining = cipherLength;
    var processed = 0;
    while (remaining > job.chunkSize) {
      final chunk = await raf.read(job.chunkSize);
      if (chunk.length != job.chunkSize) {
        await _abort(sink, partFile);
        send.send(
            {'type': 'error', 'integrity': true, 'message': 'truncated payload'});
        return;
      }

      final written = cipher.processBytes(chunk, 0, chunk.length, outBuffer, 0);
      if (written > 0) {
        sink.add(outBuffer.sublist(0, written));
      }
      processed += chunk.length;
      remaining -= chunk.length;
      send.send({'type': 'progress', 'processed': processed, 'total': cipherLength});
    }

    final tail = await raf.read(remaining);
    if (tail.length != remaining) {
      await _abort(sink, partFile);
      send.send(
          {'type': 'error', 'integrity': true, 'message': 'truncated payload'});
      return;
    }

    // Último bloque: ciphertext restante || authTag en una sola llamada.
    final finalChunk = Uint8List(remaining + authTag.length)
      ..setAll(0, tail)
      ..setAll(remaining, authTag);
    final written = cipher.processBytes(finalChunk, 0, finalChunk.length, outBuffer, 0);
    if (written > 0) {
      sink.add(outBuffer.sublist(0, written));
    }
    processed += remaining;
    send.send({'type': 'progress', 'processed': processed, 'total': cipherLength});

    // doFinal valida el auth tag ya alimentado y vuelca el bloque final.
    final finalWritten = cipher.doFinal(outBuffer, 0);
    if (finalWritten > 0) {
      sink.add(outBuffer.sublist(0, finalWritten));
    }

    await sink.flush();
    await sink.close();
    sink = null;
    await raf.close();
    raf = null;

    send.send({'type': 'done'});
  } on InvalidCipherTextException catch (e) {
    await _safeCloseSink(sink);
    await _safeCloseRaf(raf);
    await _deleteQuietly(partFile);
    send.send({'type': 'error', 'integrity': true, 'message': e.toString()});
  } catch (e) {
    await _safeCloseSink(sink);
    await _safeCloseRaf(raf);
    await _deleteQuietly(partFile);
    send.send({'type': 'error', 'integrity': false, 'message': e.toString()});
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

/// Cierra el sink en curso y elimina el archivo parcial.
Future<void> _abort(IOSink? sink, File partFile) async {
  await _safeCloseSink(sink);
  await _deleteQuietly(partFile);
}

Future<void> _deleteQuietly(File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}
