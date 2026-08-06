# KRIPTONSHARE — Memoria de sesión

## 2026-08-02

### Tarea
Implementar la arquitectura i18n/l10n v2.1 en 5 idiomas (es/en/fr/de/pt) según `KRIPTONSHARE_Plan_Arquitectura_i18n_l10n_v2.md`.

### Cambios realizados
1. **Configuración base**: `flutter_localizations`, `l10n.yaml`, 5 archivos ARB (~190 claves) y claves adicionales para badges/preview/access audit.
2. **Core localization**: `LocaleNotifier` con SharedPreferences + reconciliación remota, formatters locale-aware, selector modal y `UiErrorCode`.
3. **Integración global**: `main.dart` y `auth_provider.dart` conectados a la arquitectura de localización.
4. **Pantallas refactorizadas**: Splash, Auth, Dashboard, Profile, Onboarding, Biometric lock/settings, Viewer, Upload, Links, Expired links, Link card/gauge, Data Room card/lobby/storage, Analytics, VDR widgets y video player.
4.1 **Limpieza de literales en español en servicios/repositorios**: auth, file provider, conversion, biometric, upload repository, folder/data_room repositories.
5. **Notifiers tipificados**: `DataRoomNotifier` usa `UiErrorCode?` en vez de `String`.
6. **Base de datos**: migración idempotente `20260728000000_add_preferred_language.sql`.
7. **Tests**: `test/core/localization/locale_provider_test.dart`.
8. **Documentación**: sección i18n en `E2E_TEST_GUIDE.md`.

### Configuraciones dejadas pendientes
- RevenueCat ↔ Supabase billing sync.
- Google Play Console / App Links verificados.

### Resultado final del día (noche)
- **`flutter analyze`: No issues found** (63 → 0).
- **`flutter test`: 71/71 verdes**.
- Lección clave: con `nullable-getter: false` en `l10n.yaml`, `AppLocalizations.of()` nunca devuelve null → el `!` es siempre innecesario. No reintroducirlo.


## 2026-07-29

### Tarea
Aplicar la actualización de arquitectura del Virtual Data Room (VDR) para usuarios Premium de KRIPTONSHARE según `KRIPTONSHARE Actualización Arquitectura Virtual Data Room 29Jul26.md`, e integrar tests + guía E2E.

### Fases implementadas
1. **Migración SQL y Edge Function**
   - `supabase/migrations/20260729000000_vdr_architecture_update.sql`: tablas `data_rooms`, `folders`, `files`, `share_links`, `journey_telemetry`, columnas Premium, políticas RLS, triggers y funciones RPC.
   - `supabase/functions/billing-sync/index.ts`: Edge Function para sincronizar eventos de RevenueCat y actualizar `max_storage_bytes`/`is_premium`.
2. **Core cliente**
   - Constantes VDR, tema corporativo, utilidades crypto/network y datasource R2.
3. **Dominio y datos**
   - Entidades `DataRoomEntity`, `FolderEntity`, `FileEntity`, `ShareLinkEntity`, `JourneyTelemetryEntity`.
   - Legacy aislado en `legacy_file_entity.dart`.
   - Modelos, datasources, repositorios y use cases.
4. **Notifiers**
   - Lazy decryption, batch upload y explorer.
5. **UI/UX**
   - Pantallas explorer/lobby/storage, widgets Atomic Design, watermark dinámico, layout seguro.
6. **Enrutamiento e integración**
   - Rutas `/data-room`, `/f/:id` y `/d/:id`.
7. **Tests y guía E2E**
   - Tests unitarios VDR y actualización de `E2E_TEST_GUIDE.md`.

### Decisiones clave
- Entidades legacy aisladas para no romper el repositorio histórico; nuevas entidades usan nombres exactos del documento.
- Políticas RLS públicas para lectura a través de enlaces activos.
- Contraseña de compartir e IP del receptor son placeholders por ahora.

### Verificación pendiente
- `flutter analyze` y `flutter test` deben correrse en el entorno del usuario; no se ejecutaron desde este agente por limitaciones de Windows/PowerShell 5.1 con `&&`.

### Acciones pendientes del usuario
1. Aplicar migración SQL en Supabase.
2. Desplegar Edge Function `billing-sync`.
3. Configurar webhook de RevenueCat.
4. Ejecutar `flutter pub get`, `flutter analyze`, `flutter test` y build de prueba.
5. Seguir sección VDR de `E2E_TEST_GUIDE.md`.

## 2026-07-26

### Tarea
Corregir el overload conflictivo de `check_upload_limits` en Supabase que causaba `PGRST203`.

### Causa
Existían dos funciones `public.check_upload_limits`:
- `public.check_upload_limits(p_user_id => uuid, p_file_size => integer)` — usada por el cliente (`lib/providers/file_provider.dart:139`).
- `public.check_upload_limits(p_user_id => uuid, p_file_size => integer, p_is_folder_upload => boolean)` — residual de migraciones anteriores.
PostgREST no podía resolver la llamada con dos parámetros nombrados.

