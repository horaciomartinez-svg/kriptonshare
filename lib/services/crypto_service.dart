import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/export.dart';

import '../utils/constants.dart';

/// Servicio de cifrado local (AES-256-GCM + PBKDF2)
/// La clave AES nunca sale del dispositivo.
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _secureRandom = Random.secure();

  /// Genera salt criptográficamente seguro
  List<int> generateSalt() {
    final salt = Uint8List(AppConstants.saltSize);
    for (int i = 0; i < salt.length; i++) {
      salt[i] = _secureRandom.nextInt(256);
    }
    return salt.toList();
  }

  /// Genera nonce (IV) para AES-GCM
  List<int> generateNonce() {
    final nonce = Uint8List(AppConstants.aesNonceSize);
    for (int i = 0; i < nonce.length; i++) {
      nonce[i] = _secureRandom.nextInt(256);
    }
    return nonce.toList();
  }

  /// Deriva clave AES-256 desde contraseña del usuario + salt (PBKDF2)
  List<int> deriveKey(String password, List<int> salt) {
    final derivator = PBKDF2KeyDerivator(
      HMac(SHA256Digest(), 64),
    );
    final params = Pbkdf2Parameters(
      Uint8List.fromList(salt),
      100000, // 100k iterations
      AppConstants.aesKeySize,
    );
    derivator.init(params);
    final key = derivator.process(Uint8List.fromList(utf8.encode(password)));
    return key.toList();
  }

  /// Cifra datos con AES-256-GCM
  /// Retorna [ciphertext + authTag] (concatenados)
  Map<String, List<int>> encrypt({
    required Uint8List plaintext,
    required List<int> key,
    required List<int> nonce,
  }) {
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(Uint8List.fromList(key)),
      AppConstants.aesTagSize * 8, // tag size in bits
      Uint8List.fromList(nonce),
      Uint8List(0), // no additional authenticated data
    );
    cipher.init(true, params);

    final output = Uint8List(cipher.getOutputSize(plaintext.length));
    final len = cipher.processBytes(plaintext, 0, plaintext.length, output, 0);
    cipher.doFinal(output, len);

    // En GCM, el output incluye ciphertext + authTag al final
    final ciphertext = output.sublist(0, output.length - AppConstants.aesTagSize);
    final authTag = output.sublist(output.length - AppConstants.aesTagSize);

    return {
      'ciphertext': ciphertext.toList(),
      'authTag': authTag.toList(),
    };
  }

  /// Descifra datos con AES-256-GCM
  Uint8List decrypt({
    required List<int> ciphertext,
    required List<int> key,
    required List<int> nonce,
    required List<int> authTag,
  }) {
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(Uint8List.fromList(key)),
      AppConstants.aesTagSize * 8,
      Uint8List.fromList(nonce),
      Uint8List(0),
    );
    cipher.init(false, params);

    // Reconstruir ciphertext + authTag
    final input = Uint8List(ciphertext.length + authTag.length);
    input.setAll(0, ciphertext);
    input.setAll(ciphertext.length, authTag);

    final output = Uint8List(cipher.getOutputSize(input.length));
    final len = cipher.processBytes(input, 0, input.length, output, 0);
    final finalLen = cipher.doFinal(output, len);

    return output.sublist(0, len + finalLen);
  }

  /// Cifra un archivo completo en chunks de 256KB
  Future<Map<String, dynamic>> encryptFile({
    required Uint8List fileBytes,
    required String password,
  }) async {
    final salt = generateSalt();
    final nonce = generateNonce();
    final key = deriveKey(password, salt);

    // Cifrar todo el archivo
    final result = encrypt(
      plaintext: fileBytes,
      key: key,
      nonce: nonce,
    );

    // La clave AES se almacena en el Keystore/Keychain nativo
    // Aquí solo retornamos los parámetros para el payload
    return {
      'salt': salt,
      'nonce': nonce,
      'ciphertext': result['ciphertext'],
      'authTag': result['authTag'],
      'key': key, // <-- Este key se guarda en KeyStore, NO se transmite
    };
  }

  /// Descifra un archivo completo
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
}
