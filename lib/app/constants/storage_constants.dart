// lib/app/constants/storage_constants.dart
// Fuente única de verdad de los límites de almacenamiento y expiración.

abstract class StorageConstants {
  // Límites de archivo
  static const int freemiumMaxFileBytes = 10 * 1024 * 1024;    // 10 MB
  static const int premiumMaxFileBytes  = 100 * 1024 * 1024;   // 100 MB

  // Cuota de bóveda Premium
  static const int premiumBaseStorageBytes = 1073741824;       // 1 GB
  static const int storageAddonBytes       = 1073741824;       // +1 GB por add-on

  // Expiración de enlaces
  static const int freemiumMaxLinkHours = 48;                  // 2 días
  static const int premiumMaxLinkDays   = 30;                  // 30 días

  // Límites Freemium
  static const int freemiumMaxActiveLinks = 3;
  static const int freemiumMaxMonthlyLinks = 20;
}