### Cambios realizados
- `supabase/migrations/20260726000000_unify_check_upload_limits.sql`:
  - Asegura columnas `total_storage_used_bytes`, `max_storage_premium_bytes`, `max_storage_bytes` en `users`.
  - Alinea `max_links_monthly` a `20`.
  - Elimina el overload de 3 parámetros.
  - Recrea `check_upload_limits(UUID, INTEGER)` con lógica multi-tier completa.
- `supabase/schema.sql`, `supabase/schema_migration_fix.sql`: actualizados al estado final.
- `supabase/migrations/20260725000000_premium_dataroom.sql`: reemplazada función de 3 parámetros por la de 2.
- `supabase/migrations/20260712000000_must_have_and_premium.sql`: usa `COALESCE(max_storage_bytes, max_storage_premium_bytes, 2147483648)`.

### Resultado
- SQL ejecutado sin errores.
- `flutter run` inició limpio.
- No apareció `PGRST203` ni `[canUpload] RPC error...` en los logs.
- Login como `receptor@kriptonshare.test` funciona; `getReceivedFiles` devolvió 5 archivos.
- Falta confirmar `check_upload_limits` intentando una subida real.

### Pendientes relacionados
- Desplegar gateway `infra/conversion/` para que funcione la vista previa PDF de Office.
- Corregir `RenderFlex overflowed by 7.8 pixels` en `lib/screens/viewer/viewer_screen.dart:311`.

## 2026-07-25

### Tarea
Implementar Fase 1: Vista Previa Segura de Documentos Microsoft Office (`.docx`, `.xlsx`, `.pptx`, etc.) según `KRIPTONSHARE_Fase1_Vista_Previa_Office_Especificacion.md`.

### Cambios realizados
- Migración SQL `supabase/migrations/20260801000000_office_pdf_preview.sql` con columnas `viewer_*` y `conversion_status`, y RPCs actualizadas.
- Infraestructura de conversión `infra/conversion/`: Docker Compose con Gotenberg + gateway Deno propio (JWT, límites por plan, rate-limit, sin logs de contenido).
- Utilidades y servicios Flutter: `OfficeFormats`, `ConversionService`, constantes de conversión.
- Modelo `KriptonFile` con campos de preview y `hasPdfPreview`.
- `FileService`: conversión en upload, doble objeto R2, `useViewerObject`, borrado doble, limpieza best-effort.
- `ViewerScreen`: rama de preview Office con `pdfrx`, watermark dinámico con email + fecha.
- Paridad en capa Clean Architecture de upload: repositorio y notifier actualizados.
- UI de upload: chip informativo, estado "Generando vista previa segura…", aviso de fallback.
- Tests unitarios para `office_formats`, `conversion_service`, `kripton_file` y nuevo test crypto de payloads distintos con misma contraseña.
- README y E2E_TEST_GUIDE actualizados.

### Pendiente
- ✅ Migración SQL aplicada con éxito en Supabase tras corregir error `42P13` con `DROP FUNCTION IF EXISTS`.
- `flutter analyze` ejecutado; se corrigieron errores/warnings en `upload_repository_impl.dart`, `file_provider.dart` y `conversion_service_test.dart`.
- Ejecutar `flutter analyze` y `flutter test` nuevamente para confirmar.
- Desplegar gateway de conversión.
- Validar E2E con documentos Office reales.

## 2026-07-24

### Tarea
1. Optimizar cifrado/subida moviéndolo a un Isolate para archivos grandes (video).
2. Eliminar recuadros de enlaces expirados del Dashboard.
3. Agregar pantalla aparte de enlaces expirados accesible desde Analytics.

### Cambios realizados
- `lib/services/crypto_service.dart`: función top-level `encryptFileInIsolate()` para ejecutar AES-256-GCM + PBKDF2 fuera del hilo de UI.
- `lib/providers/file_provider.dart` y `lib/features/upload/data/repositories/upload_repository_impl.dart`: cifrado movido a `Isolate.run()` en ambos flujos de subida.
- `lib/screens/dashboard/dashboard_screen.dart`: filtro `isActive && !expired` en "Enlaces activos".
- `lib/features/links/presentation/screens/expired_links_screen.dart`: lista básica de enlaces expirados (nombre, tamaño, fecha).
- `lib/providers/file_provider.dart`: `ExpiredLinkItem`, `expiredLinksProvider` y `getExpiredLinksWithMetadata()`.
- `lib/providers/router_provider.dart`: ruta `/expired-links`.
- `lib/features/analytics/presentation/screens/analytics_dashboard_screen.dart`: botón "Ver enlaces expirados" al final.
- `pubspec.yaml`: agregada `flutter_secure_storage: ^9.2.2`.
- `lib/services/secure_credential_service.dart`: ajustado a API de `flutter_secure_storage` v8 y cambiado `const` a `final`.
- `lib/features/data_room/presentation/screens/data_room_lobby_screen.dart`: llaves en `if` de `_iconForMime`.
- `lib/features/data_room/presentation/screens/storage_management_screen.dart`: `mounted` check separado antes de usar `BuildContext`.
- `lib/providers/file_provider.dart`: cast innecesario eliminado.
- `lib/widgets/video_player_screen.dart`: llaves innecesarias eliminadas en string interpolation.
- `lib/screens/biometric/biometric_lock_screen.dart`: agregado import de `secure_credential_service.dart`.
- `android/app/build.gradle.kts`: `compileSdk` fijado a 36 para `flutter_secure_storage`.
- `lib/providers/auth_provider.dart`: fallback en `signIn` para crear registro en `public.users` si falta.
- `lib/providers/file_provider.dart`: fallback de `getReceivedFiles` filtra por `recipient_email ilike user.email`.

