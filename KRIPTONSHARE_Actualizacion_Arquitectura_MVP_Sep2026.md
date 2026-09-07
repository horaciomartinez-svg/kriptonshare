# KRIPTONSHARE — Re-alineación de Arquitectura para el Lanzamiento MVP (v1.0)

> **Documento de especificación técnica para implementación automatizada (Opencode / agente de código).**
> Fecha: 2026-09-07 · Estado: Aprobado para implementación · Alcance: Re-alineación completa del producto al modelo de negocio y arquitectura del MVP
> >
> **Instrucción para el agente de código:** este documento es autocontenido y contractual. Las rutas de archivos, nombres de columnas, constantes, firmas de métodos y fragmentos de código deben implementarse tal como se describen. Cuando se cite un fragmento existente del repositorio, búscalo y modifícalo en el lugar indicado. No renombres símbolos existentes fuera de lo especificado. Al final hay una checklist de tareas ordenadas: ejecútala en ese orden. Verifica siempre contra el estado real del repositorio antes de editar; si un fragmento citado ya no existe tal cual, localiza su equivalente actual y aplica la intención del cambio.

---

## 0. Resumen ejecutivo de los cambios

Este documento revierte la Fase 1 (conversión Office→PDF con Docker + Gotenberg), elimina la publicidad, elimina el Virtual Data Room por carpetas, actualiza los límites y precios de los planes, agrega el plan Business, la prueba gratuita de 14 días sin tarjeta, paywalls contextuales e instrumentación de métricas de activación y conversión.

| # | Cambio | Resultado |
| --- | --- | --- |
| 1 | Quitar anuncios | La app no contiene publicidad en ningún plan |
| 2 | Sin conversión Office→PDF | Solo se aceptan formatos visualizables in-app; aviso bloqueante al seleccionar un formato no soportado |
| 3 | i18n completo | Todo mensaje visible existe en los 5 idiomas (es, en, pt, fr, de) vía ARB |
| 4 | Sin Docker/Gotenberg | Se elimina `infra/conversion/` completo y todo el código cliente asociado |
| 5 | Sin carpeta virtual | Solo links de archivos individuales, cifrados y enviados uno a la vez; se elimina el Data Room por carpetas |
| 6 | RevenueCat | Premium $12.99/mes · $103.99/año (33% off); Business $29.99/mes · $239.99/año; grandfathering |
| 7 | Trial 14 días | Todo usuario nuevo recibe Premium por 14 días sin registrar tarjeta |
| 8 | Paywalls contextuales + métricas | Paywall en el momento de fricción + tabla `funnel_events` con activación, aha, toques de paywall y conversión por trigger |
| 9 | Logo primario en el inicio | El cuadro verde con la letra "K" de la pantalla de inicio se sustituye por el logo primario oficial de la marca |

### Matriz de planes objetivo (contractual)

| Parámetro | FREE | PREMIUM | BUSINESS |
| --- | --- | --- | --- |
| Precio | $0 | **$12.99/mes** · **$103.99/año** (33% off, "4 meses gratis") | **$29.99/mes** · **$239.99/año** |
| Tamaño máx. por archivo | 20 MB | 100 MB | 200 MB |
| Links por mes | 20 | Ilimitados | Ilimitados |
| Links activos simultáneos | 3 | Ilimitados | Ilimitados |
| Duración máxima del link | 7 días (168 h) | 30 días (720 h) | 60 días (1,440 h) |
| Almacenamiento total efímero | Sin bóveda (solo archivos con link activo) | 1 GB | 5 GB (suma de links activos) |
| Watermark | Institucional pasiva | Dinámica (email + fecha) | Dinámica (email + fecha) |
| Analytics | Básicos (vistas/descargas) | Completos (por página) | Completos (por página) |
| Anuncios | **Ninguno** | Ninguno | Ninguno |

> **Grandfathering:** los primeros suscriptores conservan el precio de lanzamiento de por vida. En RevenueCat esto se resuelve no cambiando el precio de los productos existentes y creando productos nuevos (`premium_monthly_v2`, etc.) cuando suba el precio de lista en el futuro. No se requiere código para el grandfathering en esta iteración: basta con **nunca editar el precio de un product ID ya publicado**.

---

## 1. Estado actual del repositorio (lo que existe hoy)

Verificado en `github.com/horaciomartinez-svg/kriptonshare` (rama `main`):

| Componente | Archivo | Rol actual |
| --- | --- | --- |
| Cifrado AES-256-GCM + PBKDF2 | `lib/services/crypto_service.dart` | `encryptFileInIsolate()`; payload `salt(16) ‖ nonce(12) ‖ ciphertext ‖ authTag(16)` |
| Upload + link (flujo vivo) | `lib/providers/file_provider.dart` → `FileService.uploadAndCreateLink()` | Cifra en Isolate, sube a R2 con SigV4, **incluye el bloque de conversión Office→PDF de la Fase 1** y callback `onConversionStatus` |
| Visor seguro | `lib/screens/viewer/viewer_screen.dart` | `pdfrx` para PDF, imágenes, texto, video; **rama de vista previa Office→PDF**; watermark dinámico |
| Pantalla de upload | `lib/features/upload/presentation/screens/upload_screen.dart` | Panel dual archivo/cámara, slider de duración, **overlay con esqueleto de anuncio (zonas 40/40/20)** y estados de conversión |
| Diálogo de aviso Office | `lib/features/upload/presentation/widgets/ms_office_warning_dialog.dart` | Avisa que el archivo se convertirá a PDF |
| Detección de formatos Office | `lib/utils/office_formats.dart` | `OfficeFormats.isConvertible()` |
| Cliente de conversión | `lib/services/conversion_service.dart` | Llama al gateway Gotenberg |
| Infra de conversión | `infra/conversion/` | `docker-compose.yml` (Gotenberg 8 + gateway Deno), `gateway/`, `README.md` |
| Constantes de planes | `lib/utils/constants.dart` | `AppConstants` (10 MB free, 48 h, 20 links/mes, 3 activos, 100 MB premium, 720 h, 2 GB), `PremiumLimits`, `Pricing` ($19/$189/$5 por GB) |
| Suscripciones | `lib/core/services/purchase_service.dart` + `lib/features/data_room/presentation/notifiers/storage_upsell_notifier.dart` | RevenueCat con flag `ENABLE_REVENUECAT` + mock; offerings `premium` y `storage_addons` |
| Pantalla de planes | `lib/features/data_room/presentation/screens/storage_management_screen.dart` | Gauge de storage, tarjetas $19/$189, add-on +1 GB, simulador premium en debug |
| Data Room por carpetas | `lib/features/data_room/` (explorer, lobby, providers) + `lib/widgets/data_room_card.dart` | Carpetas virtuales, batch upload, lobby receptor por carpeta |
| Rutas | `lib/providers/router_provider.dart` | Incluye `/data-room`, `/folder-room/:folderLinkId`, `/f/:folderLinkId` |
| Esquema DB | `supabase/schema.sql` + `supabase/migrations/` | Tablas `users`, `files` (con `viewer_object_key`, `conversion_status`), `share_links` (con `folder_id`, `link_type`), `folders`, RPCs `check_upload_limits`, `validate_share_link_expiration` (48 h free), etc. |
| i18n | `lib/l10n/app_{es,en,pt,fr,de}.arb` + `l10n.yaml` | ARB con claves de conversión, anuncios y Data Room por carpetas |
| Doc de anuncios | `UPLOAD_AD_FLOW.md` | Describe el flujo de anuncio nativo (a eliminar) |
| Doc RevenueCat | `REVENUECAT_SETUP.md` | Precios y product IDs actuales (a actualizar) |
| Dependencia de anuncios | `pubspec.yaml` → `google_mobile_ads: ^7.0.0` | No se referencia en código Dart; solo existe el esqueleto visual |

