// tool/decrypt_benchmark.dart
//
// Benchmark del descifrado para tamaños de video realistas (22 MB y 90 MB).
// Genera el payload cifrado con `package:cryptography` (AES-GCM one-shot) y
// mide, para cada tamaño, el motor por defecto del servicio (fast path hasta el
// umbral `SecureDecryptService.defaultFastPathMaxBytes`, streaming por encima)
// además del fast path forzado.
//
// Ejecutar: dart run tool/decrypt_benchmark.dart
//
// Nota: son cifras del host de desarrollo (AOT), no de un dispositivo de gama
// media. En dispositivo, los logs `[VIEWER-PERF]` del visor dan las reales.

import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:kriptonshare/services/crypto_service.dart';
import 'package:kriptonshare/services/secure_decrypt_service.dart';

Uint8List _patternBytes(int length) {
  final bytes = Uint8List(length);
  var x = 0x12345678;
  for (var i = 0; i < length; i++) {
    x = (1103515245 * x + 12345) & 0x7fffffff;
    bytes[i] = x & 0xff;
  }
  return bytes;
}

Future<void> _encryptToFile({
  required String path,
  required Uint8List plaintext,
  required String password,
}) async {
  final crypto = CryptoService();
  final salt = crypto.generateSalt();
  final nonce = crypto.generateNonce();
  final key = crypto.deriveKey(password, salt);

  final box = await AesGcm.with256bits().encrypt(
    plaintext,
    secretKey: SecretKey(key),
    nonce: nonce,
  );
  final payload = Uint8List.fromList([
    ...salt,
    ...nonce,
    ...box.cipherText,
    ...box.mac.bytes,
  ]);
  await File(path).writeAsBytes(payload, flush: true);
}

Future<void> _runEngine(
  SecureDecryptService service,
  String label,
  int megabytes,
  String encryptedPath,
  Directory dir,
  Uint8List plaintext,
) async {
  const password = 'bench-password-2026';
  final outputPath = '${dir.path}/plain_${label}_${megabytes}mb.bin';
  try {
    final watch = Stopwatch()..start();
    final result = await service.decryptPayloadFileToFile(
      encryptedPath: encryptedPath,
      outputPath: outputPath,
      password: password,
    );
    watch.stop();

    final sizeBytes = plaintext.length;
    final decryptMbps = (sizeBytes / 1048576) / (result.elapsedMs / 1000);
    final matches = result.plaintextBytes == sizeBytes;

    stdout.writeln('  [$label] ${result.elapsedMs} ms '
        '(${decryptMbps.toStringAsFixed(1)} MB/s) '
        'integridad=${matches ? "OK" : "FALLO"}');
  } finally {
    try {
      await File(outputPath).delete();
    } catch (_) {}
  }
}

Future<void> _benchmark(int megabytes) async {
  final dir = await Directory.systemTemp.createTemp('ks_bench');
  final encryptedPath = '${dir.path}/payload_${megabytes}mb.enc';

  try {
    final plaintext = _patternBytes(megabytes * 1024 * 1024);
    final encryptWatch = Stopwatch()..start();
    await _encryptToFile(
      path: encryptedPath,
      plaintext: plaintext,
      password: 'bench-password-2026',
    );
    encryptWatch.stop();

    stdout.writeln('--- MP4 $megabytes MB ---');
    stdout.writeln('  ciphertext en disco : '
        '${((await File(encryptedPath).length()) / 1048576).toStringAsFixed(1)} MB');
    stdout.writeln('  cifrado (setup)     : ${encryptWatch.elapsedMilliseconds} ms');

    await _runEngine(
      SecureDecryptService(), // motor por defecto (fast path hasta el umbral)
      'default',
      megabytes,
      encryptedPath,
      dir,
      plaintext,
    );
    await _runEngine(
      SecureDecryptService(fastPathMaxBytes: 1 << 30), // fast path forzado
      'fast',
      megabytes,
      encryptedPath,
      dir,
      plaintext,
    );
    stdout.writeln('');
  } finally {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  }
}

Future<void> main() async {
  stdout.writeln('KRIPTONSHARE :: benchmark de descifrado');
  stdout.writeln(
      'Host: ${Platform.operatingSystem} ${Platform.version.split(' ').first}');
  const thresholdMb = SecureDecryptService.defaultFastPathMaxBytes ~/ 1048576;
  stdout.writeln('Servicio: fast path <= $thresholdMb MB; streaming por encima\n');
  await _benchmark(22);
  await _benchmark(90);
}