### Pendiente
- Ejecutar `flutter pub get`, `flutter analyze` y `flutter run` en el entorno del usuario.
- Validar subida de video grande sin congelamiento de UI.

## 2026-07-23

### Problema
El receptor no ve archivos recibidos en el Dashboard aunque el link no haya caducado.

### Causas
- `get_received_files()` no estaba en `schema.sql` ni en `schema_migration_fix.sql`; solo en `test_e2e_setup.sql`.
- La comparación `recipient_email = auth.email()` era case-sensitive.
- Faltaban políticas RLS que permitan al receptor leer `share_links` y `files`.

### Cambios
- Función `get_received_files()` case-insensitive agregada a `schema.sql` y `schema_migration_fix.sql`.
- Políticas `link_recipient_access` y `file_recipient_access` agregadas a los tres archivos SQL.
- `lib/providers/file_provider.dart`: logs de diagnóstico y fallback directo a tablas si la RPC falla.

### Acción pendiente del usuario
Aplicar `supabase/schema_migration_fix.sql` en Supabase SQL Editor y recompilar/probar en Android.

### Soporte de imágenes y Office (2026-07-23)
- Imágenes: sí, se visualizan dentro de la app.
- Office (Word/Excel/PowerPoint): no; el visor muestra "Formato protegido" y recomienda convertir a PDF.
- Seguridad reforzada: se eliminaron los botones de "Abrir con otra aplicación" para PDF y se bloqueó el menú contextual de guardar en imágenes.

### Módulo Premium y Data Room (2026-07-23)
- Migración SQL `20260725000000_premium_dataroom.sql` con tablas `folders`, `journey_telemetry`, columnas de storage y RLS.
- Edge Function `revenuecat-webhook` para sincronizar compras con `max_storage_bytes`.
- Servicio `RevenueCatServiceImpl`, pantallas `StorageManagementScreen` y `DataRoomLobbyScreen`.
- Lazy Decryption en `FolderNotifier` y método `decryptFileBytes` en `CryptoService`.
- Rutas `/storage-management` y `/folder-room/:folderLinkId` agregadas al router.
- FLAG_SECURE ahora es global para toda la app.
- Modo prueba Premium (debug) activable desde StorageManagementScreen sin RevenueCat.
- Corrección: eliminado `dispose()` de `PdfViewerController` por incompatibilidad con `pdfrx ^1.3.5`.
- Soporte de video: `video_player` + `SecureVideoPlayerScreen`; reproducir MP4 y formatos comunes dentro de la app.
- Timeouts de Dio aumentados para descargas de archivos grandes.
- Pendiente: configuración de RevenueCat (API keys, productos, webhook) y pruebas E2E.

## 2026-07-11

### Tarea
Integrar Sprint 5 MVP (Must Have) + Plan Premium con bóveda acumulada de 2 GB, validación autoritativa en PostgreSQL y componentes UI no invasivos.

### Decisiones clave
- Validación de límites se centraliza en Supabase mediante RPC `check_upload_limits` para evitar evasión desde clientes modificados.
- Plan Premium: 100 MB/archivo, 2 GB de bóveda acumulada, 30 días de expiración máxima.
- Plan Free: 10 MB/archivo, 20 links/mes, 3 links activos concurrentes, 48 h máximas.
- Se alinean usuarios Free existentes a `max_links_monthly = 20`.
- Se agregan columnas `total_storage_used_bytes` y `max_storage_premium_bytes` a `public.users` con trigger automático de recálculo.
- Se mantiene el esqueleto visual actual; los cambios en UploadScreen son inyecciones quirúrgicas (panel dual, slider adaptativo, share sheet mejorado).
- Onboarding se implementa con `SharedPreferences` local y aparece una sola vez tras el primer login.