---

## 2. Cambio 1 — Eliminar toda la publicidad

**Decisión de producto:** KRIPTONSHARE no muestra anuncios en ningún plan. La publicidad contradice el posicionamiento de privacidad/zero-knowledge.

1. **`pubspec.yaml`:** eliminar la dependencia `google_mobile_ads: ^7.0.0`. Ejecutar `flutter pub get` y verificar que `pubspec.lock` se regenera sin ella.
2. **`lib/features/upload/presentation/screens/upload_screen.dart`:** eliminar el overlay publicitario `_buildProcessingAdOverlay()` y sustituirlo por una vista de progreso limpia `_buildProcessingView()` que conserve únicamente la **Zona de Autoridad** (icono de candado con shimmer, `l10n.protectingFiles`, `LinearProgressIndicator` con `_progress` y la línea de estado). Se eliminan la zona de anuncio (40% central) y la zona de escape/upsell (20% inferior). Ver §9 para el código de referencia.
3. **`UPLOAD_AD_FLOW.md`:** eliminar el archivo.
4. **Claves ARB obsoletas:** eliminar de los 5 archivos `lib/l10n/app_*.arb` y regenerar: `adSampleTitle`, `adSampleBody`, `adSampleCta`, `upsellTitle`, `upsellCta` (el upsell dentro del overlay desaparece; los upsells ahora son paywalls contextuales, §10).
5. **Búsqueda de residuos:** `grep -ri "admob\|google_mobile_ads\|NativeAd\|BannerAd\|InterstitialAd" lib/ android/ ios/` no debe arrojar resultados tras el cambio. Si `android/app/build.gradle` o `AndroidManifest.xml` contienen el `APPLICATION_ID` de AdMob (`com.google.android.gms.ads.APPLICATION_ID` meta-data), eliminarlo.

---

## 3. Cambios 2 y 4 — Eliminar la conversión Office→PDF, Docker y Gotenberg

**Decisión de producto:** no hay conversión de MS Office a PDF. KRIPTONSHARE solo acepta archivos en formatos visualizables de forma segura dentro de la app. Al seleccionar un formato no soportado se muestra un aviso bloqueante.

### 3.1 Archivos a eliminar

- `infra/conversion/` — directorio completo (`docker-compose.yml`, `gateway/`, `README.md`).
- `lib/services/conversion_service.dart`
- `lib/utils/office_formats.dart` (se sustituye por `lib/utils/supported_formats.dart`, §3.2)
- `lib/features/upload/presentation/widgets/ms_office_warning_dialog.dart` (se sustituye por `unsupported_format_dialog.dart`, §3.3)

### 3.2 Nuevo `lib/utils/supported_formats.dart`

```dart
/// Formatos que KRIPTONSHARE acepta porque pueden visualizarse de forma
/// segura dentro de la app (descifrados en memoria, sin apps externas).
class SupportedFormats {
  /// MIME types exactos aceptados.
  static const Set<String> viewableMimeTypes = {
    'application/pdf',
    'text/plain',
    'text/markdown',
    'text/csv',
  };

  /// Prefijos MIME aceptados (imágenes y video reproducibles in-app).
  static const List<String> viewableMimePrefixes = [
    'image/',
    'video/',
  ];

  /// Extensiones aceptadas (fallback cuando el MIME llega vacío o como
  /// application/octet-stream, frecuente en Android).
  static const Set<String> viewableExtensions = {
    // Documentos
    'pdf',
    // Imágenes
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif',
    // Texto
    'txt', 'md', 'csv', 'log',
    // Video
    'mp4', 'mov', 'webm', 'mkv', 'm4v', '3gp',
  };

  /// Verdadero si el archivo puede visualizarse dentro de la app.
  static bool isViewable({required String mimeType, required String fileName}) {
    final mime = mimeType.toLowerCase();
    if (viewableMimeTypes.contains(mime)) return true;
    if (viewableMimePrefixes.any((p) => mime.startsWith(p))) return true;
    final ext = fileName.split('.').last.toLowerCase();
    return viewableExtensions.contains(ext);
  }

  /// Lista legible para el usuario, usada en el aviso bloqueante.
  /// Orden fija y contractual: se muestra tal cual en los 5 idiomas.
  static const String viewableListForHumans =
      'PDF, JPG, JPEG, PNG, GIF, WEBP, BMP, HEIC, TXT, MD, CSV, MP4, MOV, WEBM, MKV';
}
```

### 3.3 Nuevo `lib/features/upload/presentation/widgets/unsupported_format_dialog.dart`

Diálogo bloqueante (sin opción de continuar: el formato no soportado **no se sube**). Reutiliza el estilo visual del antiguo `MsOfficeWarningDialog` (mismo `Dialog`, colores y tipografía de `KriptonTheme`), con estas diferencias:

- Icono: `Icons.block` en `KriptonTheme.alertRed`.
- Título: `l10n.unsupportedFormatTitle`.
- Cuerpo: `l10n.unsupportedFormatBody(SupportedFormats.viewableListForHumans)`.
- Un solo botón `ElevatedButton` (electricLime) con `l10n.accept` que cierra el diálogo y **limpia la selección** del archivo.

### 3.4 `lib/features/upload/presentation/screens/upload_screen.dart`

1. **Bloqueo en la selección:** en `_pickFile()`, tras verificar el tamaño, evaluar:

```dart
final mimeType = file.mimeType ??
    lookupMimeType(file.name) ??
    'application/octet-stream';
if (!SupportedFormats.isViewable(mimeType: mimeType, fileName: file.name)) {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const UnsupportedFormatDialog(),
  );
  return; // No se asigna _selectedFile
}
```

2. **Eliminar** el campo `_isConverting`, `_conversionFailed`, `_conversionErrorDetail`, la llamada a `OfficeFormats.isConvertible` en `_uploadAndEncrypt()`, el `MsOfficeWarningDialog` previo al cifrado, el parámetro `onConversionStatus` en la llamada a `uploadAndCreateLink()`, el chip `pdfPreviewGeneratedNotice`, el aviso ámbar `previewGenerationFailedNotice` de la tarjeta de éxito y todo el overlay publicitario (ver §2).
3. El estado de progreso ahora tiene solo dos pasos: `encryptingAesStep` → `syncingR2Step`.
4. La cámara (`_captureSecurePhoto`) produce imágenes: no requiere validación de formato.

### 3.5 `lib/providers/file_provider.dart` — `FileService`

1. Eliminar los imports de `conversion_service.dart` y `office_formats.dart`.
2. En `uploadAndCreateLink()`: eliminar el parámetro `onConversionStatus`, el bloque completo "3. Conversión Office → PDF", las variables `viewerStorageKey`, `viewerSizeBytes`, `conversionStatus`, y las claves `'viewer_object_key'`, `'viewer_file_size_bytes'`, `'conversion_status'` del `insert` en `files`. El `debugPrint('[UPLOAD_START] ... URL de conversión ...')` se elimina.
3. En la limpieza best-effort tras fallo del insert: eliminar la referencia a `viewerStorageKey` (solo queda `_deleteR2Object(storageKey)`).
4. En `downloadAndDecryptFile()`: eliminar el parámetro `useViewerObject` y la selección de `file.viewerObjectKey`; el objeto a descargar vuelve a ser siempre `file.storageObjectKey`.
5. En `deleteFile()`: eliminar el borrado del objeto preview (`viewer_object_key`).

