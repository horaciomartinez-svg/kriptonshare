// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'KRIPTONSHARE';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Reintentar';

  @override
  String get delete => 'Eliminar';

  @override
  String get share => 'Compartir';

  @override
  String get revoke => 'Revocar';

  @override
  String get dataRoom => 'Data Room';

  @override
  String get premium => 'Premium';

  @override
  String get premiumBadge => 'PREMIUM';

  @override
  String get free => 'Free';

  @override
  String get enabled => 'Activado';

  @override
  String get disabled => 'Desactivado';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get splashTagline => 'Data Room Efímero';

  @override
  String get onboardingTitle1 => 'Cifrado Zero-Knowledge';

  @override
  String get onboardingBody1 =>
      'Tus archivos se encriptan localmente con AES-256 antes de subir a la nube. Nadie más que tú posee el control de las llaves.';

  @override
  String get onboardingTitle2 => 'Enlaces Efímeros';

  @override
  String get onboardingBody2 =>
      'Configura la autodestrucción física de tus documentos. Elige la duración exacta de validez del link de acceso seguro.';

  @override
  String get onboardingTitle3 => 'Seguridad Forense';

  @override
  String get onboardingBody3 =>
      'Mitiga el espionaje corporativo y las filtraciones físicas con marcas de agua dinámicas y bloqueo de capturas de pantalla.';

  @override
  String get onboardingSkip => 'OMITIR';

  @override
  String get onboardingStart => 'EMPEZAR';

  @override
  String get onboardingNext => 'SIGUIENTE';

  @override
  String get authTagline => 'Tu dispositivo es el único custodio';

  @override
  String get loginTab => 'Iniciar sesión';

  @override
  String get registerTab => 'Crear cuenta';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'tu@email.com';

  @override
  String get emailRequired => 'Email requerido';

  @override
  String get emailInvalid => 'Email inválido';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordRequired => 'Contraseña requerida';

  @override
  String passwordMinLength(int min) {
    return 'Mínimo $min caracteres';
  }

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get confirmPasswordRequired => 'Confirmación requerida';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get registerButton => 'Crear cuenta gratis';

  @override
  String get loginInvalidCredentials =>
      'Credenciales inválidas. Intenta de nuevo.';

  @override
  String get registerError => 'Error al crear cuenta. Intenta con otro email.';

  @override
  String get biometricLoginReason =>
      'Verifica tu identidad para completar el inicio de sesión';

  @override
  String get biometricAuthCancelled => 'Autenticación biométrica cancelada.';

  @override
  String freePlanInfo(int maxMB, int maxLinks, int maxHours) {
    return 'Plan gratuito: $maxMB MB máximo · $maxLinks links/mes · ${maxHours}h de duración';
  }

  @override
  String get termsNotice =>
      'Al registrarte, aceptas los términos de soberanía de datos. KRIPTONSHARE nunca almacena tus archivos en texto plano.';

  @override
  String get lockTitle => 'KRIPTONSHARE bloqueado';

  @override
  String get lockSubtitle => 'Usa tu huella o rostro para desbloquear la app.';

  @override
  String get lockVerifying => 'Verificando...';

  @override
  String get unlockWithBiometrics => 'Desbloquear con biometría';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get authCancelled => 'Autenticación cancelada.';

  @override
  String get noSavedCredentials =>
      'No hay credenciales guardadas. Inicia sesión manualmente.';

  @override
  String get invalidSavedCredentials =>
      'Las credenciales guardadas ya no son válidas. Inicia sesión manualmente.';

  @override
  String get biometricSettingsTitle => 'Configuración de Biometría';

  @override
  String get biometricIntro =>
      'Protege el acceso a tus Data Rooms con tu identidad biométrica.';

  @override
  String get biometricNotAvailableTitle => 'Biometría no disponible';

  @override
  String get biometricNoSensorsBody =>
      'Este dispositivo no tiene sensores biométricos configurados.';

  @override
  String get testNow => 'Probar ahora';

  @override
  String get verifyAgain => 'Verificar de nuevo';

  @override
  String get biometricUnlock => 'Desbloqueo biométrico';

  @override
  String get dataSovereigntyTitle => 'Soberanía de datos';

  @override
  String get dataSovereigntyBody =>
      'Tu huella o rostro nunca salen del dispositivo. No almacenamos datos biométricos.';

  @override
  String get quickAccessTitle => 'Acceso rápido';

  @override
  String get quickAccessBody =>
      'Desbloquea KRIPTONSHARE sin escribir tu contraseña cada vez.';

  @override
  String get extraProtectionTitle => 'Protección adicional';

  @override
  String get extraProtectionBody =>
      'La biometría complementa tu contraseña; no la reemplaza.';

  @override
  String get securityTitle => 'Seguridad';

  @override
  String get faceId => 'Face ID';

  @override
  String get iris => 'Iris';

  @override
  String get fingerprint => 'Huella digital';

  @override
  String get faceIdDescription =>
      'Usa Face ID para desbloquear KRIPTONSHARE de forma segura.';

  @override
  String get irisDescription => 'Usa el reconocimiento de iris para acceder.';

  @override
  String get fingerprintDescription =>
      'Usa tu huella digital para desbloquear la app rápidamente.';

  @override
  String get biometricEnableReason =>
      'Confirma tu huella o rostro para activar el desbloqueo biométrico';

  @override
  String get biometricAuthSuccess => 'Autenticación biométrica exitosa.';

  @override
  String get biometricEnableCancelled =>
      'No se pudo activar: autenticación cancelada.';

  @override
  String get biometricUnlockEnabledMsg =>
      'Desbloqueo biométrico activado. Se pedirá después de iniciar sesión.';

  @override
  String get biometricUnlockDisabledMsg => 'Desbloqueo biométrico desactivado.';

  @override
  String biometricQueryError(String message) {
    return 'Error al consultar biometría: $message';
  }

  @override
  String get dashboardTab => 'Dashboard';

  @override
  String get linksTab => 'Enlaces';

  @override
  String get profileTab => 'Perfil';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get capacity => 'Capacidad';

  @override
  String get duration => 'Duración';

  @override
  String get plan => 'Plan';

  @override
  String get receivedFiles => 'Archivos recibidos';

  @override
  String get noReceivedFiles => 'No has recibido archivos';

  @override
  String get receivedFilesHint =>
      'Los enlaces enviados a tu correo aparecerán aquí';

  @override
  String get activeLinks => 'Enlaces activos';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get noActiveLinks => 'Sin enlaces activos';

  @override
  String get createFirstDataRoom => 'Crea tu primer Data Room seguro';

  @override
  String get expiresLabel => 'Expira';

  @override
  String expiresInMinutes(int minutes) {
    return 'en ${minutes}m';
  }

  @override
  String expiresInHours(int hours) {
    return 'en ${hours}h';
  }

  @override
  String expiresInDays(int days) {
    return 'en ${days}d';
  }

  @override
  String get analyticsTooltip => 'Analytics';

  @override
  String get newDataRoom => 'Nuevo Data Room';

  @override
  String get attachFile => 'Adjuntar Archivo';

  @override
  String get cameraToVault => 'Cámara a Vault';

  @override
  String get noPublicGallery => 'Sin galería pública';

  @override
  String get encryptionPasswordLabel => 'Contraseña de cifrado';

  @override
  String get passwordNotStoredHint => 'No se almacena en la nube';

  @override
  String get recipientEmailOptional => 'Email del receptor (opcional)';

  @override
  String get encryptAndGenerateLink => 'Cifrar y generar enlace';

  @override
  String get pdfPreviewGeneratedNotice =>
      'Se generará una vista previa PDF segura para el receptor';

  @override
  String get dataRoomReadyBanner => 'Data Room listo en Cloudflare';

  @override
  String get previewGenerationFailedNotice =>
      'El archivo se compartió, pero no se pudo generar la vista previa. El receptor podrá descargarlo si tú lo permites.';

  @override
  String get protectingFiles => 'Protegiendo tus archivos...';

  @override
  String get encryptingAesStep => '> Cifrando con AES-256...';

  @override
  String get generatingPreviewStep => '> Generando vista previa segura...';

  @override
  String get syncingR2Step => '> Sincronizando en R2...';

  @override
  String fileExceedsPlanLimit(String maxSize) {
    return 'El archivo excede el límite de $maxSize de tu plan';
  }

  @override
  String captureExceedsPlanLimit(String maxSize) {
    return 'La captura excede el límite de $maxSize de tu plan';
  }

  @override
  String get cameraAccessCancelled => 'Acceso a la cámara cancelado o denegado';

  @override
  String get enterEncryptionPassword => 'Ingresa una contraseña de cifrado';

  @override
  String get sessionExpired => 'Sesión expirada';

  @override
  String get filePickError => 'Error al seleccionar archivo';

  @override
  String get shareDataRoomTitle => 'Data Room Confidencial Compartido';

  @override
  String get expirationLabel => 'Expiración:';

  @override
  String get oneHour => '1 hora';

  @override
  String get default24h => '24h (Defecto)';

  @override
  String get max48Hours => '48 horas (Máx)';

  @override
  String get max30Days => 'Máx 30 días';

  @override
  String daysUnit(int count) {
    return '$count Días';
  }

  @override
  String hoursUnit(int count) {
    return '$count Horas';
  }

  @override
  String get upsellTitle => '¿Envíos sin pausas?';

  @override
  String get upsellCta => '> Ve a Premium';

  @override
  String linkExpiresNotice(int hours) {
    return 'Este enlace expira en ${hours}h.';
  }

  @override
  String get adSampleTitle => 'IBM Cloud Security';

  @override
  String get adSampleBody => 'Protege la infraestructura de tu empresa.';

  @override
  String get adSampleCta => 'CONOCER MÁS';

  @override
  String get searchByIdOrEmail => 'Buscar por ID o email';

  @override
  String get createLink => 'Crear enlace';

  @override
  String get noSearchResults => 'No se encontraron resultados';

  @override
  String get createFirstFromDashboard =>
      'Crea tu primer Data Room desde el dashboard';

  @override
  String get deleteDocumentTitle => 'Eliminar documento';

  @override
  String get deleteDocumentWarning =>
      'Esta acción es irreversible. El documento será eliminado permanentemente.';

  @override
  String get linkRevoked => 'Enlace revocado';

  @override
  String get documentDeleted => 'Documento eliminado';

  @override
  String shareMessageTemplate(String url, String appUrl, int hours) {
    return 'Documento seguro via KRIPTONSHARE\n\n$url\n\nSi el link no abre la app, usa:\n$appUrl\n\nEste enlace expira en ${hours}h.';
  }

  @override
  String hoursRemaining(int hours) {
    return '${hours}h restantes';
  }

  @override
  String daysRemaining(int days) {
    return '${days}d restantes';
  }

  @override
  String viewsCount(int count) {
    return '$count vistas';
  }

  @override
  String get activeTag => 'ACTIVO';

  @override
  String get expiredTag => 'EXPIRADO';

  @override
  String expiresOn(String date) {
    return 'Expira: $date';
  }

  @override
  String get expiredLinksTitle => 'Enlaces expirados';

  @override
  String get noExpiredLinks => 'Sin enlaces expirados';

  @override
  String get allDataRoomsActive => 'Todos tus Data Rooms están activos';

  @override
  String sizeExpiredOn(String size, String date) {
    return '$size · Expiró el $date';
  }

  @override
  String get linkIdMissing => 'ID de enlace no proporcionado';

  @override
  String get linkInvalidExpiredRevoked =>
      'Enlace inválido, expirado o revocado';

  @override
  String recipientOnlyNotice(String recipient) {
    return 'Este archivo fue enviado a $recipient. Inicia sesión con esa cuenta para acceder.';
  }

  @override
  String documentLoadError(String error) {
    return 'Error al cargar el documento: $error';
  }

  @override
  String get invalidDecryptedFile =>
      'El archivo descifrado no es válido. Verifica la contraseña.';

  @override
  String get incompleteFileData => 'Datos de archivo incompletos o corruptos.';

  @override
  String get wrongPasswordOrCorrupt =>
      'Contraseña incorrecta o archivo corrupto';

  @override
  String get secureDocument => 'Documento seguro';

  @override
  String get encryptedFileReceived => 'Has recibido un archivo cifrado';

  @override
  String get senderPasswordPrompt =>
      'Ingresa la contraseña que te proporcionó el emisor para descifrarlo';

  @override
  String get decryptionPasswordLabel => 'Contraseña de descifrado';

  @override
  String get decryptAndView => 'Descifrar y ver';

  @override
  String get selfDestructNotice =>
      'Este documento se autodestruye tras la caducidad. No se almacena en tu dispositivo.';

  @override
  String get decryptingDocument => 'Descifrando documento...';

  @override
  String get unexpectedError => 'Error inesperado';

  @override
  String pdfOpenError(String error) {
    return 'No se pudo abrir el PDF:\n$error';
  }

  @override
  String get pdfViewerFallback =>
      'El visor nativo no pudo mostrar este PDF. Por seguridad no se permite abrirlo fuera de la app.';

  @override
  String get decryptedVideo => 'Video descifrado';

  @override
  String get playVideo => 'Reproducir video';

  @override
  String get protectedFormat => 'Formato protegido';

  @override
  String get officeNotViewable =>
      'Los documentos de Microsoft Office y otros formatos no se visualizan directamente dentro de la app por seguridad.';

  @override
  String get convertToPdfAdvice =>
      'Para compartir este contenido de forma segura, conviértelo a PDF antes de subirlo.';

  @override
  String get confidentialBanner => 'KRIPTONSHARE | CONFIDENCIAL';

  @override
  String get secureMode => 'MODO SEGURO';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String videoPlaybackError(String error) {
    return 'No se pudo reproducir el video: $error';
  }

  @override
  String fileSizeAndType(String size, String mimeType) {
    return '$size · $mimeType';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get yourCurrentPlan => 'Tu plan actual';

  @override
  String get maxFileSize => 'Tamaño máximo por archivo';

  @override
  String get dataRoomStorage => 'Almacenamiento Data Room';

  @override
  String get notAvailable => 'No disponible';

  @override
  String get monthlyLinks => 'Enlaces mensuales';

  @override
  String get maxDuration => 'Duración máxima';

  @override
  String hoursValue(int count) {
    return '$count horas';
  }

  @override
  String get encryptionLabel => 'Cifrado';

  @override
  String get watermarkLabel => 'Marca de agua';

  @override
  String get institutionalPassiveWatermark => 'Institucional pasiva';

  @override
  String get biometricsLabel => 'Biometría';

  @override
  String get configureBiometrics => 'Configura huella o Face ID';

  @override
  String get unlockFullCapacity => 'Desbloquea capacidad total';

  @override
  String get premiumBenefits =>
      '100 MB por archivo, enlaces ilimitados, caducidad personalizable, marca de agua forense dinámica.';

  @override
  String get managePremiumVault => 'Gestionar Bóveda Premium';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get noDataAvailable => 'No hay datos disponibles';

  @override
  String get dataRoomsMetrics => 'Métricas de tus Data Rooms';

  @override
  String get topLinks => 'Top Links';

  @override
  String get linkEvents => 'Eventos del link';

  @override
  String get viewExpiredLinks => 'Ver enlaces expirados';

  @override
  String get totalLinks => 'Links totales';

  @override
  String get activeLabel => 'Activos';

  @override
  String get expiredLabel => 'Expirados';

  @override
  String get totalViews => 'Vistas totales';

  @override
  String get downloadsLabel => 'Descargas';

  @override
  String get avgDuration => 'Duración promedio';

  @override
  String get events24h => 'Eventos 24h';

  @override
  String get storageLabel => 'Almacenamiento';

  @override
  String get noActivityYet => 'Sin actividad aún';

  @override
  String get topLinksEmptyHint => 'Los links más vistos aparecerán aquí';

  @override
  String get unnamedDocument => 'Documento sin nombre';

  @override
  String viewsDownloadsSummary(int views, int downloads) {
    return '$views vistas · $downloads descargas';
  }

  @override
  String get noEventsForLink => 'No hay eventos registrados para este link';

  @override
  String pageN(int number) {
    return 'Página $number';
  }

  @override
  String get eventPageView => 'Vista de página';

  @override
  String get eventDownloadComplete => 'Descarga completada';

  @override
  String get eventDownloadStart => 'Inicio de descarga';

  @override
  String get eventScreenshotBlocked => 'Screenshot bloqueado';

  @override
  String get enterDataRoomPassword => 'Ingresa la contraseña del Data Room';

  @override
  String get dataRoomNotFound => 'No se encontró el Data Room';

  @override
  String get dataRoomPasswordLabel => 'Contraseña del Data Room';

  @override
  String get selectFileToDecrypt =>
      'Selecciona un archivo para descifrarlo en memoria RAM';

  @override
  String encryptedFilesCount(int count, String size) {
    return '$count Archivos Cifrados · $size';
  }

  @override
  String aes256Encrypted(String size) {
    return '$size · Cifrado AES-256';
  }

  @override
  String get officeDocsNotViewable =>
      'Los documentos Office no se visualizan directamente por seguridad.';

  @override
  String confidentialUserWatermark(String email) {
    return '$email • CONFIDENCIAL';
  }

  @override
  String get storageManagementTitle => 'Bóveda y Almacenamiento Data Room';

  @override
  String get premiumActive => 'PREMIUM ACTIVO';

  @override
  String get freePlanBadge => 'PLAN GRATUITO';

  @override
  String get dataRoomCapacity => 'Capacidad del Data Room';

  @override
  String storageUsedOf(String used, String max) {
    return '$used / $max Usados';
  }

  @override
  String get expandDataRoomAddon => 'Expandir Data Room (+1 GB por \$5/mes)';

  @override
  String get subscriptionOptions => 'Opciones de Suscripción';

  @override
  String get monthlyPlan => 'Mensual';

  @override
  String get monthlyPrice => '\$19.00 / mes';

  @override
  String get annualPlan => 'Anual';

  @override
  String get annualPrice => '\$189.00 / año';

  @override
  String get annualSavings => 'Ahorras \$39 USD/año';

  @override
  String get subscribeToPremium => 'Suscribirse a Premium';

  @override
  String get restorePurchases => 'Restaurar Compras';

  @override
  String get testModeLabel => 'MODO PRUEBA (debug)';

  @override
  String get testModeDescription =>
      'Activa Premium sin RevenueCat ni Google Cloud para evaluar la interfaz.';

  @override
  String get deactivateTestPremium => 'Desactivar Premium de prueba';

  @override
  String get activateTestPremium => 'Activar Premium de prueba';

  @override
  String get testPremiumActivated => 'Premium de prueba activado';

  @override
  String get testPremiumDeactivated => 'Premium de prueba desactivado';

  @override
  String get noOfferingsAvailable => 'No hay ofertas disponibles';

  @override
  String get subscriptionActivated => 'Suscripción activada';

  @override
  String get noAddonsAvailable => 'No hay add-ons disponibles';

  @override
  String get storageExpanded => 'Almacenamiento ampliado';

  @override
  String remainingLinks(int remaining) {
    return '$remaining restantes';
  }

  @override
  String get freePlanLabel => 'Plan gratuito';

  @override
  String get errorUserNotAuthenticated => 'Usuario no autenticado';

  @override
  String get errorQuotaExceeded => 'Límite de cuotas excedido';

  @override
  String get errorUploadNotAllowed =>
      'No se puede completar la subida. Verifica los límites de tu plan.';

  @override
  String get errorSignInFailed => 'No se pudo iniciar sesión';

  @override
  String get errorUserRecordMissing =>
      'Usuario autenticado pero no encontrado en la tabla users.';

  @override
  String get errorCreateRoomFailed => 'No se pudo crear el Data Room';

  @override
  String get errorInvalidLinkFragment => 'Enlace inválido: fragmento ausente';

  @override
  String get errorInvalidKey => 'Clave inválida';

  @override
  String get errorDecryptionFailed => 'Error al descifrar';

  @override
  String errorDecryptionWithDetail(String error) {
    return 'Error descifrando: $error';
  }

  @override
  String get dataRoomExplorerTitle => 'Mi Bóveda Data Room';

  @override
  String get premiumCapacityLabel => 'CAPACIDAD DATA ROOM PREMIUM';

  @override
  String storageUsedSummary(String used, String max, int percent) {
    return '$used de $max usados ($percent%)';
  }

  @override
  String get expandVaultAddon => 'Expandir Bóveda (+1 GB por \$5/mes)';

  @override
  String get uploadFileMax => 'Subir archivo (≤ 100 MB)';

  @override
  String get newVirtualFolder => 'Nueva carpeta virtual';

  @override
  String get batchUploadAction => 'Subida múltiple a carpeta';

  @override
  String get batchUploadHint => 'Selección en lote';

  @override
  String get virtualFoldersSection => 'Carpetas virtuales';

  @override
  String get unfiledFilesSection => 'Archivos individuales en Bóveda';

  @override
  String folderCardSummary(int count, String size) {
    return '$count archivos · $size';
  }

  @override
  String linkStatusActiveExpires(int days) {
    return 'Enlace: Activo (expira en $days días)';
  }

  @override
  String get sendAction => 'Enviar';

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByLastModified => 'Última modificación';

  @override
  String get sortBySize => 'Tamaño';

  @override
  String get gridView => 'Vista de cuadrícula';

  @override
  String get listView => 'Vista de lista';

  @override
  String get emptyDataRoomTitle => 'Tu Data Room está vacío';

  @override
  String get emptyDataRoomHint =>
      'Sube archivos cifrados o crea tu primera carpeta virtual';

  @override
  String get folderNameLabel => 'Nombre de la carpeta';

  @override
  String get folderDescriptionLabel => 'Descripción (opcional)';

  @override
  String get createFolder => 'Crear carpeta';

  @override
  String get folderCreated => 'Carpeta creada';

  @override
  String get batchUploadTitle => 'Subida múltiple';

  @override
  String batchProgressSummary(int completed, int total) {
    return '$completed de $total archivos subidos';
  }

  @override
  String batchCompletedMessage(int count) {
    return '$count archivos cifrados en Data Room';
  }

  @override
  String batchFileSkippedTooLarge(String filename) {
    return '$filename excede 100 MB y fue omitido';
  }

  @override
  String get selectDestinationFolder => 'Selecciona la carpeta de destino';

  @override
  String filesSelected(int count) {
    return '$count archivos seleccionados';
  }

  @override
  String dataRoomLobbyTitle(String name) {
    return 'DATA ROOM: $name';
  }

  @override
  String linkExpiresInLabel(int days) {
    return 'Enlace expira en: $days días';
  }

  @override
  String get recipientEmailRequiredTitle =>
      'Ingrese su correo para acceder a los documentos';

  @override
  String get dataRoomAccessAuditNotice =>
      'Ingresa tu correo para continuar. El acceso quedará auditado.';

  @override
  String get accessAction => 'Acceder';

  @override
  String get availableDocumentsSection =>
      'Documentos disponibles en la carpeta';

  @override
  String get encryptedAtOrigin => 'Cifrado en Origen';

  @override
  String get openAndDecryptInRam => 'Abrir y descifrar en memoria RAM';

  @override
  String get ramDecryptionNotice =>
      'Los documentos se descifran exclusivamente en RAM volátil y cuentan con auditoría de lectura activa.';

  @override
  String get shareSheetTitle => 'Compartir de forma segura';

  @override
  String get shareSingleFile => 'Archivo individual';

  @override
  String get shareFullFolder => 'Carpeta completa';

  @override
  String get requireRecipientEmailLabel => 'Correo del receptor obligatorio';

  @override
  String get requireRecipientEmailSubtitle =>
      'El receptor deberá ingresar su correo antes de acceder';

  @override
  String get enableWatermarkLabel => 'Marca de agua dinámica';

  @override
  String get enableWatermarkSubtitle =>
      'Superpone correo, IP y fecha del receptor sobre el documento';

  @override
  String get expirationPremiumNotice =>
      'Premium: los enlaces pueden durar hasta 30 días';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get shareQrCode => 'Compartir código QR';

  @override
  String get errorExpirationMustBeFuture =>
      'La fecha de expiración debe ser futura.';

  @override
  String get errorExpirationPremiumMax =>
      'Premium: La expiración máxima de un enlace es de 30 días.';

  @override
  String get errorExpirationFreemiumMax =>
      'Plan Gratis: La expiración máxima de un enlace es de 48 horas.';

  @override
  String get expirationPremiumValid => 'Expiración Premium válida (≤ 30 días).';

  @override
  String get expirationFreemiumValid => 'Expiración Freemium válida (≤ 48 h).';

  @override
  String get eventLobbyEnter => 'Ingreso al lobby';

  @override
  String get eventFileOpen => 'Archivo abierto';

  @override
  String get eventLobbyExit => 'Salida del lobby';
}