### Cambios realizados
- `supabase/migrations/20260712000000_must_have_and_premium.sql`: migración con columnas Premium, trigger de storage y función RPC `check_upload_limits` multi-tier.
- `pubspec.yaml`: agregada dependencia `shared_preferences`.
- `lib/utils/constants.dart` y `lib/core/utils/constants.dart`: sincronizados con constantes Free/Premium y aliases de compatibilidad.
- `lib/models/user_model.dart`: parseo de `total_storage_used_bytes`/`max_storage_premium_bytes`, getters `maxFileSizeBytes`, `maxDurationHours`, `remainingPremiumStorageBytes`; corrección de `linksRemaining` y `canCreateLink` para usar `AppConstants.maxLinksPerMonth`.
- `lib/providers/auth_provider.dart`: inicialización de nuevas columnas en signUp.
- `lib/providers/file_provider.dart`: `canUpload` ahora invoca RPC `check_upload_limits` y tiene fallback cliente multi-tier.
- `lib/features/upload/presentation/screens/upload_screen.dart`:
  - Panel dual: seleccionar archivo + Cámara a Vault.
  - `_captureSecurePhoto()` con `ImagePicker`, sin pasar por galería pública.
  - `_pickFile()` adaptado por tier (10 MB / 100 MB).
  - Slider adaptativo: Free 1–48 h, Premium 1–720 h con badge y etiquetas en días.
  - `_shareLinkToExternal()` con mensaje corporativo Zero-Knowledge.
- `lib/screens/onboarding_screen.dart`: pantalla de 3 slides con `PageController` y persistencia en `SharedPreferences`.
- `lib/providers/router_provider.dart`: ruta `/onboarding` y redirect post-auth condicionado a la flag local.

### Pendiente
- Ejecutar `flutter pub get`, `flutter analyze` y `flutter build apk --debug` en el entorno Windows del usuario.
- Aplicar migración SQL en Supabase.
- Validar flujos E2E: Free/Premium, Cámara, Share Sheet y Onboarding.

## 2026-06-27

### Interacción
- Usuario preguntó cómo ejecutar KRIPTONSHARE en VS Code después de `flutter pub get` y `flutter analyze`.
- Se identificó que el siguiente paso es `flutter run` (o F5 en VS Code), pero solo después de configurar credenciales reales de Cloudflare R2 en `lib/utils/constants.dart` (actualmente placeholders).
- Se le ofrecieron dos opciones: pasar credenciales vía `--dart-define` (recomendado) o editar `constants.dart`.
- El usuario reportó un warning de `flutter analyze`: import innecesario de `dart:typed_data` en `lib/providers/file_provider.dart`.
- Se eliminó el import `dart:typed_data` de `lib/providers/file_provider.dart` porque `package:flutter/foundation.dart` ya exporta `Uint8List`.
- El usuario ejecutó `flutter run` en un dispositivo Android físico. La app corrió, se conectó a Supabase y a Cloudflare R2 (test de conexión HTTP 200 y upload iniciado con payload de 106 KB).
- Se detectaron errores de renderizado en los logs:
  1. Crash en `lib/widgets/link_gauge.dart`: `Gradient.sweep` fallaba con `Failed assertion` cuando `percentage` era 0 (startAngle == endAngle).
  2. Overflows en `lib/features/upload/presentation/screens/upload_screen.dart`: Row del slider (línea 140) y Columnas del overlay de procesamiento (líneas 234 y 269).
- El usuario reportó error `DioException[bad response]` con status code `411` al subir archivo a R2. Esto ocurre porque S3/R2 requiere la cabecera `Content-Length`, que no se enviaba al usar un `Stream` como `data` en Dio.
- El usuario reportó error `PostgrestException` con código `23502`: `null value in column 'encryption_salt' of relation 'files' violates not-null constraint`. La tabla `files` en Supabase tenía una columna `encryption_salt` NOT NULL que no estaba en el schema local ni en el insert de Dart.

### Cambios realizados
- `lib/widgets/link_gauge.dart`: se agregó `safePercentage` clamp entre 0 y 1 y se envuelve el dibujo del arco en `if (arcAngle > 0.001)` para evitar crear un `SweepGradient` con ángulos inválidos.
- `lib/features/upload/presentation/screens/upload_screen.dart`:
  - Slider: el texto "Expiración del Data Room:" se acortó a "Expiración:" y se envolvió en `Expanded`; el badge pasó de "X Horas" a "Xh".
  - Overlay de procesamiento: se redujeron tamaños de iconos, fuentes y espacios; se añadió `SingleChildScrollView` + `ConstrainedBox` + `IntrinsicHeight` para evitar overflow cuando el teclado o insets reducen la altura disponible; se hicieron más compactos los textos del anuncio B2B y el upsell.
  - Post-`flutter analyze`: se agregó `const` a `EdgeInsets.all(24)` en el padding del overlay (línea 198).
