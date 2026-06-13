import 'dart:typed_data';

/// Interfaz de Repositorio Criptográfico (Capa de Dominio).
/// Abstrae todas las operaciones de cifrado y Zero-Knowledge.
abstract class ICryptoRepository {
  /// Encripta el archivo usando AES-256-GCM.
  /// Retorna el ciphertext, salt, nonce, authTag y la llave derivada.
  Future<Map<String, dynamic>> encryptPayload(Uint8List fileBytes, String password);

  /// Compone el enlace Zero-Knowledge inyectando la clave en el fragmento (#).
  /// La clave nunca viaja por la red; solo el fragmento local del receptor la extrae.
  String buildZeroKnowledgeLink(String roomId, List<int> encryptionKey);

  /// Extrae la clave criptográfica desde el fragmento de URL sin enviarla al servidor.
  List<int> extractKeyFromFragment(Uri deepLink);

  /// Descifra un payload usando la clave extraída localmente.
  Future<Uint8List> decryptPayload({
    required List<int> ciphertext,
    required List<int> key,
    required List<int> nonce,
    required List<int> authTag,
  });

  /// Deriva una clave AES-256 desde una contraseña + salt (PBKDF2).
  List<int> deriveKey(String password, List<int> salt);
}