### 3.6 `lib/models/kripton_file.dart`

Eliminar los campos `viewerObjectKey`, `viewerFileSizeBytes`, `conversionStatus`, el helper `hasPdfPreview` y su mapeo en `fromJson`/`toJson`.

### 3.7 `lib/screens/viewer/viewer_screen.dart`

1. Eliminar el import de `office_formats.dart`, la variable `usePreview` en `_decryptAndView()` y el parámetro `useViewerObject` en la llamada a `downloadAndDecryptFile()`.
2. En `_buildDocumentViewer()`: eliminar la condición de vista previa Office; la rama PDF vuelve a ser solo `mimeType == 'application/pdf'`.
3. La rama final ("Formato protegido") se simplifica: ya no distingue `conversionStatus == 'failed'`; el mensaje es `l10n.unsupportedViewerBody(SupportedFormats.viewableListForHumans)` seguido de `l10n.convertToPdfAdvice` (esta clave se conserva). Nota: tras el bloqueo en origen (§3.4) esta rama solo la verían links creados antes de esta versión.
4. El timer de fallback de 3 s vuelve a aplicar solo cuando `mimeType == 'application/pdf'`.

### 3.8 Variante Clean Architecture (`lib/features/upload/data|domain`)

Buscar referencias a `ConversionService`, `OfficeFormats`, `viewer_object_key`, `conversion_status` y `onConversionStatus` en `lib/features/upload/` y eliminarlas con paridad a §3.5 (la especificación Fase 1 pedía replicar la conversión aquí; si existe, se revierte). El código debe compilar.

### 3.9 Base de datos (ver también §8)

Las columnas `viewer_object_key`, `viewer_file_size_bytes` y `conversion_status` de `files` se eliminan con una migración (§8), y las RPCs `get_shared_file_metadata()` y `get_received_files()` se redefinen con `CREATE OR REPLACE` sin esas columnas.

### 3.10 Documentación

- `README.md`: eliminar toda mención a la conversión Office→PDF, al conversion-gateway, a Gotenberg y a Docker; actualizar la lista de formatos soportados; el claim **zero-knowledge vuelve a ser absoluto**: ningún contenido en texto plano sale jamás del dispositivo del emisor.
- `KRIPTONSHARE_Fase1_Vista_Previa_Office_Especificacion.md`: mover a `docs/deprecated/` (o eliminar) con una nota al inicio: `> DEPRECADO 2026-09-07: la conversión Office→PDF se descartó para el MVP. Ver KRIPTONSHARE_Actualizacion_Arquitectura_MVP_Sep2026.md`.

---

## 4. Cambio 5 — Eliminar la carpeta virtual (Data Room por carpetas)

**Decisión de producto:** no existe carpeta virtual del usuario. Solo links de archivos cifrados individuales, que se cifran y envían **uno a la vez**. No hay subida en lote ni links de carpeta completa.

### 4.1 Código a eliminar

- `lib/features/data_room/` completo, **excepto** `presentation/screens/storage_management_screen.dart` y `presentation/notifiers/storage_upsell_notifier.dart`, que se **mueven** a una nueva ubicación: `lib/features/subscription/presentation/screens/plans_screen.dart` y `lib/features/subscription/presentation/notifiers/subscription_notifier.dart` (renombrar clases `StorageManagementScreen` → `PlansScreen`, `StorageUpsellNotifier` → `SubscriptionNotifier`, `storageUpsellNotifierProvider` → `subscriptionNotifierProvider`). Actualizar los imports.
- `lib/widgets/data_room_card.dart`.

### 4.2 Rutas (`lib/providers/router_provider.dart`)

- Eliminar las rutas `/data-room`, `/folder-room/:folderLinkId` y `/f/:folderLinkId` y sus imports.
- Eliminar `isFolderRoomRoute` del `redirect` (solo se preserva `/room/` tras login).
- La ruta `/storage-management` pasa a `/plans` apuntando a `PlansScreen` (mantener `/storage-management` como redirect a `/plans` para no romper enlaces internos existentes).

### 4.3 Referencias en otras pantallas

- `lib/screens/dashboard/dashboard_screen.dart`: eliminar cualquier entrada/banner al Data Room Explorer; el gauge de storage se elimina del dashboard (el storage se gestiona en `/plans`).
- `lib/screens/profile/profile_screen.dart`: la tarjeta "Tu plan actual" elimina la fila `dataRoomStorage`; el botón `managePremiumVault` navega a `/plans`. Actualizar el texto `premiumBenefits` (ver §7).
- `lib/features/data_room/` tenía providers (`data_room_providers.dart`, `folder_providers.dart`): eliminados con el directorio. Buscar y eliminar cualquier import residual (`grep -r "data_room" lib/ test/`).

### 4.4 Base de datos (migración en §8)

- `DROP TABLE IF EXISTS public.folders CASCADE;`
- `ALTER TABLE public.share_links DROP COLUMN IF EXISTS folder_id, DROP COLUMN IF EXISTS link_type;` y eliminar el constraint `chk_share_link_type_coherence` y el índice `idx_share_links_folder`.
- Eliminar las políticas `folders_public_read_active_link` y `files_public_read_active_folder_link`, y la columna `files.folder_id` si existe.
- `ALTER TABLE public.share_links ALTER COLUMN file_id SET NOT NULL;` (todo link es de archivo individual).

---

## 5. Nuevos límites de planes (contractual)

### 5.1 `lib/utils/constants.dart`

```dart
// === LÍMITES PLAN GRATUITO (FREEMIUM) ===
static const int freeMaxFileSizeBytes = 20 * 1024 * 1024; // 20 MB
static const int freeMaxActiveLinks = 3;                  // 3 links activos simultáneos
static const int freeMaxLinksPerMonth = 20;               // 20 links/mes
static const int freeMaxDurationHours = 168;              // 7 días máximo
static const int freeDefaultDurationHours = 24;           // Selección por defecto

// === LÍMITES PLAN PREMIUM ===
static const int premiumMaxFileSizeBytes = 100 * 1024 * 1024; // 100 MB por archivo
static const int premiumMaxStorageBytes = 1 * 1024 * 1024 * 1024; // 1 GB total
static const int premiumMaxDurationHours = 30 * 24;       // 720 h (30 días)
static const int premiumDefaultDurationHours = 24;

// === LÍMITES PLAN BUSINESS ===
static const int businessMaxFileSizeBytes = 200 * 1024 * 1024; // 200 MB por archivo
static const int businessMaxStorageBytes = 5 * 1024 * 1024 * 1024; // 5 GB en links activos
static const int businessMaxDurationHours = 60 * 24;      // 1,440 h (60 días)
static const int businessDefaultDurationHours = 24;

// === ALIASES DE COMPATIBILIDAD (Free tier) ===
static const int maxFileSizeBytes = freeMaxFileSizeBytes;
static const int maxLinksPerMonth = freeMaxLinksPerMonth;
static const int maxActiveLinks = freeMaxActiveLinks;
static const int maxDurationHours = freeMaxDurationHours;
static const int defaultDurationHours = freeDefaultDurationHours;
static const int maxDurationSeconds = freeMaxDurationHours * 3600;
static const int maxDownloadsDefault = 5;

// === SUBSCRIPTION TIERS ===
static const String tierFree = 'free';
static const String tierPremium = 'premium';
static const String tierBusiness = 'business';
// 'enterprise' se conserva en la DB por compatibilidad histórica y se trata como 'business'.

// Eliminar de AppConstants: conversionServiceUrl, conversionTimeout,
// conversionMaxBytesFor y cualquier constante de conversión.
```

