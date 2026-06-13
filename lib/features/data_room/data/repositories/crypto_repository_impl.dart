import 'dart:convert';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:pointycastle/export.dart';
import '../../domain/repositories/i_crypto_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/crypto_service.dart';

/// Implementación del Repositorio Criptográfico con Zero-Knowledge.
class CryptoRepositoryImpl implements ICryptoRepository {
  final CryptoService _cryptoService;

  CryptoRepositoryImpl(this._cryptoService);

  @override
  Future<Either<Failure, List<int>>> generateKey() async {
    try {
      final key = _cryptoService.generateSalt(); // Usamos salt como base para key
      return Right(key);
    } catch (e) {
      return Left(CryptoFailure('Error generating key: $e'));
    }
  }

  @override
  Future<Either<Failure, List<int>>> encrypt({
    required List<int> data,
    required List<int> key,
  }) async {
    try {
      final nonce = _cryptoService.generateNonce();
      final result = _cryptoService.encrypt(
        plaintext: Uint8List.fromList(data),
        key: key,
        nonce: nonce,
      );
      // Concatenar: nonce + ciphertext + authTag
      final encrypted = [
        ...nonce,
        ...result['ciphertext']!,
        ...result['authTag']!,
      ];
      return Right(encrypted);
    } catch (e) {
      return Left(CryptoFailure('Error encrypting data: $e'));
    }
  }

  @override
  Future<Either<Failure, List<int>>> decrypt({
    required List<int> encryptedData,
    required List<int> key,
  }) async {
    try {
      // Extraer nonce, ciphertext, authTag del formato: nonce(12) + ciphertext + authTag(16)
      const nonceSize = 12;
      const tagSize = 16;
      final nonce = encryptedData.sublist(0, nonceSize);
      final ciphertext = encryptedData.sublist(nonceSize, encryptedData.length - tagSize);
      final authTag = encryptedData.sublist(encryptedData.length - tagSize);

      final decrypted = _cryptoService.decrypt(
        ciphertext: ciphertext,
        key: key,
        nonce: nonce,
        authTag: authTag,
      );
      return Right(decrypted.toList());
    } catch (e) {
      return Left(CryptoFailure('Error decrypting data: $e'));
    }
  }

  @override
  Future<Either<Failure, List<int>>> deriveKeyFromFragment(String fragment) async {
    try {
      if (!fragment.startsWith('key=')) {
        return const Left(CryptoFailure('Invalid fragment format'));
      }
      final base64Key = fragment.substring(4);
      final key = base64Decode(base64Key); // Requiere dart:convert import
      return Right(key.toList());
    } catch (e) {
      return Left(CryptoFailure('Error deriving key from fragment: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> generateSecureFragment() async {
    try {
      final key = _cryptoService.generateSalt();
      final base64Key = base64Encode(key); // Requiere dart:convert import
      return Right('key=$base64Key');
    } catch (e) {
      return Left(CryptoFailure('Error generating secure fragment: $e'));
    }
  }

  @override
  Future<Either<Failure, List<int>>> hash(List<int> data) async {
    try {
      // Usamos SHA-256 via pointycastle
      final digest = SHA256Digest();
      final hash = digest.process(Uint8List.fromList(data));
      return Right(hash.toList());
    } catch (e) {
      return Left(CryptoFailure('Error hashing data: $e'));
    }
  }

  @override
  Future<Either<Failure, List<int>>> generateNonce(int length) async {
    try {
      final nonce = _cryptoService.generateNonce();
      // Ajustar al length solicitado si es necesario
      if (length <= nonce.length) {
        return Right(nonce.sublist(0, length));
      }
      return Right(nonce);
    } catch (e) {
      return Left(CryptoFailure('Error generating nonce: $e'));
    }
  }
}