- `lib/screens/auth/auth_screen.dart`: se agregó verificación `mounted` antes de cada `setState` dentro de los bloques `catch` y `finally` de `_login()` y `_register()`. Esto evita el error `setState() called after dispose()` que ocurría cuando el login/registro era exitoso y `context.go()` navegaba a otra pantalla antes de que el `finally` ejecutara `setState(() => _isLoading = false)`.
- Corrección `PostgrestException` código `23502` (`encryption_salt` NOT NULL):
  - `lib/providers/file_provider.dart`: se agregó `'encryption_salt': encrypted['salt']` al insert de la tabla `files`.
  - `supabase/schema.sql`: se agregó la columna `encryption_salt BYTEA NOT NULL` en la definición de `files`.
  - `supabase/schema_migration_fix.sql`: se agregó `ADD COLUMN IF NOT EXISTS encryption_salt BYTEA NOT NULL DEFAULT '\x'` para tablas existentes.
- Flujo E2E validado: el usuario confirmó que puede cifrar/subir archivos, el receptor los visualiza, y las estadísticas de descargas y tiempo de visualización funcionan correctamente.
- Cambio de UX solicitado: en `lib/features/upload/presentation/screens/upload_screen.dart` el texto del botón de subida cambió de "Cifrar y generar enlace en Cloudflare R2" a "Cifrar y generar enlace".
- Configuración de marca visual:
  - Se agregó el logo `assets/KRIPTONSHARE_Logo_Primary.png` a `pubspec.yaml` como fuente para splash screen y app icon.
  - Se agregaron los paquetes `flutter_native_splash` y `flutter_launcher_icons` en `dev_dependencies`.
  - Se configuró `flutter_native_splash` con fondo `#0A0A0F` (Charcoal Black) y el logo para Android, iOS y Android 12+.
  - Se configuró `flutter_launcher_icons` para generar iconos de launcher en Android usando `assets/KRIPTONSHARE_App_Icon.png`. iOS se dejó desactivado (`ios: false`) porque el directorio `ios/Runner/Assets.xcassets/AppIcon.appiconset` no existe en el proyecto y el generador fallaba.
  - El usuario proporcionó `assets/KRIPTONSHARE_App_Icon.png` (icono cuadrado con la K en escudo sobre fondo oscuro). Se actualizó `pubspec.yaml` para usar esta imagen tanto en `flutter_native_splash` como en `flutter_launcher_icons`.
  - Se reemplazó la letra "K" del cuadro verde en `lib/screens/auth/auth_screen.dart` por `Image.asset('assets/KRIPTONSHARE_App_Icon.png')` con esquinas redondeadas, pero el usuario pidió revertirlo; la "K" volvió a aparecer en el cuadro verde.

### Pendiente
- Usuario debe volver a ejecutar `flutter run` para validar que la subida a R2 completa exitosamente (el insert en Supabase ya no debe fallar por `encryption_salt`).
- Verificar que `flutter analyze` no reporte nuevos issues tras los cambios.

### Bloqueantes conocidos
- El entorno del agente no puede ejecutar Bash/PowerShell porque el wrapper inserta `cd ... &&` y PowerShell 5.1 no acepta `&&`. Por eso el usuario debe ejecutar los comandos de Flutter localmente en VS Code.
- Las credenciales de Cloudflare R2 parecen estar configuradas (logs muestran endpoint real y test 200), por lo que el placeholder ya no es bloqueante.

## 2026-06-26

### Tarea
Migrar el almacenamiento de archivos cifrados de Supabase Storage a Cloudflare R2, completando la arquitectura de soberanía de datos y desacoplamiento binario.

### Decisiones clave
- Los binarios cifrados ahora fluyen directamente desde/hacia Cloudflare R2 vía REST (Dio), sin pasar por Supabase Storage. Supabase conserva solo metadatos ligeros y relaciones.
- Las credenciales de R2 se inyectan por entorno de compilación (`R2_ENDPOINT`, `R2_SECRET_TOKEN`) con placeholders en `lib/utils/constants.dart`.
- Mantener los límites freemium restrictivos: 10 MB, 20 links/mes, 3 links activos concurrentes, 48h máximo de duración.
- Pantalla de subida refactorizada a estado local con slider de 1–48h y overlay de procesamiento dividido 40%/40%/20% (autoridad / anuncio B2B / upsell).