```dart
/// Límites y capacidades por tier de suscripción.
class PremiumLimits {
  static const int freemiumMaxFileBytes = 20971520;       // 20 MB
  static const int premiumMaxFileBytes = 104857600;       // 100 MB
  static const int businessMaxFileBytes = 209715200;      // 200 MB
  static const int premiumBaseStorageBytes = 1073741824;  // 1 GB
  static const int businessBaseStorageBytes = 5368709120; // 5 GB
  static const int freemiumLinkTtlHours = 168;            // 7 días
  static const int premiumLinkTtlHours = 720;             // 30 días
  static const int businessLinkTtlHours = 1440;           // 60 días
  static const int freemiumMonthlyLinkQuota = 20;
  static const int freemiumMaxActiveLinks = 3;
  static const int trialDurationDays = 14;                // Trial Premium sin tarjeta
}

/// Precios públicos de suscripción (solo referencia en UI/marketing;
/// el precio real lo fija la tienda vía RevenueCat).
class Pricing {
  static const double premiumMonthlyUsd = 12.99;
  static const double premiumYearlyUsd = 103.99;   // 33% off — "4 meses gratis"
  static const double businessMonthlyUsd = 29.99;
  static const double businessYearlyUsd = 239.99;  // ~33% off
}
```

### 5.2 Slider de duración en `upload_screen.dart`

- Free: `maxRange = 168` (7 días), `divisions: 167`, etiquetas extremos `1 hora` / `7 días (Máx)`.
- Premium (y trial): sin cambios (720 h, 30 días).
- Business: `maxRange = 1440` (60 días), etiqueta de extremo `60 días (Máx)` (nueva clave ARB `max60Days`).
- Claves ARB: renombrar `max48Hours` → `max7Days` ("7 días (Máx)" / traducciones) en los 5 idiomas.

### 5.3 Base de datos (migración en §8)

- `users.max_file_size_bytes` default pasa a `20971520` (20 MB).
- `users.max_links_monthly` default `20` (sin cambio).
- `validate_share_link_expiration()`: el tope freemium pasa de 48 h a `INTERVAL '168 hours'`; premium se mantiene en 30 días; **business: 60 días** (`INTERVAL '1440 hours'`); los mensajes de error se actualizan ("7 días" en lugar de "48 horas").
- `check_upload_limits()`: el tope de links activos freemium (`3`) y mensual (`20`) ya coinciden; verificar que el límite de tamaño se lee de `users.max_file_size_bytes` (ya lo hace). **Agregar verificación de almacenamiento por tier:** la suma de `files.size_bytes` de archivos con links **activos** (links expirados o revocados excluidos — sus archivos los purga la lifecycle rule) más el archivo nuevo no puede exceder la cuota del tier (1 GB premium/trial, 5 GB business); si se excede, `reason_code='storage'`.
- Migración de datos: `UPDATE public.users SET max_file_size_bytes = 20971520 WHERE subscription_tier = 'free';`

---

## 6. Cambio 6 — RevenueCat: planes Premium y Business

### 6.1 Product IDs y offerings (contractual)

Crear en las tiendas (Google Play / App Store) y en RevenueCat, con estos identificadores **exactos**:

| Product ID | Tipo | Precio |
| --- | --- | --- |
| `premium_monthly` | Suscripción | $12.99 USD/mes |
| `premium_annual` | Suscripción | $103.99 USD/año |
| `business_monthly` | Suscripción | $29.99 USD/mes |
| `business_annual` | Suscripción | $239.99 USD/año |

En RevenueCat:

- **Entitlements:** `premium` (productos `premium_monthly`, `premium_annual`) y `business` (productos `business_monthly`, `business_annual`). El entitlement `business` debe conceder también todo lo de `premium` (en RevenueCat se configura el entitlement `business` como independiente; el código trata `business` como superconjunto, ver §6.3).
- **Offering `default` (current):** los 4 paquetes (`premium_monthly`, `premium_annual`, `business_monthly`, `business_annual`).
- Se **elimina** el offering `storage_addons` y el producto `storage_1gb` (ya no hay add-ons de almacenamiento: Premium incluye 1 GB total y Business 5 GB).
- **Grandfathering:** no modificar nunca el precio de un product ID publicado; futuras subidas de precio usan product IDs nuevos con sufijo de versión (p. ej. `premium_monthly_v2`).

### 6.2 `lib/core/services/purchase_service.dart`

1. `MockPurchaseServiceImpl.getOfferings()` devuelve ahora los 4 paquetes con los precios nuevos (`$12.99/mes`, `$103.99/año`, `$29.99/mes`, `$239.99/año`) y `addonPackages` vacío.
2. Eliminar `purchaseAddon()` del contrato `IPurchaseService` y de ambas implementaciones (no hay add-ons).
3. El mock de compra de Business debe llamar a una nueva función `setTierSimulation('business')` (ver §6.4) en lugar de `setPremiumSimulation(true)`.

### 6.3 Modelo de usuario y tier efectivo (`lib/models/user_model.dart`, `lib/providers/auth_provider.dart`)

1. `KriptonUser` gana los campos: `trialEndsAt` (DateTime?, de `users.trial_ends_at`), y el getter:

```dart
/// Tier efectivo: durante el trial (14 días desde el registro) el usuario
/// free disfruta los límites Premium. Después del trial, rige subscription_tier.
String get effectiveTier {
  if (subscriptionTier == 'business' || subscriptionTier == 'enterprise') return 'business';
  if (subscriptionTier == 'premium') return 'premium';
  if (trialEndsAt != null && trialEndsAt!.isAfter(DateTime.now())) return 'premium';
  return 'free';
}

bool get isPremium => effectiveTier == 'premium' || effectiveTier == 'business';
bool get isBusiness => effectiveTier == 'business';
bool get isInTrial => subscriptionTier == 'free' && trialEndsAt != null && trialEndsAt!.isAfter(DateTime.now());
```

2. Toda la lógica de límites del cliente que hoy consulta `user.isPremium` sigue funcionando sin cambios (el getter absorbe el trial).
3. `setPremiumSimulation(bool)` se sustituye por `setTierSimulation(String tier)` que escribe `subscription_tier` directamente (`free`/`premium`/`business`) y ajusta `max_storage_bytes` (1 GB premium, 5 GB business). Solo en debug (ya protegido por `kDebugMode` en la UI).

### 6.4 Pantalla de planes (`plans_screen.dart`, ex-`storage_management_screen.dart`)

1. Eliminar la sección de add-on "Expandir Data Room" y el gauge de "Capacidad Data Room" como elemento principal. El gauge de storage **se conserva** pero re-etiquetado: "Almacenamiento efímero total" (suma de archivos con links activos), usando `users.total_storage_used_bytes` / `users.max_storage_bytes`.
2. Sección de suscripción con **dos planes y cuatro paquetes**: tarjetas Premium ($12.99/mes · $103.99/año con badge "4 meses gratis") y Business ($29.99/mes · $239.99/año con badge "Ahorra 33%"). Cada plan muestra 3-4 bullets de beneficios (claves ARB nuevas, §7).
3. El simulador de prueba en debug ofrece ahora tres estados: Free / Premium / Business.
4. Mostrar banner de trial cuando `user.isInTrial`: `l10n.trialDaysRemaining(days)`.
5. Actualizar `REVENUECAT_SETUP.md`: nuevos product IDs, entitlements, offerings y precios; eliminar referencias a `storage_1gb` y al add-on.

### 6.5 Base de datos (migración en §8)

