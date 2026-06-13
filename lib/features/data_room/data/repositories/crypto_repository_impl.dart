import 'dart:convert';
import 'dart:typed_data';
import '../../domain/repositories/i_crypto_repository.dart';
import '../../../../services/crypto_service.dart';

/// Implementación del Repositorio Criptográfico con Zero-Knowledge.
/// La clave de encriptación nunca sale del dispositivo.
/// Se distribuye vía fragmentos de URI (#) según RFC 3986.
class CryptoRepositoryImpl implements ICryptoRepository {
  final CryptoService _cryptoService;

  CryptoRepositoryImpl(this._cryptoService);

  @override
  Future<Map<String, dynamic>> encryptPayload(Uint8List fileBytes, String password) async {
    // Retorna el ciphertext, salt, nonce, authTag y la llave derivada
    return await _cryptoService.encryptFile(
      fileBytes: fileBytes,
      password: password,
    );
  }

  @override
  String buildZeroKnowledgeLink(String roomId, List<int> encryptionKey) {
    // Transforma la llave asimétrica a Base64
    final String base64Key = base64Url.encode(encryptionKey);

    // El secreto se ancla AL FINAL de la URL después del '#'.
    // Supabase NO recibirá esta porción. El navegador/sistema operativo
    // nunca envía el fragmento en la petición HTTP (RFC 3986).
    return 'https://kriptonshare.com/room/$roomId#key=$base64Key';
  }

  @override
  List<int> extractKeyFromFragment(Uri deepLink) {
    // Extrae el fragmento en el dispositivo receptor de forma local
    if (!deepLink.hasFragment) {
      throw Exception('Enlace inválido o corrupto: Fragmento ZK ausente.');
    }

    final String fragment = deepLink.fragment;

    if (!fragment.startsWith('key=')) {
      throw Exception('Firma criptográfica no encontrada en el fragmento.');
    }

    final String base64Key = fragment.substring(4);
    return base64Url.decode(base64Key);
  }

  @override
  Future<Uint8List> decryptPayload({
    required List<int> ciphertext,
    required List<int> key,
    required List<int> nonce,
    required List<int> authTag,
  }) async {
    return await _cryptoService.decryptFile(
      ciphertext: ciphertext,
      key: key,
      nonce: nonce,
      authTag: authTag,
    );
  }

  @override
  List<int> deriveKey(String password, List<int> salt) {
    return _cryptoService.deriveKey(password, salt);
  }
}