### Cambios realizados
- `supabase/migrations/20260625000000_cloudflare_r2_and_freemium_limits.sql`: migración con `max_file_size_bytes DEFAULT 10485760`, `max_links_monthly DEFAULT 20` y función `check_upload_limits` con bypass Premium, validación de tamaño, cuota mensual y concurrencia de 3 links activos (`SECURITY DEFINER`).
- `lib/utils/constants.dart`: reemplazo completo con getters `supabaseUrl`/`supabaseAnonKey`, sección `INFRAESTRUCTURA DE ALMACENAMIENTO PERIMETRAL: CLOUDFLARE R2` (`storageProvider = 'r2'`, `bucketName`, `r2Endpoint`, `r2AccessKeyId`, `r2SecretAccessKey`) y retención de UI constants para no romper otras pantallas.
- `lib/services/r2_signature_service.dart`: nuevo servicio de firma AWS Signature Version 4 para peticiones S3-compatible contra Cloudflare R2 (región `auto`).
- `lib/providers/file_provider.dart`: refactor completo a Cloudflare R2 REST con autenticación S3 (Access Key ID + Secret Access Key).
  - `canUpload` ahora requiere `userId` y valida concurrencia de links activos.
  - `uploadAndCreateLink` encripta localmente, firma y sube el payload a R2 con `PUT` vía stream, y registra metadatos en Supabase.
  - `downloadAndDecryptFile` firma y descarga bytes desde R2 con `GET`, luego descifra localmente.
  - `deleteFile` firma y elimina el objeto en R2 con `DELETE` antes de borrar registros.
  - Logs de diagnóstico temporales agregados (`debugPrint`) y método `testR2Connection()` para depurar error `SSLV3_ALERT_HANDSHAKE_FAILURE` en Dio.
  - Corrección error HTTP 411: se cambió `data: Stream.fromIterable(...)` por `data: encryptedBytes` en el `PUT` a R2. S3/R2 requiere la cabecera `Content-Length`, que Dio calcula automáticamente cuando envía `Uint8List` en lugar de un stream.
- `lib/features/upload/presentation/screens/upload_screen.dart`: reemplazo completo.
  - Estado local para cifrado/subida/progreso/link/errores.
  - Slider interactivo de 1 a 48 horas con etiqueta dinámica.
  - Overlay de procesamiento a pantalla completa con esqueleto publicitario 40/40/20.
  - Post-`flutter analyze`: se eliminó import `dart:typed_data` sin uso y se reactivó la visualización de `_selectedFileSize` en KB.
  - Nota: la ruta solicitada por el usuario (`lib/screens/upload/upload_screen.dart`) no existe en el proyecto; la ruta activa conectada al router es `lib/features/upload/presentation/screens/upload_screen.dart`.

### Advertencias técnicas
- El campo `aes_key_encrypted` sigue almacenándose en Supabase. Aunque el prompt lo mantiene, idealmente no debería persistirse la clave derivada en el servidor para un modelo Zero-Knowledge puro. Considerar eliminarlo en una fase posterior.
- El anuncio B2B del overlay es un esqueleto estático con `OutlinedButton` placeholder; no usa `google_mobile_ads` en esta pantalla.
- El parámetro `maxDownloads` de `uploadAndCreateLink` está aceptado pero aún no se expone en la UI.

### Pendiente
- Reemplazar placeholders de R2 en `lib/utils/constants.dart` por credenciales reales de Cloudflare.
- Aplicar la migración SQL en Supabase (SQL Editor o CLI).
- Ejecutar `flutter pub get`, `flutter analyze` y `flutter build apk --debug` en el entorno Windows del usuario.
- Validar flujo E2E: subida a R2, descarga desde R2 y descifrado en dispositivo receptor.

## 2026-06-23

### Tarea
Aplicar fase de ingeniería de monetización y restricción de recursos en KRIPTONSHARE.

### Decisiones clave
- Inyectar reglas B2B directamente en PostgreSQL para evitar evasión por clientes modificados o llamadas API directas.
- Alinear constantes del cliente con nuevos umbrales: 20 links/mes, 3 links activos simultáneos, 48h máximo de duración.
- Preparar infraestructura Google Mobile Ads (AdMob) e integrar anuncio nativo en la pantalla de subida.
- Reemplazar indicador de duración fija por un Slider que permite elegir entre 1 y 48 horas.

### Cambios realizados
- `supabase/20260623000000_update_freemium_limits.sql`: migración con `max_links_monthly DEFAULT 20` y función `check_upload_limits` que valida tamaño, cuota mensual y concurrencia de 3 links activos. **Pendiente:** mover a `supabase/migrations/` (no se pudo crear el subdirectorio desde este entorno Windows/PowerShell 5.1).
- `lib/core/utils/constants.dart` y `lib/utils/constants.dart`: actualizados con `maxLinksPerMonth = 20`, `maxActiveLinks = 3`, `maxDurationHours = 48`, `defaultDurationHours = 24`, `maxDurationSeconds = 48 * 3600`.
- `pubspec.yaml`: dependencia `google_mobile_ads` actualizada de `^4.0.0` a `^7.0.0` para compatibilidad con Gradle 9.1.0 / Android Gradle Plugin 9.0.1.
- `android/app/src/main/AndroidManifest.xml`: añadido `<meta-data>` de AdMob APPLICATION_ID.
- `ios/Runner/Info.plist`: añadida clave `GADApplicationIdentifier`.
- `lib/main.dart`: importado `google_mobile_ads` e inicializado `MobileAds.instance.initialize()`.
- `lib/features/upload/presentation/screens/upload_screen.dart`: añadido Slider de duración, overlay de procesamiento con anuncio nativo B2B (`_NativeAdB2B` con `NativeTemplateStyle`) y cálculo de `expiresAt` según `_selectedDuration`.
- Capas de upload (`IUploadRepository`, `UploadFileUseCase`, `UploadNotifier`, `UploadRepositoryImpl`): propagado parámetro `DateTime? expiresAt` para respetar la duración seleccionada.
- `lib/providers/file_provider.dart`, `lib/screens/auth/auth_screen.dart`, `lib/features/qna/domain/entities/chat_message_entity.dart`: actualizados textos hardcodeados de 50 links/mes y 72h a valores parametrizados desde `AppConstants`.
- `UPLOAD_AD_FLOW.md`: diagrama Mermaid del flujo de cifrado + anuncio nativo.

