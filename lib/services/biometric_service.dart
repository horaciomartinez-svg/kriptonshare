import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

export 'package:local_auth/local_auth.dart' show BiometricType;

/// Servicio que centraliza la autenticación biométrica y la persistencia
/// del estado "desbloqueo biométrico habilitado".
///
/// La biometría actúa como un bloqueo de pantalla local: si el usuario
/// habilita el desbloqueo, la próxima vez que abra la app se le pedirá
/// huella / rostro antes de acceder al dashboard.
class BiometricService {
  static const String _enabledKey = 'biometric_unlock_enabled';

  final LocalAuthentication _localAuth;
  final SharedPreferences _prefs;

  BiometricService._(this._localAuth, this._prefs);

  static Future<BiometricService> create() async {
    final localAuth = LocalAuthentication();
    final prefs = await SharedPreferences.getInstance();
    return BiometricService._(localAuth, prefs);
  }

  /// Indica si el dispositivo tiene hardware biométrico disponible.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Devuelve los tipos de biometría disponibles (huella, face, iris...).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Verifica tanto hardware como biometría enrolada.
  Future<bool> isBiometricAvailable() async {
    final canCheck = await canCheckBiometrics();
    final available = await getAvailableBiometrics();
    return canCheck && available.isNotEmpty;
  }

  /// Muestra el diálogo nativo de autenticación biométrica.
  /// Retorna `true` si el usuario se autenticó correctamente.
  Future<bool> authenticate({String? localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason ??
            'Verifica tu identidad para acceder a KRIPTONSHARE',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      // Propaga códigos conocidos para que la UI pueda mostrar mensajes útiles.
      switch (e.code) {
        case auth_error.notAvailable:
          throw Exception('La biometría no está disponible.');
        case auth_error.notEnrolled:
          throw Exception('No hay huella o rostro configurado.');
        case auth_error.passcodeNotSet:
          throw Exception('Configura un PIN/patrón en el dispositivo.');
        case auth_error.lockedOut:
          throw Exception('Demasiados intentos fallidos. Intenta más tarde.');
        default:
          throw Exception('Error de autenticación: ${e.message}');
      }
    }
  }

  /// Estado persistente del desbloqueo biométrico en la app.
  bool get isBiometricEnabled => _prefs.getBool(_enabledKey) ?? false;

  /// Activa/desactiva el desbloqueo biométrico.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_enabledKey, enabled);
  }
}
