import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio que guarda las credenciales de Supabase de forma segura en el
/// Keystore (Android) / Keychain (iOS), protegidas por autenticación biométrica.
///
/// Esto permite que el usuario inicie sesión con huella/rostro sin tener que
/// escribir su contraseña cada vez, siempre que previamente haya optado por
/// habilitar el desbloqueo biométrico.
class SecureCredentialService {
  static const _emailKey = 'biometric_email';
  static const _passwordKey = 'biometric_password';

  // Opciones que restringen el acceso al almacenamiento seguro al menos a
  // un bloqueo de pantalla (Android) / dispositivo desbloqueado (iOS).
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Guarda el email y password cifrados en el almacenamiento seguro del SO.
  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  /// Recupera las credenciales guardadas. Retorna null si no existen.
  static Future<Map<String, String>?> getCredentials() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return {'email': email, 'password': password};
  }

  /// Elimina las credenciales guardadas.
  static Future<void> deleteCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  /// Indica si hay credenciales guardadas.
  static Future<bool> hasCredentials() async {
    final credentials = await getCredentials();
    return credentials != null;
  }
}