- `ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_subscription_tier_check;` y recrear el CHECK con `('free', 'premium', 'business', 'enterprise')`.
- `users.max_storage_bytes`: default `1073741824` (1 GB) — ya existe; `max_storage_premium_bytes` queda deprecada (eliminar columna y sus referencias en `auth_provider.dart` y en el código: usar solo `max_storage_bytes`). Al cambiar de tier (webhook de RevenueCat → función servidor, o `setTierSimulation` en debug), `max_storage_bytes` se fija a `1073741824` (premium/trial) o `5368709120` (5 GB, business).

---

## 7. Cambio 7 — Prueba gratis de 14 días de Premium (sin tarjeta)

**Mecánica:** el trial vive en la base de datos, no en la tienda (no hay cobro ni tarjeta).

### 7.1 Base de datos (migración en §8)

```sql
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ;

-- Trigger: todo usuario nuevo recibe 14 días de Premium.
CREATE OR REPLACE FUNCTION set_trial_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.trial_ends_at IS NULL THEN
    NEW.trial_ends_at := NOW() + INTERVAL '14 days';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_trial ON public.users;
CREATE TRIGGER trg_users_trial
  BEFORE INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION set_trial_on_signup();
```

**Autoridad en servidor:** `check_upload_limits()` y `validate_share_link_expiration()` deben resolver el tier efectivo en servidor, no confiar en `subscription_tier` a secas:

```sql
-- Dentro de ambas RPCs, sustituir la lectura del tier por:
SELECT CASE
         WHEN subscription_tier IN ('business', 'enterprise') THEN 'business'
         WHEN subscription_tier = 'premium' THEN 'premium'
         WHEN trial_ends_at IS NOT NULL AND trial_ends_at > NOW() THEN 'premium'
         ELSE 'free'
       END
INTO v_tier
FROM public.users WHERE id = p_user_id;
```

### 7.2 App

1. `auth_provider.dart` (`_createPublicUserRecord` y `signUp`): dejar de escribir campos que el trigger ya resuelve; no escribir `trial_ends_at` desde el cliente (lo fija el trigger; defensa contra clientes modificados).
2. **Dashboard:** si `user.isInTrial`, mostrar un banner bajo el saludo: `l10n.trialBanner(days)` ("Prueba Premium: te quedan {days} días") con CTA a `/plans`. Últimos 3 días del trial: el banner cambia a color ámbar (`KriptonTheme.amber`).
3. **Al expirar el trial:** en el primer arranque en que `!isInTrial && trialEndsAt != null && subscription_tier == 'free'`, mostrar una vez (flag en `SharedPreferences`, clave `trial_expired_notice_shown`) un diálogo de pérdida: `l10n.trialExpiredTitle` / `l10n.trialExpiredBody` con CTA a `/plans`. Esto es loss aversion deliberada: el usuario ya usó 30 días de caducidad y links ilimitados.
4. **Onboarding:** la diapositiva 1 o una nueva tarjeta en la pantalla de registro comunica el trial: `l10n.trialPromo` ("14 días de Premium gratis. Sin tarjeta.").

---

## 8. Migración de base de datos consolidada

Crear **`supabase/migrations/20260907000000_mvp_realignment.sql`** con, en este orden:

1. `ALTER TABLE public.users`: nuevo CHECK de `subscription_tier` (`free`, `premium`, `business`, `enterprise`); `max_file_size_bytes` default `20971520`; `ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ`; trigger `trg_users_trial`; `DROP COLUMN IF EXISTS max_storage_premium_bytes` (tras migrar cualquier valor necesario a `max_storage_bytes`).
2. `UPDATE public.users SET max_file_size_bytes = 20971520 WHERE subscription_tier = 'free';`
3. `ALTER TABLE public.files DROP COLUMN IF EXISTS viewer_object_key, DROP COLUMN IF EXISTS viewer_file_size_bytes, DROP COLUMN IF EXISTS conversion_status;` (+ `DROP INDEX IF EXISTS idx_files_viewer_object_key;`)
4. Eliminación del VDR por carpetas (§4.4): `folders`, `share_links.folder_id`, `link_type`, constraints, índices y políticas asociadas; `files.folder_id` si existe.
5. `CREATE OR REPLACE` de `get_shared_file_metadata()` y `get_received_files()` **sin** las columnas de preview.
6. `CREATE OR REPLACE` de `check_upload_limits()` y `validate_share_link_expiration()` con el tier efectivo (trial incluido, §7.1) y los nuevos topes (20 MB y 168 h free; 100 MB, 30 días y 1 GB premium; 200 MB, 60 días y 5 GB business; verificación de storage por links activos, §5.3).
7. Nueva tabla de métricas de funnel (§11.1).
8. Ampliar el CHECK de `telemetry_events.event_type` solo si se decide registrar eventos de paywall ahí; **preferir la tabla `funnel_events`** (§11.1) para no mezclar dominios.

Aplicar con el flujo habitual del proyecto (`supabase/migrations/` + verificación post-deploy de que las RPCs desplegadas coinciden con las del repositorio — recordar que históricamente hubo RPCs no versionadas).

---

## 9. Código de referencia — vista de progreso sin anuncios

En `upload_screen.dart`, sustituir `_buildProcessingAdOverlay()` por:

