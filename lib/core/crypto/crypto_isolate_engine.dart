// lib/core/crypto/crypto_isolate_engine.dart
// Ejecuta operaciones AES-256-GCM + PBKDF2 en un Isolate Dart para no
// bloquear el hilo de UI con archivos grandes (hasta 100 MB).

import 'dart:isolate';
import 'dart:typed_data';
import 'crypto_service.dart';

/// Cifra [fileBytes] con [password] dentro de un Isolate.
/// Retorna un mapa con salt, nonce, ciphertext, authTag y key.
Future<Map<String, Uint8List>> encryptFileInIsolate({
  required Uint8List fileBytes,
  required String password,
}) async {
  return Isolate.run(() async {
    final service = CryptoService();
    return service.encryptFile(fileBytes: fileBytes, password: password);
  });
}

/// Descifra un payload completo `salt || nonce || ciphertext || authTag`
/// dentro de un Isolate.
Future<Uint8List> decryptFileInIsolate({
  required Uint8List encryptedBytes,
  required String password,
}) async {
  return Isolate.run(() async {
    final service = CryptoService();
    return service.decryptFileBytes(
      encryptedBytes: encryptedBytes,
      password: password,
    );
  });
}
