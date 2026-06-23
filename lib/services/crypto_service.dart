import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/export.dart';

import '../utils/constants.dart';

/// Servicio de cifrado local con AES-256-GCM + PBKDF2.
///
/// ### Modelo de amenaza
/// - La contraseña del usuario **nunca** se almacena.
/// - La clave AES-256 se deriva de la contraseña con PBKDF2 (100k iteraciones)
///   y un salt aleatorio de 128 bits.
/// - Cada archivo utiliza un **nonce/IV único** de 96 bits generado con
///   `Random.secure()`.
/// - La confidencialidad y la integridad están garantizadas por **AES-256-GCM**,
///   que produce un ciphertext autenticado y un MAC (authTag) de 128 bits.
/// - El payload resultante tiene el formato: `salt || nonce || ciphertext || authTag`.
///
/// ### Streaming / chunked processing
/// Aunque las interfaces públicas reciben buffers completos (`Uint8List`),
/// internamente el cifrado y descifrado se procesan por chunks de
/// [AppConstants.chunkSize] (256 KB) para reducir la presión de memoria
/// con archivos grandes.
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _secureRandom = math.Random.secure();

  /// Genera un salt criptográficamente seguro de [AppConstants.saltSize] bytes.
  ///
  /// El salt se usa como entrada aleatoria para PBKDF2 y debe ser único
  /// por archivo/operación de derivación.
  List<int> generateSalt() {
    final salt = Uint8List(AppConstants.saltSize);
    for (int i = 0; i < salt.length; i++) {
      salt[i] = _secureRandom.nextInt(256);
    }
    return salt.toList();
  }

  /// Genera un nonce (también conocido como IV) de [AppConstants.aesNonceSize]
  /// bytes (12 bytes, 96 bits), que es el tamaño recomendado para AES-GCM.
  ///
  /// El nonce debe ser único para cada clave+operación. Nunca reutilizar un
  /// nonce con la misma clave bajo GCM, ya que compromete tanto la
  /// confidencialidad como la integridad.
  List<int> generateNonce() {
    final nonce = Uint8List(AppConstants.aesNonceSize);
    for (int i = 0; i < nonce.length; i++) {
      nonce[i] = _secureRandom.nextInt(256);
    }
    return nonce.toList();
  }

  /// Deriva una clave AES-256 (32 bytes) desde una contraseña y un salt
  /// usando PBKDF2-HMAC-SHA256 con 100.000 iteraciones.
  ///
  /// [password] Contraseña proporcionada por el usuario.
  /// [salt]     Salt aleatorio de [AppConstants.saltSize] bytes.
  List<int> deriveKey(String password, List<int> salt) {
    final derivator = PBKDF2KeyDerivator(
      HMac(SHA256Digest(), 64),
    );
    final params = Pbkdf2Parameters(
      Uint8List.fromList(salt),
      100000, // 100k iteraciones (OWASP recomienda >= 600k en 2023; ajustar según UX)
      AppConstants.aesKeySize,
    );
    derivator.init(params);
    final key = derivator.process(Uint8List.fromList(utf8.encode(password)));
    return key.toList();
  }

  /// Cifra [plaintext] con AES-256-GCM.
  ///
  /// Retorna un mapa con:
  /// - `ciphertext`: bytes cifrados (sin el authTag).
  /// - `authTag`:    MAC de autenticación de 16 bytes.
  ///
  /// La clave [key] debe tener 32 bytes (AES-256).
  /// El [nonce] debe tener 12 bytes y ser único por clave.
  ///
  /// Internamente se procesa el plaintext por chunks de 256 KB para evitar
  /// picos de memoria con archivos grandes.
  Map<String, List<int>> encrypt({
    required Uint8List plaintext,
    required List<int> key,
    required List<int> nonce,
  }) {
    _validateKey(key);
    _validateNonce(nonce);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(Uint8List.fromList(key)),
      AppConstants.aesTagSize * 8, // tag size in bits: 128
      Uint8List.fromList(nonce),
      Uint8List(0), // no additional authenticated data (AAD)
    );
    cipher.init(true, params);

    final output = Uint8List(cipher.getOutputSize(plaintext.length));
    var outputOffset = 0;

    // Procesar plaintext en chunks para reducir uso de memoria.
    for (var i = 0; i < plaintext.length; i += AppConstants.chunkSize) {
      final end = math.min(i + AppConstants.chunkSize, plaintext.length);
      final written = cipher.processBytes(plaintext, i, end - i, output, outputOffset);
      outputOffset += written;
    }

    // doFinal en modo encrypt genera el authTag y lo concatena al output.
    final finalLen = cipher.doFinal(output, outputOffset);
    final totalLen = outputOffset + finalLen;

    // En GCM, el output real es: ciphertext || authTag
    final ciphertext = output.sublist(0, totalLen - AppConstants.aesTagSize);
    final authTag = output.sublist(totalLen - AppConstants.aesTagSize, totalLen);

    return {
      'ciphertext': ciphertext.toList(),
      'authTag': authTag.toList(),
    };
  }

  /// Descifra datos cifrados con AES-256-GCM y verifica la integridad.
  ///
  /// [ciphertext] Datos cifrados (sin el authTag).
  /// [key]        Clave AES-256 de 32 bytes.
  /// [nonce]      Nonce de 12 bytes usado durante el cifrado.
  /// [authTag]    MAC de autenticación de 16 bytes.
  ///
  /// Si el [authTag] no coincide con los datos, GCM lanzará
  /// [InvalidCipherTextException], indicando que el ciphertext fue alterado
  /// (tampering) o corrupto.
  ///
  /// Internamente se reconstruye `ciphertext || authTag` y se procesa por
  /// chunks de 256 KB.
  Uint8List decrypt({
    required List<int> ciphertext,
    required List<int> key,
    required List<int> nonce,
    required List<int> authTag,
  }) {
    _validateKey(key);
    _validateNonce(nonce);
    _validateAuthTag(authTag);

    if (ciphertext.isEmpty) {
      throw ArgumentError('ciphertext cannot be empty');
    }

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(Uint8List.fromList(key)),
      AppConstants.aesTagSize * 8,
      Uint8List.fromList(nonce),
      Uint8List(0),
    );
    cipher.init(false, params);

    // Reconstruir ciphertext || authTag para que GCM valide el MAC.
    final input = Uint8List(ciphertext.length + authTag.length);
    input.setAll(0, ciphertext);
    input.setAll(ciphertext.length, authTag);

    final output = Uint8List(cipher.getOutputSize(input.length));
    var outputOffset = 0;

    // Procesar ciphertext || authTag en chunks. processBytes reconoce que
    // los últimos [aesTagSize] bytes son el MAC y los guarda internamente
    // para la validación, sin escribirlos en el output.
    for (var i = 0; i < input.length; i += AppConstants.chunkSize) {
      final end = math.min(i + AppConstants.chunkSize, input.length);
      final written = cipher.processBytes(input, i, end - i, output, outputOffset);
      outputOffset += written;
    }

    // doFinal valida el authTag acumulado y escribe los últimos bytes de
    // plaintext pendientes del buffer interno.
    final finalLen = cipher.doFinal(output, outputOffset);

    return Uint8List.sublistView(output, 0, outputOffset + finalLen);
  }

  /// Cifra un archivo completo a partir de [fileBytes] y una contraseña.
  ///
  /// Deriva la clave con PBKDF2, genera salt+nonce aleatorios y cifra el
  /// contenido por chunks. Retorna un mapa con todos los parámetros
  /// necesarios para el descifrado:
  /// - `salt`:       salt de 16 bytes.
  /// - `nonce`:      nonce/IV de 12 bytes.
  /// - `ciphertext`: bytes cifrados.
  /// - `authTag`:    MAC de 16 bytes.
  /// - `key`:        clave AES-256 derivada (debe almacenarse de forma segura,
  ///                 idealmente en el Keystore/Keychain nativo; **no debe**
  ///                 transmitirse al servidor).
  Future<Map<String, dynamic>> encryptFile({
    required Uint8List fileBytes,
    required String password,
  }) async {
    final salt = generateSalt();
    final nonce = generateNonce();
    final key = deriveKey(password, salt);

    final result = encrypt(
      plaintext: fileBytes,
      key: key,
      nonce: nonce,
    );

    return {
      'salt': salt,
      'nonce': nonce,
      'ciphertext': result['ciphertext'],
      'authTag': result['authTag'],
      'key': key,
    };
  }

  /// Descifra un archivo completo verificando su integridad.
  ///
  /// Reconstruye `ciphertext || authTag` y descifra por chunks. Si el MAC
  /// es inválido, lanza [InvalidCipherTextException].
  Future<Uint8List> decryptFile({
    required List<int> ciphertext,
    required List<int> key,
    required List<int> nonce,
    required List<int> authTag,
  }) async {
    return decrypt(
      ciphertext: ciphertext,
      key: key,
      nonce: nonce,
      authTag: authTag,
    );
  }

  // ─────────────────────────────── Validaciones ───────────────────────────────

  void _validateKey(List<int> key) {
    if (key.length != AppConstants.aesKeySize) {
      throw ArgumentError(
        'Invalid AES key size: ${key.length} bytes. Expected ${AppConstants.aesKeySize} bytes.',
      );
    }
  }

  void _validateNonce(List<int> nonce) {
    if (nonce.length != AppConstants.aesNonceSize) {
      throw ArgumentError(
        'Invalid nonce size: ${nonce.length} bytes. Expected ${AppConstants.aesNonceSize} bytes.',
      );
    }
  }

  void _validateAuthTag(List<int> authTag) {
    if (authTag.length != AppConstants.aesTagSize) {
      throw ArgumentError(
        'Invalid authTag size: ${authTag.length} bytes. Expected ${AppConstants.aesTagSize} bytes.',
      );
    }
  }
}