```dart
// === VISTA DE PROCESAMIENTO (sin publicidad) ===
Widget _buildProcessingView() {
  final l10n = AppLocalizations.of(context);
  return Scaffold(
    backgroundColor: KriptonTheme.charcoalBlack,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: KriptonTheme.electricLime)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms),
            const SizedBox(height: 12),
            Text(
              l10n.protectingFiles,
              style: const TextStyle(
                color: KriptonTheme.platinum,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: KriptonTheme.inkDeep,
              valueColor: const AlwaysStoppedAnimation(KriptonTheme.electricLime),
            ),
            const SizedBox(height: 10),
            Text(
              _isEncrypting ? l10n.encryptingAesStep : l10n.syncingR2Step,
              style: const TextStyle(
                color: KriptonTheme.cyanTelemetry,
                fontFamily: 'SFMono',
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

Y en `build()`: `if (_isEncrypting || _isUploading) return _buildProcessingView();`

---

## 10. Cambio 8 — Paywalls contextuales

**Principio:** el paywall aparece en el momento exacto de la fricción (cuando el usuario choca con un límite), no como banner permanente. Cada paywall registra su trigger en `funnel_events` (§11).

### 10.1 Nuevo widget `lib/features/subscription/presentation/widgets/paywall_sheet.dart`

Bottom sheet modal reutilizable:

```dart
enum PaywallTrigger {
  fileSizeLimit,     // archivo > 20 MB en free
  activeLinksLimit,  // 3 links activos alcanzados
  monthlyQuotaLimit, // 20 links/mes alcanzados
  durationLimit,     // quiere más de 7 días en free
  storageLimit,      // cuota de storage llena (1 GB premium/trial, 5 GB business)
  trialExpired,      // trial terminado
  generic,           // entrada desde /plans o perfil
}
```

API: `PaywallSheet.show(context, trigger: PaywallTrigger.fileSizeLimit)`. Contenido: título y cuerpo según trigger (claves ARB `paywallFileSizeTitle`, `paywallFileSizeBody`, etc.), beneficios del plan, CTA "Ver planes" → `/plans`, y botón secundario "Ahora no". Al mostrarse llama a `FunnelMetricsService.logPaywallShown(trigger)`; al CTA, `logPaywallCta(trigger)`; al cerrarse sin acción, `logPaywallDismissed(trigger)`.

### 10.2 Puntos de activación (todos obligatorios)

| Trigger | Dónde | Condición |
| --- | --- | --- |
| `fileSizeLimit` | `upload_screen.dart` `_pickFile()` | Archivo > `freeMaxFileSizeBytes` y usuario free: en lugar de solo mostrar error, mostrar paywall con "Premium permite 100 MB" |
| `activeLinksLimit` | `file_provider.dart` `canUpload()` → propagar código de error | La RPC devuelve "3 enlaces activos"; la UI muestra paywall |
| `monthlyQuotaLimit` | ídem | La RPC devuelve "20 enlaces mensuales"; la UI muestra paywall |
| `durationLimit` | `upload_screen.dart` slider | Usuario free arrastra el slider: fijar tope en 168 h y, al llegar al tope por primera vez por sesión, tooltip/paywall suave "Premium: hasta 30 días" |
| `storageLimit` | `plans_screen.dart` / error de `check_upload_limits` por storage | Paywall con sugerencia de liberar espacio (eliminar links activos) |
| `trialExpired` | Diálogo de §7.2.3 | CTA directo a `/plans` |

**Caso especial Business:** `storageLimit` en un usuario Business no puede ofrecer upgrade (ya es el plan tope): el sheet muestra únicamente la acción de liberar espacio (eliminar o expirar links activos) y **no** el CTA "Ver planes". Lo mismo aplica si un usuario Business supera los 200 MB por archivo: mensaje de error plano (`paywallFileSizeTitle` + cuerpo sin upgrade), no paywall de venta.

Para distinguir los motivos de rechazo de `canUpload()`, la RPC `check_upload_limits()` devuelve además una columna `reason_code TEXT` con valores contractuales: `file_size`, `monthly_quota`, `active_links`, `storage`. Actualizar la migración §8 y el cliente (`file_provider.dart`) para propagar ese código hasta la UI (lanzar una `QuotaExceededException(reasonCode)` tipada en lugar de `Exception(message)`).

---

## 11. Cambio 9 — Métricas de activación y conversión (día 1)

### 11.1 Nueva tabla (migración §8)

```sql
CREATE TABLE IF NOT EXISTS public.funnel_events (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'signup_completed',
        'first_link_created',      -- ACTIVACIÓN
        'first_recipient_view',    -- AHA (primer view de un destinatario en un link del usuario)
        'paywall_shown',
        'paywall_cta_clicked',
        'paywall_dismissed',
        'checkout_started',
        'purchase_completed',
        'trial_started',
        'trial_expired'
    )),
    trigger TEXT,                  -- PaywallTrigger cuando aplique
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.funnel_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY funnel_events_insert_own ON public.funnel_events
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY funnel_events_select_own ON public.funnel_events
    FOR SELECT USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_funnel_events_type_time
  ON public.funnel_events(event_type, created_at);
