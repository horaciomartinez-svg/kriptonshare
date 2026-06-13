import 'dart:io';

/// Abstracción de verificación de conectividad de red.
/// Agnóstica de implementaciones externas.
abstract class NetworkInfo {
  /// Verifica si hay conectividad a internet.
  Future<bool> get isConnected;
}

/// Implementación básica usando dart:io.
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
