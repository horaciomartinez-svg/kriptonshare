class AppConstants {
  // === SUPABASE CONFIG ===
  // Reemplazar con tus credenciales reales de Supabase
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // === LÍMITES FREEMIUM (Versión Gratuita) ===
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxLinksPerMonth = 50;
  static const int maxDurationHours = 72; // 72 horas máximo
  static const int maxDurationSeconds = 72 * 3600; // 259200 segundos
  static const int maxDownloadsDefault = 5; // Límite default descargas
  
  // === CRYPTO CONFIG ===
  static const int aesKeySize = 32; // 256 bits
  static const int aesNonceSize = 12; // 96 bits for GCM
  static const int aesTagSize = 16; // 128 bits MAC
  static const int saltSize = 16; // 128 bits
  static const int chunkSize = 256 * 1024; // 256 KB chunks
  
  // === UI CONSTANTS ===
  static const int animationDurationMs = 300;
  static const int encryptionAnimationDurationMs = 800;
  static const int cardBorderRadius = 12;
  static const double fabMargin = 24;
  
  // === DEEP LINKS ===
  static const String appDomain = 'kriptonshare.com';
  static const String deepLinkScheme = 'kriptonshare';
  static const String roomPath = '/room';
  
  // === STORAGE PROVIDER ===
  static const String storageProvider = 'r2'; // 'r2', 's3', 'supabase'
  static const String bucketName = 'kriptonshare-ephemeral';
  
  // === TELEMETRY ===
  static const int heartbeatIntervalSeconds = 30;
  static const int maxTelemetryBufferSize = 50;
  
  // === SUBSCRIPTION TIERS ===
  static const String tierFree = 'free';
  static const String tierPremium = 'premium';
  static const String tierEnterprise = 'enterprise';
  
  // === WATERMARK ===
  static const double watermarkOpacity = 0.35;
  static const double watermarkFontSize = 10;
  static const double watermarkRotationAngle = -45 * 3.14159265359 / 180; // -45 degrees in radians
}