### Notas técnicas
- El entorno Windows actual no permite ejecutar comandos `Bash` porque el wrapper inserta `cd ... &&` y PowerShell 5.1 no acepta `&&`. No se pudo crear `supabase/migrations/` ni ejecutar `flutter analyze`/`flutter pub get`.
- Los IDs de AdMob usados son de prueba (`ca-app-pub-3940256099942544~...`); deben reemplazarse por los de producción.
- El botón de upsell a Premium es un placeholder; debe conectarse a RevenueCat cuando esté disponible.

### Pendiente
- ✅ Mover `supabase/20260623000000_update_freemium_limits.sql` a `supabase/migrations/` y aplicar la migración en Supabase. **Aplicado en 2026-06-23 vía SQL Editor del dashboard de Supabase.**
- Ejecutar `flutter pub get`, `flutter analyze` y `flutter build apk --debug` en el entorno del usuario.
- Configurar IDs reales de AdMob y unidades de anuncio nativo para producción.

## 2026-06-21

### Tarea
Mejorar la experiencia del receptor de un enlace cifrado:
- Al abrir `https://kriptonshare.com/room/<id>`, mostrar que ha recibido un archivo cifrado.
- Permitir abrir PDFs directamente dentro de la app.
- Mostrar una sección "Archivos recibidos" en el Dashboard.

### Decisiones clave
- Se agregó el paquete `pdfrx` como visor nativo de PDFs dentro de la app.
- Se extendió `KriptonFile` con campos del link (`linkId`, `linkExpiresAt`, `recipientEmail`, `linkIsActive`) para mantener contexto de recepción.
- Se creó función RPC `get_received_files` en Supabase para listar archivos enviados al usuario autenticado (`recipient_email = auth.email()`).
- Se agregó validación opcional: si el link tiene destinatario, solo ese email puede acceder.
- Se mantuvo el botón de compartir como opción secundaria para PDFs y principal para otros formatos.

### Cambios realizados
- `pubspec.yaml`: dependencia `pdfrx: ^1.1.24`.
- `lib/models/kripton_file.dart`: campos opcionales del share_link y helper `_parseBytea` para soportar tanto `List<dynamic>` como String base64 provenientes de Supabase.
- `lib/screens/viewer/viewer_screen.dart`: mensaje "Has recibido un archivo cifrado", validación de destinatario, visor nativo de PDF.
- `lib/providers/file_provider.dart`: provider `receivedFilesProvider` y método `getReceivedFiles()`.
- `lib/screens/dashboard/dashboard_screen.dart`: sección "Archivos recibidos" con tarjetas navegables a `/room/<id>`.
- `supabase/test_e2e_setup.sql`: función RPC `get_received_files`.
- `E2E_TEST_GUIDE.md`: actualización del flujo de prueba incluyendo PDF nativo y archivos recibidos.

### Bugs corregidos
- Error en "Archivos recibidos": `type 'String' is not a subtype of type 'List<dynamic>' in type cast`. Causa: la RPC devolvía BYTEA como String. Solución: `KriptonFile.fromJson` ahora acepta `List<dynamic>` y String base64.
- Error en "Archivos recibidos": `FormatException: Invalid character`. Causa: el String devuelto por Supabase para BYTEA no era base64 válido. Solución: eliminar las columnas BYTEA de `get_received_files` (no se usan en el Dashboard) y hacer los campos criptográficos de `KriptonFile` opcionales con default `[]`.
- Error al re-ejecutar SQL: `cannot change return type of existing function`. Solución: agregar `DROP FUNCTION IF EXISTS get_received_files();` antes de recrear la función.
- Error al abrir archivo recibido: `FormatException: Invalid character \x5b37362c...`. Causa: Supabase enviaba BYTEA como String con array JSON literal. Solución: `_parseBytea` ahora soporta `List<dynamic>`, String JSON array, String hex `\\x...` y String base64.

### Mejora de seguridad solicitada
- Eliminar opciones de compartir/descargar en el visor de documentos descifrados.
- Evitar copia de texto en documentos de texto.
- Reforzar `FLAG_SECURE` al mostrar contenido sensible.
- Cambios en `lib/screens/viewer/viewer_screen.dart`: se quitaron botones de compartir, se reemplazó `SelectableText` por `Text`, se llama `ScreenshotService.enableSecureView()` tras descifrar.

