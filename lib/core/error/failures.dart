import 'package:equatable/equatable.dart';

/// Clase base para fallas en la capa de dominio.
/// Agnóstica de frameworks externos.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Falla de servidor remoto (Supabase, R2, etc.)
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Falla de caché local (SQLite)
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Falla de red (sin conexión)
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Falla criptográfica (clave inválida, corrupción de datos)
class CryptoFailure extends Failure {
  const CryptoFailure(super.message);
}

/// Falla de validación de negocio (límites de plan, expiración)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