```

> `first_recipient_view` se inserta desde el **visor del receptor** con el `owner_id` del archivo (disponible en `get_shared_file_metadata`). Para permitirlo sin exponer escritura libre sobre filas ajenas, crear una RPC `log_first_recipient_view(p_link_id UUID)` SECURITY DEFINER que: valide el link activo, obtenga `owner_id`, e inserte el evento solo si el owner aún no tiene uno (`INSERT ... SELECT ... WHERE NOT EXISTS`).

### 11.2 Nuevo servicio `lib/core/services/funnel_metrics_service.dart`

```dart
class FunnelMetricsService {
  // logEvent(FunnelEventType type, {String? trigger, Map<String, dynamic>? metadata})
  // logPaywallShown / logPaywallCta / logPaywallDismissed (wrappers con trigger)
  // Todos best-effort: jamás bloquean ni rompen la UI (try/catch silencioso).
}
```

### 11.3 Puntos de instrumentación

| Evento | Punto del código |
| --- | --- |
| `signup_completed` | `auth_provider.dart` `signUp()` tras insertar `public.users` |
| `trial_started` | mismo lugar (el trigger fija `trial_ends_at`) |
| `first_link_created` | `file_provider.dart` `uploadAndCreateLink()` tras el insert en `share_links`, solo si `user.monthlyLinksGenerated == 0` antes del incremento |
| `first_recipient_view` | `viewer_screen.dart` tras el primer `download_complete` exitoso (vía RPC §11.1) |
| `paywall_shown` / `paywall_cta_clicked` / `paywall_dismissed` | `paywall_sheet.dart` |
| `checkout_started` | `plans_screen.dart` al invocar `purchasePackage` |
| `purchase_completed` | `subscription_notifier.dart` tras compra exitosa (mock y real) |
| `trial_expired` | Al mostrar el diálogo de §7.2.3 |

### 11.4 Consultas de análisis (documentar en el README de analytics)

- **Conversión por trigger:** `SELECT trigger, count(*) FILTER (WHERE event_type='paywall_shown') AS shown, count(*) FILTER (WHERE event_type='purchase_completed') AS converted FROM funnel_events GROUP BY trigger;`
- **Activación:** % de `signup_completed` con `first_link_created` en ≤24 h.
- **Aha:** % de usuarios activados con `first_recipient_view` en ≤72 h (mide si la caducidad de 7 días protege el momento aha).

---

## 12. Cambio 3 — Internacionalización completa (5 idiomas)

**Regla:** ningún texto visible al usuario puede estar hardcodeado en Dart ni faltar en ninguno de los 5 ARB (`es`, `en`, `pt`, `fr`, `de`).

### 12.1 Claves ARB a ELIMINAR (de los 5 archivos + regenerar localizations)

`adSampleTitle`, `adSampleBody`, `adSampleCta`, `upsellTitle`, `upsellCta`, `msOfficeWarningTitle`, `msOfficeWarningBody`, `pdfPreviewGeneratedNotice`, `generatingPreviewStep`, `previewGenerationFailedNotice`, `conversionPreviewFailed`, y todas las claves del Data Room por carpetas: `dataRoomExplorerTitle`, `premiumCapacityLabel`, `storageUsedSummary`, `expandVaultAddon`, `newVirtualFolder`, `batchUploadAction`, `batchUploadHint`, `virtualFoldersSection`, `unfiledFilesSection`, `folderCardSummary`, `linkStatusActiveExpires`, `emptyDataRoomTitle`, `emptyDataRoomHint`, `folderNameLabel`, `folderDescriptionLabel`, `createFolder`, `folderCreated`, `batchUploadTitle`, `batchProgressSummary`, `batchCompletedMessage`, `batchFileSkippedTooLarge`, `selectDestinationFolder`, `filesSelected`, `dataRoomLobbyTitle`, `shareFullFolder`, `shareSheetTitle` (se conserva `shareSingleFile` si se reutiliza), `eventLobbyEnter`, `eventFileOpen`, `eventLobbyExit`, `expandDataRoomAddon`, `noAddonsAvailable`, `storageExpanded`, `dataRoomCapacity`, `storageManagementTitle` (sustituida por `plansTitle`), `enterDataRoomPassword`, `dataRoomNotFound`, `dataRoomPasswordLabel`, `selectFileToDecrypt`, `encryptedFilesCount`, `availableDocumentsSection`, `openAndDecryptInRam`, `ramDecryptionNotice`, `officeDocsNotViewable`.

> Tras eliminar claves, ejecutar `flutter gen-l10n` (o `flutter pub get` con `generate: true`) y corregir todos los errores de compilación por claves referenciadas ya inexistentes: es la verificación automática de que no quedan residuos.

### 12.2 Claves ARB NUEVAS (crear en los 5 idiomas; se muestra el español contractual)

```jsonc
{
  "unsupportedFormatTitle": "Formato no soportado",
  "unsupportedFormatBody": "Por seguridad KRIPTONSHARE solo acepta archivos de los formatos: {formats}. Convierte tu documento a PDF antes de compartirlo.",
  "unsupportedViewerBody": "Este formato no puede visualizarse de forma segura dentro de la app. Formatos aceptados: {formats}.",
  "plansTitle": "Planes y almacenamiento",
  "trialBanner": "Prueba Premium: te quedan {days} días",
  "trialPromo": "14 días de Premium gratis. Sin tarjeta.",
  "trialExpiredTitle": "Tu prueba Premium terminó",
  "trialExpiredBody": "Vuelves al plan gratuito: 20 MB por archivo, 20 links al mes y caducidad de 7 días. Conserva 100 MB, links ilimitados y 30 días con Premium.",
  "premiumBenefits": "100 MB por archivo · links ilimitados · hasta 30 días · 1 GB de almacenamiento efímero · marca de agua dinámica",
  "businessBenefits": "200 MB por archivo · 5 GB totales · links de hasta 60 días · todo lo de Premium · prioridad de soporte · marca personalizada en el visor (próximamente)",
  "premiumPriceMonthly": "$12.99 / mes",
  "premiumPriceAnnual": "$103.99 / año",
  "premiumAnnualSavings": "4 meses gratis (33% de ahorro)",
  "businessPriceMonthly": "$29.99 / mes",
  "businessPriceAnnual": "$239.99 / año",
  "businessAnnualSavings": "Ahorra 33%",
  "paywallFileSizeTitle": "Archivo demasiado grande",
  "paywallFileSizeBody": "Tu plan permite {maxSize} por archivo. Con Premium sube hasta 100 MB.",
  "paywallActiveLinksTitle": "Límite de links activos",
  "paywallActiveLinksBody": "El plan gratuito permite 3 links activos a la vez. Con Premium son ilimitados.",
  "paywallMonthlyQuotaTitle": "Límite mensual alcanzado",
  "paywallMonthlyQuotaBody": "Has creado 20 links este mes. Con Premium son ilimitados.",
  "paywallDurationTitle": "Duración máxima del plan gratuito",
  "paywallDurationBody": "Los links gratuitos duran hasta 7 días. Con Premium, hasta 30 días.",
  "paywallStorageTitle": "Almacenamiento lleno",
  "paywallStorageBody": "Has usado tu {quota} de almacenamiento. Elimina links activos para liberar espacio o amplía tu plan.",
  "paywallStorageBodyBusiness": "Has usado tus 5 GB. Elimina o expira links activos para liberar espacio.",
  "paywallViewPlans": "Ver planes",
  "paywallNotNow": "Ahora no",
  "max7Days": "7 días (Máx)",
  "max60Days": "60 días (Máx)",
  "ephemeralStorageLabel": "Almacenamiento efímero total",
  "subscribeToBusiness": "Suscribirse a Business",
  "businessBadge": "BUSINESS",
  "businessPlanLabel": "Plan Business"
}
```

Traducir cada clave a `en`, `pt`, `fr`, `de` con el tono y registro ya usados en los ARB existentes (formal-profesional, tuteo en es, you en en, você en pt, tutoiement en fr, du en de). Los precios quedan como cadenas fijas en USD en los 5 idiomas.

### 12.3 Auditoría de hardcodeo

Ejecutar una búsqueda de literales de texto en `lib/` (`grep -rn "Text('[^']" lib/`) y migrar a ARB cualquier cadena visible residual (excepción: logs `debugPrint`, nombres técnicos y la marca `KRIPTONSHARE`). Los mensajes de error devueltos por las RPCs en español (`check_upload_limits`, `validate_share_link_expiration`) se mapean en el cliente a claves ARB usando el `reason_code` (§10.2) en lugar de mostrar el texto crudo del servidor.

---

## 13. Flujos completos resultantes (contratos de comportamiento)

### 13.1 Upload de un PDF (camino feliz, free)

1. Usuario (trial activo o free) elige `contrato.pdf` (8 MB) → formato soportado, tamaño OK.
2. Contraseña + slider (tope 168 h en free, 720 h en premium/trial, 1440 h en business) + email opcional.
3. Progreso: "Cifrando con AES-256" → "Sincronizando en R2". Sin anuncios, sin conversión.
4. Éxito: QR + compartir. Si era su primer link → `first_link_created`.

### 13.2 Intento de upload de un `.docx`

1. Usuario elige `informe.docx` → `UnsupportedFormatDialog` bloqueante con la lista de formatos y el consejo de convertir a PDF.
2. La selección se descarta; no se cifra ni se sube nada. No existe camino de upload para Office.

### 13.3 Usuario free que toca un límite

1. Sube un archivo de 35 MB → `check_upload_limits` devuelve `reason_code='file_size'` → paywall contextual `fileSizeLimit` → CTA a `/plans` (`paywall_cta_clicked` con trigger) → compra (`checkout_started`, `purchase_completed`).

### 13.4 Ciclo del trial

Registro → `trial_started` + 14 días de límites premium → banner con cuenta regresiva en Dashboard → día 15: diálogo `trialExpired` (una sola vez) → límites free aplicados en cliente y servidor.

---

## 14. Seguridad

- **Zero-knowledge vuelve a ser absoluto:** al eliminar el conversion-gateway, ningún contenido en texto plano sale del dispositivo del emisor. Restaurar el claim completo en README, onboarding y landing (ya no se requiere el matiz de la Fase 1).
- El bloqueo de formatos en origen (§3.4) **reduce** la superficie de ataque: ya no se aceptan binarios arbitrarios que el receptor pudiera verse tentado a abrir fuera de la app.
- El trial y los límites se validan en servidor (RPCs SECURITY DEFINER); el cliente nunca escribe `trial_ends_at`, `subscription_tier` (salvo el simulador debug) ni `max_file_size_bytes`.
- `funnel_events` no registra nombres de archivo, contenido ni contraseñas; solo eventos y triggers.
- Las credenciales R2 embebidas en `constants.dart` son un riesgo **preexistente** (fuera de alcance de este documento, pero registrar como deuda técnica prioritaria: mover la escritura R2 detrás de una Edge Function con URLs firmadas).

---

## 15. Plan de pruebas

### 15.1 Unitarias (`test/`)

- `supported_formats_test.dart`: acepta pdf/jpg/png/txt/csv/mp4 (por MIME y por extensión, case-insensitive); rechaza docx/xlsx/pptx/exe/zip; `application/octet-stream` se resuelve por extensión.
- `user_model_test.dart`: `effectiveTier` en los 5 casos (free, free+trial activo, free+trial expirado, premium, business/enterprise).
- Eliminar/actualizar los tests de la Fase 1 (`office_formats_test.dart`, `conversion_service_test.dart`, `kripton_file_test.dart` con campos de preview).
- Tests de `PaywallTrigger` → mapeo a claves ARB.

### 15.2 Integración / E2E (actualizar `E2E_TEST_GUIDE.md`)

1. Upload de PDF 8 MB (free con trial): límites premium aplican (slider hasta 30 días).
2. Upload de `.docx`: diálogo bloqueante, nada se sube.
3. Free sin trial: 4.º link activo → paywall `activeLinksLimit`; 21.º link del mes → paywall `monthlyQuotaLimit`; archivo 25 MB → paywall `fileSizeLimit`; slider tope en 7 días.
4. Trial expirado (forzar `trial_ends_at` en DB): diálogo una sola vez; límites free efectivos en servidor (verificar con cliente modificado que la RPC rechaza 30 días de caducidad).
5. Compra mock de Premium y de Business: tier y límites cambian; `purchase_completed` registrado. En Business: upload de 150 MB aceptado, slider hasta 60 días, la RPC acepta 60 días y rechaza 61, y la verificación de storage corta en 5 GB (el paywall `storageLimit` de Business no ofrece upgrade, solo liberar espacio).
6. Receptor abre link: `first_recipient_view` insertado una sola vez por owner.
7. Regresión: un link creado antes de la migración con archivo Office muestra la pantalla "formato no soportado" sin crash.
8. `flutter analyze` sin errores nuevos; `flutter test` en verde; `flutter gen-l10n` sin claves faltantes en ninguno de los 5 ARB (la compilación falla si falta alguna — es la verificación de i18n completo).

---

## 16. Checklist de implementación (orden de ejecución)

1. [ ] Migración `supabase/migrations/20260907000000_mvp_realignment.sql` (§5.3, §6.5, §7.1, §8, §11.1) y aplicarla; verificar RPCs desplegadas contra repo.
2. [ ] `pubspec.yaml`: eliminar `google_mobile_ads`; `flutter pub get` (§2).
3. [ ] Eliminar `infra/conversion/`, `lib/services/conversion_service.dart`, `lib/utils/office_formats.dart`, `ms_office_warning_dialog.dart`, `UPLOAD_AD_FLOW.md` (§2, §3.1).
4. [ ] Crear `lib/utils/supported_formats.dart` y `unsupported_format_dialog.dart` (§3.2, §3.3).
5. [ ] `file_provider.dart`: revertir Fase 1 + propagar `reason_code` de cuotas (§3.5, §10.2).
6. [ ] `kripton_file.dart`: eliminar campos de preview (§3.6).
7. [ ] `viewer_screen.dart`: revertir rama de preview; mensaje de formato no soportado (§3.7).
8. [ ] `upload_screen.dart`: bloqueo de formatos, vista de progreso sin anuncios, slider 168 h free, paywalls `fileSizeLimit`/`durationLimit` (§3.4, §5.2, §9, §10).
9. [ ] Eliminar `lib/features/data_room/` (moviendo planes a `lib/features/subscription/`), `data_room_card.dart`, rutas y referencias en dashboard/profile (§4).
10. [ ] `constants.dart`: nuevos límites, precios, tiers; eliminar constantes de conversión (§5.1).
11. [ ] `user_model.dart` + `auth_provider.dart`: `effectiveTier`, trial, `setTierSimulation` (§6.3, §7.2).
12. [ ] `purchase_service.dart`: 4 productos, sin add-ons (§6.2); actualizar `REVENUECAT_SETUP.md` (§6.4).
13. [ ] `plans_screen.dart`: dos planes, cuatro paquetes, banner de trial, gauge re-etiquetado (§6.4).
14. [ ] `paywall_sheet.dart` + integración de triggers (§10).
15. [ ] `funnel_metrics_service.dart` + instrumentación completa (§11).
16. [ ] ARB: eliminar claves obsoletas, crear claves nuevas en los 5 idiomas, `flutter gen-l10n`, auditoría de hardcodeo (§12).
17. [ ] Pruebas §15 y actualización de `E2E_TEST_GUIDE.md`.
18. [ ] `README.md`: zero-knowledge absoluto restaurado, formatos soportados, planes y precios, sin Docker/Gotenberg/anuncios (§3.10, §14).
19. [ ] Logo primario en la pantalla de inicio (y login/registro si aplica): asset `assets/branding/`, sustitución del placeholder "K" (§18).

**Criterios de aceptación:** no queda ninguna referencia a Gotenberg, Docker, conversión, AdMob ni carpetas virtuales en el código ni en la documentación; un `.docx` no puede subirse y muestra el aviso con la lista de formatos; los límites free (20 MB / 20 al mes / 3 activos / 7 días), premium (100 MB / ilimitados / 30 días / 1 GB) y business (200 MB / ilimitados / 60 días / 5 GB) se aplican en cliente y servidor; todo usuario nuevo tiene 14 días de Premium sin tarjeta; los 6 triggers de paywall muestran el sheet y registran métricas; la app compila con las 5 localizaciones completas y no contiene publicidad; la pantalla de inicio muestra el logo primario oficial en lugar del cuadro verde con "K".

---

## 17. Riesgos y notas

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| Links antiguos con archivos Office en R2 (pre-migración) | Bajo | La rama "formato protegido" del visor cubre el caso con el nuevo mensaje (§3.7) |
| RPCs no versionadas en la DB de producción | Medio | Post-deploy: verificar que `check_upload_limits`, `get_shared_file_metadata`, `get_received_files` y `validate_share_link_expiration` coinciden con la migración §8 |
| Usuarios premium legacy a $19/$189 | Bajo | Grandfathering: conservan su producto y precio; los nuevos productos usan los IDs de §6.1 |
| Rechazo de formatos percibido como limitación | Bajo | El diálogo incluye el consejo accionable (convertir a PDF) y la lista explícita de formatos |
| Crecimiento del costo R2 por links de 7 días en free | Bajo | 20 MB × 3 links activos máx. por usuario free; la lifecycle rule de 72 h post-expiración sigue vigente |

---

## 18. Cambio 10 — Logo primario en la pantalla de inicio de la app

**Objetivo:** la pantalla de inicio de la app (splash y, si aplica, onboarding/login) debe mostrar el **logo primario oficial** de la marca (símbolo escudo-K + wordmark KRIPTONSHARE + tagline) en lugar del cuadro verde con la letra "K" que se usa hoy como placeholder. El ícono de la aplicación (`KRIPTONSHARE_App_Icon.png`, ya configurado en Android/iOS) **no se toca**.

### 18.1 Asset

1. Copiar el archivo oficial `KRIPTONSHARE_Logo_Primary.png` a `assets/branding/kriptonshare_logo_primary.png` (el asset oficial vive en el repositorio de marca del proyecto; si no está versionado, agrégalo con este commit).
2. Declarar el directorio en `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/branding/
```

### 18.2 Localizar y sustituir el placeholder

Buscar el widget actual del inicio (contenedor verde con la letra "K"): típicamente en las pantallas de splash/onboarding/login; pistas de búsqueda: `grep -rn "'K'" lib/`, `grep -rn "kryptonGreen" lib/` en widgets de cabecera, o un `Container`/`BoxDecoration` verde con un `Text('K')` centrado. Reemplazar ese widget por:

```dart
Center(
  child: Image.asset(
    'assets/branding/kriptonshare_logo_primary.png',
    height: 160,
    fit: BoxFit.contain,
  ),
)
```

- El fondo de la pantalla se mantiene `charcoalBlack` (#0A0A0F): el PNG oficial trae fondo oscuro integrado que se funde con el fondo de la app; si se dispone de la versión con fondo transparente, usarla preferentemente con el mismo nombre de archivo.
- Aplicar el mismo reemplazo en cualquier otra pantalla de autenticación que repita el placeholder (login/registro), con altura menor (p. ej. 96–120) si el espacio es reducido.
- No eliminar el nombre de la app ni textos de i18n asociados; este cambio es solo gráfico.

### 18.3 Identidad de marca de referencia (para futuros ajustes visuales)

Según el sistema de identidad oficial: Muted Krypton Green `#4E9B47` (marca), Electric Lime `#39FF14` (acento/CTA), Charcoal Black `#121212` (fondo), Ink `#2B2B2B` (fondo secundario), Light Gray `#E0E0E0` (texto/iconos); Tiempos para titulares/editorial e Inter para UI/cuerpo. Los colores de `lib/utils/theme.dart` ya coinciden con esta paleta; no se requieren cambios de tema en esta iteración.