### Telemetría de lectura por página
- Se verificó que la infraestructura de telemetría existía pero no se usaba en `ViewerScreen`.
- Se creó `lib/providers/local_database_provider.dart` para romper dependencias circulares.
- Se creó `lib/features/telemetry/telemetry_providers.dart` para evitar dependencias circulares con `main.dart`.
- Se movieron `telemetryRepositoryProvider` y `telemetryNotifierProvider` desde `lib/main.dart` a `lib/features/telemetry/telemetry_providers.dart`.
- Se actualizó `lib/main.dart` para usar `localDatabaseProvider` desde `lib/providers/local_database_provider.dart`.
- Se integró `telemetryNotifierProvider` en `ViewerScreen`.
- Se registra `download_complete` al descifrar exitosamente.
- Se registra `page_view` con `pageNumber` y `durationMs`:
  - PDFs: se usa `PdfViewerController` para detectar cambios de página.
  - Imágenes y texto: se registra como página 1 con duración hasta cerrar el visor.
- Correcciones post-`flutter analyze`: `PdfViewerController` no requiere `dispose()`; `pageNumber` es nullable y se maneja con null-safety.
- Se agregó la creación de la tabla `telemetry_events` y sus políticas RLS en `supabase/test_e2e_setup.sql` para que el script de pruebas E2E sea autocontenido.
- Políticas RLS de `telemetry_events`: cualquier usuario autenticado puede insertar eventos; solo el owner del link puede verlos.
- Los errores de telemetría se ignoran silenciosamente para no interrumpir la UX.

### Resultado
- `flutter analyze` sin errores.
- Sección "Archivos recibidos" en Dashboard funciona correctamente tras recrear `get_received_files` en Supabase.

### Acceso a Analytics para el emisor
- Se agregó botón de Analytics en el `AppBar` del `DashboardScreen` para navegar a `/analytics`.
- Se mejoró la visualización de eventos en `AnalyticsDashboardScreen`:
  - Duración en formato legible (segundos/minutos) en lugar de ms.
  - Fecha y hora del evento.
- Se corrigió el contador de descargas en "Top Links" cruzándolo con eventos `download_complete` de `telemetry_events`.
- Se actualizó `SupabaseAnalyticsDataSource` para agregar `link_id` en la query de eventos y calcular descargas por link.

### Pendiente
- Validar flujo completo E2E en dos dispositivos Android (abrir link, descifrar y ver PDF nativo).

## 2026-06-20

### Tarea
Prueba de extremo a extremo (E2E) en dos dispositivos Android:
- Usuario A sube un archivo cifrado.
- Se genera un link compartible.
- Usuario B abre el link en la app y descifra el archivo.

### Decisiones clave
- Ambos usuarios deben tener cuenta en KRIPTONSHARE (preferencia del usuario).
- Creación de usuarios desde el dashboard de Supabase (no automatizada con service_role).
- Uso de dos dispositivos Android físicos para la prueba.
- Se creó función RPC `get_shared_file_metadata` con `SECURITY DEFINER` para que un receptor autenticado pueda leer metadata del archivo sin violar RLS de owner.
- Se configuró lectura pública en el bucket de Storage porque los archivos están cifrados; la seguridad real está en la contraseña.

### Cambios realizados
- `supabase/test_e2e_setup.sql`: funciones RPC y políticas de Storage.
- `supabase/test_users_setup.sql`: instrucciones para crear usuarios de prueba.
- `supabase/schema_migration_fix.sql`: migración de emergencia para agregar columnas faltantes en tablas existentes.
- `lib/providers/file_provider.dart`: `getFileByLinkId` usa RPC; `downloadAndDecryptFile` registra métricas.
- `lib/screens/viewer/viewer_screen.dart`: implementación completa de carga, descifrado y visualización.
- `lib/providers/router_provider.dart`: ruta `/room/:id` y redirect preservado para login.
- `lib/screens/auth/auth_screen.dart`: acepta `redirectPath` y navega tras login/registro.
- `lib/main.dart`: conexión de `app_links` para deep links.
- `lib/utils/constants.dart`: helpers `shareUrl()` y `appLinkUrl()`.
- `lib/features/upload/data/repositories/upload_repository_impl.dart` y `lib/features/links/presentation/screens/links_screen.dart`: usan el helper de URL.
- `E2E_TEST_GUIDE.md`: guía completa de preparación, build y prueba.

### Pendiente
- Ejecutar `flutter pub get`, `flutter analyze` y `flutter build apk --debug` en el entorno del usuario (no se pudo ejecutar desde este agente en Windows).
- Instalar el APK en los dos dispositivos Android y ejecutar la prueba E2E.

### Notas técnicas
- El entorno Windows actual no permite ejecutar comandos Bash/PowerShell a través de la herramienta `Bash` (falla el separador `&&`).
- `main.dart` ahora importa `utils/constants.dart` en lugar de `core/utils/constants.dart` para usar las credenciales reales de Supabase hardcodeadas.
