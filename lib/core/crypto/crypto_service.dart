// lib/core/crypto/crypto_service.dart
// Abstracción unificada del motor criptográfico de KRIPTONSHARE.

import 'dart:typed_data';
import '../../services/crypto_service.dart' as legacy;

/// Wrapper del motor AES-256-GCM + PBKDF2 existente para la nueva arquitectura.
class CryptoService {
  final legacy.CryptoService _engine = legacy.CryptoService();

  /// Cifra [fileBytes] con [password] y retorna un mapa con salt, nonce,
  /// ciphertext, authTag y key como Uint8List.
  Future<Map<String, Uint8List>> encryptFile({
    required Uint8List fileBytes,
    required String password,
  }) async {
    final result = await _engine.encryptFile(
      fileBytes: fileBytes,
      password: password,
    );
    return {
      'salt': Uint8List.fromList(result['salt']! as List<int>),
      'nonce': Uint8List.fromList(result['nonce']! as List<int>),
      'ciphertext': Uint8List.fromList(result['ciphertext']! as List<int>),
      'authTag': Uint8List.fromList(result['authTag']! as List<int>),
      'key': Uint8List.fromList(result['key']! as List<int>),
    };
  }

  /// Descifra un payload completo `salt || nonce || ciphertext || authTag`
  /// usando únicamente la contraseña del usuario.
  Future<Uint8List> decryptFileBytes({
    required Uint8List encryptedBytes,
    required String password,
  }) async {
    return _engine.decryptFileBytes(
      encryptedBytes: encryptedBytes,
      password: password,
    );
  }

  /// Descifra componentes individuales.
  Uint8List decrypt({
    required List<int> ciphertext,
    required List<int> key,
    required List<int> nonce,
    required List<int> authTag,
  }) {
    return _engine.decrypt(
      ciphertext: ciphertext,
      key: key,
      nonce: nonce,
      authTag: authTag,
    );
  }

  /// Genera un salt criptográficamente seguro.
  Uint8List generateSalt() => Uint8List.fromList(_engine.generateSalt());

  /// Genera un nonce de 12 bytes para AES-GCM.
  Uint8List generateNonce() => Uint8List.fromList(_engine.generateNonce());

  /// Deriva una clave AES-256 desde una contraseña y un salt.
  Uint8List deriveKey(String password, List<int> salt) =>
      Uint8List.fromList(_engine.deriveKey(password, salt));
}
