// lib/utils/constants.dart

class AppConstants {
  // === SUPABASE CLOUD ROUTING ===
  static String get supabaseUrl => const String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://olskjkbyzpowxlhjhovu.supabase.co');

  static String get supabaseAnonKey => const String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9sc2tqa2J5enBvd3hsaGpob3Z1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NDQ2NzMsImV4cCI6MjA5NjQyMDY3M30.Q5YAMmsZdc9EZuh-f6FyAsiegE4ZSYcuAtS2HsTM1Xg');

  // === LÍMITES PLAN GRATUITO (FREEMIUM) ===
  static const int freeMaxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int freeMaxActiveLinks = 3;
  static const int freeMaxDurationHours = 48; // 2 días máximo
  static const int freeDefaultDurationHours = 24; // Selección por defecto

  // === LÍMITES PLAN PREMIUM / ENTERPRISE ===
  static const int premiumMaxFileSizeBytes = 100 * 1024 * 1024; // 100 MB por archivo
  static const int premiumMaxStorageBytes = 2 * 1024 * 1024 * 1024; // 2 GB de bóveda acumulada
  static const int premiumMaxDurationHours = 30 * 24; // 720 Horas (30 días máximo)
  static const int premiumDefaultDurationHours = 24; // Mantiene 24h por defecto

  // === ALIASES DE COMPATIBILIDAD (Free tier) ===
  static const int maxFileSizeBytes = freeMaxFileSizeBytes;
  static const int maxLinksPerMonth = 20;
  static const int maxActiveLinks = freeMaxActiveLinks;
  static const int maxDurationHours = freeMaxDurationHours;
  static const int defaultDurationHours = freeDefaultDurationHours;
  static const int maxDurationSeconds = freeMaxDurationHours * 3600;
  static const int maxDownloadsDefault = 5;

  // === CRYPTO ENGINES (AES-256-GCM + PBKDF2) ===
  static const int aesKeySize = 32; // 256 bits
  static const int aesNonceSize = 12; // 96 bits para GCM
  static const int aesTagSize = 16; // 128 bits para etiqueta MAC
  static const int saltSize = 16; // 128 bits
  static const int chunkSize = 256 * 1024; // 256 KB Chunks

  // === ECOVÍA DE ENLACES PROFUNDOS ===
  static const String appDomain = 'kriptonshare.com';
  static const String deepLinkScheme = 'kriptonshare';
  static const String roomPath = '/room';

  static String shareUrl(String linkId) => 'https://$appDomain$roomPath/$linkId';
  static String appLinkUrl(String linkId) => '$deepLinkScheme://room/$linkId';

  // === INFRAESTRUCTURA DE ALMACENAMIENTO PERIMETRAL: CLOUDFLARE R2 ===
  static const String storageProvider = 'r2'; // Forzar enrutamiento a R2
  static const String bucketName = 'kriptonshare-ephemeral';

  // Credenciales S3-compatibles de Cloudflare R2 (Access Key ID / Secret Access Key).
  // Se inyectan en compilación AOT mediante --dart-define o mediante secrets del pipeline.
  static const String r2Endpoint = String.fromEnvironment('R2_ENDPOINT',
      defaultValue: 'https://67bec4f06347f4a150e12b5b2f23f77b.r2.cloudflarestorage.com');
  static const String r2AccessKeyId = String.fromEnvironment('R2_ACCESS_KEY_ID',
      defaultValue: 'aa9f9e8a50c6bddd81f698b4445f4bd1');
  static const String r2SecretAccessKey = String.fromEnvironment('R2_SECRET_ACCESS_KEY',
      defaultValue: '0682f41640fe890f8651186fca141d9b7539d606a877df3ba016b528d3b98b7b');

  // === UI CONSTANTS ===
  static const int animationDurationMs = 300;
  static const int encryptionAnimationDurationMs = 800;
  static const int cardBorderRadius = 12;
  static const double fabMargin = 24;

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
