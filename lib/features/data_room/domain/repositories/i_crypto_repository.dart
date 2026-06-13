import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class ICryptoRepository {
  // Generar clave AES-256-GCM
  Future<Either<Failure, List<int>>> generateKey();

  // Cifrar datos
  Future<Either<Failure, List<int>>> encrypt({
    required List<int> data,
    required List<int> key,
  });

  // Descifrar datos
  Future<Either<Failure, List<int>>> decrypt({
    required List<int> encryptedData,
    required List<int> key,
  });

  // Derivar clave de fragmento URI
  Future<Either<Failure, List<int>>> deriveKeyFromFragment(String fragment);

  // Generar fragmento URI seguro
  Future<Either<Failure, String>> generateSecureFragment();

  // Hash SHA-256
  Future<Either<Failure, List<int>>> hash(List<int> data);

  // Generar nonce aleatorio
  Future<Either<Failure, List<int>>> generateNonce(int length);
}
