# KRIPTONSHARE — Fase 1: Vista Previa Segura de Documentos Microsoft Office

> **Documento de especificación técnica para implementación automatizada (KIMI CODE CLI).**
> Fecha: 2026-07-27 · Estado: Aprobado para implementación · Alcance: Fase 1 (conversión Office → PDF en upload + visualización con `pdfrx`)
>
> **Instrucción para el agente de código:** este documento es autocontenido. Las rutas de archivos, nombres de columnas, firmas de métodos y fragmentos de código son contractuales: impleméntalos tal como se describen. Cuando un fragmento existente del repositorio se cite como referencia, búscalo y modifícalo en el lugar indicado. No renombres símbolos existentes fuera de lo especificado. Al final hay una checklist de tareas ordenadas: ejecútala en ese orden.

---

## 1. Objetivo

Permitir que los usuarios de KRIPTONSHARE suban documentos de Microsoft Office (`.docx`, `.xlsx`, `.pptx` y sus variantes heredadas/OpenDocument) y que los receptores los **visualicen dentro de la app móvil** con el mismo nivel de seguridad que un PDF: cifrado AES-256-GCM en reposo, descifrado solo en memoria, watermark dinámico, bloqueo de capturas de pantalla y temporalidad (auto-destrucción).

**Restricción inviolable:** el documento nunca se abre con aplicaciones externas ni visores en la nube de terceros (Microsoft, Google). La visualización ocurre exclusivamente dentro de KRIPTONSHARE.

### 1.1 Estrategia elegida (resumen)

1. En el **momento del upload**, el dispositivo del **emisor** (que legítimamente posee el texto plano) envía el documento Office original a un **servicio de conversión efímero** propio (Gotenberg / LibreOffice headless detrás de un gateway de autenticación).
2. El servicio devuelve un **PDF de vista previa**. El servicio no persiste nada: procesa en memoria/tmpfs, no registra contenido y descarta todo al responder.
3. La app del emisor **cifra el PDF con la misma contraseña del archivo** (salt/nonce nuevos, mismo formato de payload `salt || nonce || ciphertext || authTag`) y lo sube a Cloudflare R2 como **segundo objeto** ligado al mismo registro `files`.
4. El receptor abre el link, ingresa la **misma contraseña de siempre**, y la app descarga/descifra el PDF de vista previa y lo renderiza con el visor `pdfrx` ya existente. El original Office cifrado se conserva intacto en R2.

**Consecuencia de seguridad clave:** el modelo zero-knowledge se mantiene frente a Supabase y Cloudflare R2 (ambos solo almacenan ciphertext). El único punto de confianza nuevo es el servicio de conversión, que ve texto plano de forma efímera durante el upload — el mismo modelo de confianza que usan DocSend/Digify. Esto debe documentarse al usuario en la sección 12.

**Límites por plan (contractual):** la conversión hereda exactamente los topes del producto — **10 MB por archivo para el plan gratuito** y **100 MB para premium/enterprise** — aplicados en tres capas: cliente (`AppConstants.conversionMaxBytesFor`), RPC existente `check_upload_limits` y, de forma autoritativa, el gateway de conversión consultando `users.max_file_size_bytes` en servidor (§4.3). Ningún archivo que el plan no permita subir puede llegar a convertirse.

### 1.2 Fuera de alcance (Fase 2, no implementar)

- Renderizado de Office directamente en el dispositivo con SDK comercial (Apryse/PDFTron) — zero-knowledge total.
- Edición o anotación de documentos.
- ONLYOFFICE / Collabora.
- Conversión asíncrona post-upload (la Fase 1 convierte síncronamente durante el upload).

---

## 2. Estado actual del sistema (lo que existe hoy)

Archivos relevantes verificados en el repositorio (rama `main`, commit `b9b6bdb`):

| Componente | Archivo | Rol actual |
|---|---|---|
| Cifrado AES-256-GCM + PBKDF2 (100k iter.) | `lib/services/crypto_service.dart` | `encryptFileInIsolate()`, `encryptFile()`, `decryptFileBytes()`; payload `salt(16) ‖ nonce(12) ‖ ciphertext ‖ authTag(16)` |
| Upload + link (flujo en producción) | `lib/providers/file_provider.dart` → `FileService.uploadAndCreateLink()` | Cifra en Isolate, sube a **Cloudflare R2** con firma SigV4 (`R2SignatureService`), inserta en `files` y `share_links` |
| Upload (Clean Architecture, paralelo) | `lib/features/upload/...` → `UploadRepositoryImpl.uploadFile()` | Variante con `SupabaseUploadDataSource` (Supabase Storage). Mantener paridad de cambios (ver §8.7) |
| Descarga + descifrado | `lib/providers/file_provider.dart` → `FileService.downloadAndDecryptFile()` | GET firmado a R2, separa salt/nonce/ciphertext/authTag, deriva clave con la contraseña del receptor |
| Visor seguro | `lib/screens/viewer/viewer_screen.dart` | `pdfrx` para PDF, `Image.memory` para imágenes, texto plano, video; **Office cae en el bloque "Formato protegido"** que pide convertir a PDF manualmente |
| Watermark | `WatermarkPainter` en `viewer_screen.dart` | Texto estático `'KRIPTONSHARE | CONFIDENCIAL'`, opacidad 0.18 |
| Anti-screenshots | `lib/services/screenshot_service.dart` | MethodChannel `com.kriptonshare/screenshot`, `FLAG_SECURE` global |
| Firmado R2 | `lib/services/r2_signature_service.dart` | AWS SigV4, región `auto`, servicio `s3` |
| Constantes | `lib/utils/constants.dart` | `AppConstants.bucketName = 'kriptonshare-ephemeral'`, endpoint R2, límites freemium/premium, constantes crypto |
| Esquema DB | `supabase/schema.sql` + migraciones en `supabase/migrations/` | Tablas `users`, `files`, `share_links`, `chat_messages`, `telemetry_events`; RPCs `check_upload_limits`, `get_received_files`, `cleanup_expired_files` |

> **Nota importante:** las RPCs `get_shared_file_metadata(p_link_id)`, `increment_link_access_count(p_link_id)` e `increment_file_download_count(p_file_id)` se **invocan desde el cliente** (`file_provider.dart`) pero sus definiciones SQL **no están en el repositorio** (viven en la base de datos). La migración de §5 debe (re)definirlas con `CREATE OR REPLACE` incluyendo las columnas nuevas, y el equipo debe verificar post-deploy que la versión desplegada coincide.

---

## 3. Arquitectura objetivo (Fase 1)

```
┌─────────────────────────── EMISOR (Flutter) ───────────────────────────┐
│ upload_screen → FileService.uploadAndCreateLink()                      │
│                                                                        │
│  1. ¿mimeType es Office? ──NO──► flujo actual (idéntico a hoy)         │
│        │SI                                                             │
│        ▼                                                               │
│  2. ConversionService.convertToPdf(fileBytes)  ──HTTPS+JWT──┐          │
│        │  (PDF en memoria, timeout 120 s)                    │          │
│        ▼                                                    │          │
│  3. encryptFileInIsolate(original)  y  encryptFileInIsolate(pdf)       │
│        (MISMA contraseña, salt/nonce independientes)        │          │
│        ▼                                                    │          │
│  4. PUT R2: storageKey (original cifrado)                   │          │
│     PUT R2: viewerStorageKey (pdf cifrado)                  │          │
│        ▼                                                    │          │
│  5. INSERT files (..., viewer_object_key, conversion_status='ready')   │
└─────────────────────────────────────────────────────────────┼──────────┘
                                                              │
                                                              ▼
┌────────────────── conversion-gateway (nuevo, Docker) ──────────────────┐
│  POST /v1/convert/office                                               │
│   - Valida JWT de Supabase (Authorization: Bearer)                     │
│   - Límite de tamaño por plan (10 MB free / 100 MB premium)            │
│   - Multipart → Gotenberg POST /forms/libreoffice/convert              │
│   - Devuelve application/pdf                                           │
│  Seguridad: tmpfs, sin logs de contenido, sin persistencia,            │
│  rate-limit por usuario, solo HTTPS detrás de proxy TLS                │
└────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────── RECEPTOR (Flutter) ─────────────────────────┐
│ viewer_screen → FileService.downloadAndDecryptFile()                   │
│                                                                        │
│  - mime Office + conversion_status='ready'                             │
│      → descarga/descifra viewer_object_key (misma contraseña)          │
│      → PdfViewer.data(pdfrx) + WatermarkPainter dinámico               │
│  - cualquier otro caso → comportamiento actual sin cambios             │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Nuevo componente: `conversion-gateway` + Gotenberg

### 4.1 Por qué un gateway y no llamar a Gotenberg directo

Gotenberg no autentica ni limita por usuario. El gateway (proceso ligero junto a Gotenberg en el mismo host) aporta: validación del JWT de Supabase, límite de tamaño por tier, rate-limiting, allowlist de extensiones, timeouts y logs sin contenido.

> **Alternativa simple documentada (no implementar salvo bloqueo de infra):** una Supabase Edge Function `office-convert` que reciba el archivo y lo reenvíe a Gotenberg. Rechazada como opción principal porque los límites de tamaño/tiempo de Edge Functions chocan con archivos premium de hasta 100 MB. Úsese solo como contingencia para archivos < 20 MB.

### 4.2 Despliegue (nuevo directorio `infra/conversion/`)

Crear **`infra/conversion/docker-compose.yml`**:

```yaml
services:
  gotenberg:
    image: gotenberg/gotenberg:8
    restart: unless-stopped
    command:
      - "gotenberg"
      - "--api-port=3000"
      - "--api-timeout=120s"
      - "--libreoffice-restart-after=200"
      - "--log-level=warn"               # no registrar nombres ni contenido
    tmpfs:
      - /tmp:size=512m,mode=1777          # trabajo solo en RAM
    networks: [conversion]
    # SIN puertos publicados: solo accesible desde el gateway

  gateway:
    build: ./gateway
    restart: unless-stopped
    environment:
      GOTENBERG_URL: http://gotenberg:3000
      SUPABASE_JWT_SECRET: ${SUPABASE_JWT_SECRET}   # del dashboard de Supabase
      SUPABASE_URL: ${SUPABASE_URL}
      SUPABASE_SERVICE_ROLE_KEY: ${SUPABASE_SERVICE_ROLE_KEY}  # solo para leer users.max_file_size_bytes
      FREE_MAX_BYTES: "10485760"          # 10 MB — límite plan gratuito (fallback)
      PREMIUM_MAX_BYTES: "104857600"      # 100 MB — límite plan premium/enterprise (fallback)
      PORT: "8080"
    ports:
      - "127.0.0.1:8080:8080"             # solo loopback; TLS lo termina Caddy/Nginx
    depends_on: [gotenberg]
    networks: [conversion]

networks:
  conversion:
```

Requisitos de entorno del host: Docker, proxy TLS (Caddy recomendado por certificados automáticos), dominio `convert.kriptonshare.com`, firewall que solo exponga 443. Nada de esto vive en Supabase ni en Cloudflare: es un VPS independiente (o Fly.io/Railway) cuyo único dato sensible es `SUPABASE_JWT_SECRET` en variables de entorno del host.

### 4.3 Contrato del endpoint

**`POST https://convert.kriptonshare.com/v1/convert/office`**

- Headers: `Authorization: Bearer <access_token de Supabase Auth>`, `Content-Type: multipart/form-data`.
- Body multipart: campo `file` (binario). **No se acepta ningún campo de tier ni de tamaño del cliente**: el límite se resuelve en servidor.
- **Límite de tamaño por plan (obligatorio, autoritativo en servidor):** el gateway consulta `users.max_file_size_bytes` del usuario autenticado (vía Supabase REST con la service role key, cacheado 5 min por `sub`). Esa columna ya existe y es la fuente de verdad del plan: **10 MB (10 485 760 bytes) para free** y **100 MB (104 857 600 bytes) para premium/enterprise** (configurada en `supabase/schema.sql` y las migraciones freemium/premium). Si la consulta falla, se aplica el fallback conservador `FREE_MAX_BYTES` (10 MB). Esta validación es **defensa en profundidad**: la app ya rechaza archivos sobre el límite antes de llamar al gateway (`check_upload_limits`), pero el gateway nunca confía en el cliente.
- Extensiones permitidas (allowlist estricta): `doc docx xls xlsx ppt pptx odt ods odp rtf`.
- Respuesta `200`: `Content-Type: application/pdf`, cuerpo = PDF.
- Errores JSON `{ "error": "<code>" }`: `401 unauthorized`, `413 too_large` (con campo `limit_bytes` del plan del usuario), `415 unsupported_format`, `422 conversion_failed` (LibreOffice no pudo), `429 rate_limited`, `504 conversion_timeout`.
- Timeout total: 120 s. Rate limit: 10 conversiones/minuto por usuario, 100/día (en memoria).

### 4.4 Implementación del gateway (nuevo directorio `infra/conversion/gateway/`)

Servicio mínimo en **Deno** (un solo archivo `main.ts`, sin framework, coherente con el ecosistema Supabase Edge). Responsabilidades en orden:

1. Rechazar métodos ≠ POST y rutas ≠ `/v1/convert/office`.
2. Extraer y **verificar el JWT** (HS256 con `SUPABASE_JWT_SECRET`, validando `exp` y `iss`). Rechazar anónimos.
3. **Resolver el límite del plan:** GET `${SUPABASE_URL}/rest/v1/users?id=eq.<sub>&select=max_file_size_bytes` con la service role key (cache en memoria 5 min por `sub`; si falla → `FREE_MAX_BYTES` = 10 MB).
4. Parsear multipart con **límite duro por streaming**; cortar la conexión en cuanto se exceda el límite resuelto del usuario (10 MB free / 100 MB premium) — no bufferizar más. Nunca aceptar > `PREMIUM_MAX_BYTES` aunque la consulta de tier falle.
5. Verificar extensión contra la allowlist y `Content-Length` > 0.
6. Rate-limit por `sub` del JWT en un `Map` en memoria.
7. Reenviar a Gotenberg: `POST ${GOTENBERG_URL}/forms/libreoffice/convert` con multipart `files=@<archivo>` y campo `pdfa=PDF/A-2b` (salida archivable y determinista).
8. Devolver el stream del PDF tal cual. **Jamás escribir a disco ni registrar nombre, tamaño exacto en bytes ni contenido.** Logs solo: `user_sub(prefix 8)`, extensión, duración, código de estado.
9. Mapear errores de Gotenberg a los códigos de §4.3.

Incluir `infra/conversion/gateway/Dockerfile` (`FROM denoland/deno:alpine`, `CMD ["run", "--allow-net", "--allow-env", "main.ts"]`) y `infra/conversion/README.md` con pasos de despliegue (crear VPS, copiar `.env`, `docker compose up -d`, apuntar DNS, verificar con `curl`).

---

## 5. Cambios en la base de datos (Supabase)

Crear **`supabase/migrations/20260801000000_office_pdf_preview.sql`**:

```sql
-- ==========================================================
-- FASE 1: Vista previa PDF para documentos Office
-- Agrega columnas de preview a files y expone nuevas RPCs.
-- ==========================================================

ALTER TABLE files
  ADD COLUMN IF NOT EXISTS viewer_object_key UUID,
  ADD COLUMN IF NOT EXISTS viewer_file_size_bytes INTEGER
      CHECK (viewer_file_size_bytes IS NULL OR viewer_file_size_bytes > 0),
  ADD COLUMN IF NOT EXISTS conversion_status TEXT NOT NULL DEFAULT 'none'
      CHECK (conversion_status IN ('none', 'pending', 'ready', 'failed'));

CREATE UNIQUE INDEX IF NOT EXISTS idx_files_viewer_object_key
  ON files(viewer_object_key) WHERE viewer_object_key IS NOT NULL;

-- Metadata del archivo compartido (incluye preview). SECURITY DEFINER:
-- valida que el link exista, esté activo y no expirado; no requiere RLS del receptor.
CREATE OR REPLACE FUNCTION get_shared_file_metadata(p_link_id UUID)
RETURNS TABLE (
    id UUID, owner_id UUID, original_filename TEXT,
    file_size_bytes INTEGER, mime_type TEXT,
    storage_provider TEXT, bucket_name TEXT, storage_object_key UUID,
    viewer_object_key UUID, viewer_file_size_bytes INTEGER,
    conversion_status TEXT,
    created_at TIMESTAMPTZ, expires_at TIMESTAMPTZ,
    max_downloads INTEGER, downloads_count INTEGER, status TEXT,
    link_id UUID, link_expires_at TIMESTAMPTZ,
    recipient_email TEXT, is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT f.id, f.owner_id, f.original_filename, f.file_size_bytes, f.mime_type,
           f.storage_provider, f.bucket_name, f.storage_object_key,
           f.viewer_object_key, f.viewer_file_size_bytes, f.conversion_status,
           f.created_at, f.expires_at, f.max_downloads, f.downloads_count, f.status,
           sl.id, sl.expires_at, sl.recipient_email, sl.is_active
    FROM share_links sl
    JOIN files f ON f.id = sl.file_id
    WHERE sl.id = p_link_id
      AND sl.is_active = TRUE
      AND sl.expires_at > NOW()
      AND f.status = 'active'
      AND f.expires_at > NOW()
      AND f.downloads_count < f.max_downloads
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- get_received_files(): añadir a su RETURN QUERY las columnas
-- viewer_object_key, viewer_file_size_bytes y conversion_status
-- (CREATE OR REPLACE con la definición vigente en la base + estas 3 columnas).
-- Contadores: increment_link_access_count(p_link_id) e
-- increment_file_download_count(p_file_id) se verifican/rec crean con
-- CREATE OR REPLACE si no están versionadas en el repo.
```

Notas de implementación DB:

- La política RLS de `files` no cambia: las nuevas columnas solo se exponen vía las RPCs `SECURITY DEFINER` (mismo patrón que hoy).
- `cleanup_expired_files()` no cambia: al expirar, **ambos** objetos R2 (original y preview) quedan huérfanos y los elimina la lifecycle rule del bucket (72 h). El borrado explícito por el usuario sí debe eliminar ambos (ver §8.5).
- No tocar el CHECK de `telemetry_events.event_type` en Fase 1 (la telemetría del preview reutiliza `page_view` / `download_complete`).

---

## 6. Convención de cifrado del preview (sin cambios de modelo)

- El preview PDF se cifra con **la misma contraseña** que el usuario eligió para el archivo, pero con `encryptFileInIsolate()` independiente → salt y nonce propios.
- Payload idéntico al actual: `salt(16) ‖ nonce(12) ‖ ciphertext ‖ authTag(16)` subido como `application/octet-stream` a R2 bajo `viewer_object_key` (un `Uuid.v4()` nuevo).
- El receptor **no nota diferencia alguna**: ingresa una sola contraseña; la app decide qué objeto descargar.
- `mime_type` de la fila `files` **sigue siendo el del original** (p. ej. `application/vnd.openxmlformats-officedocument.wordprocessingml.document`). El preview se identifica por `viewer_object_key IS NOT NULL` + `conversion_status='ready'`.

---

## 7. Detección de formatos Office (nuevo utilitario)

Crear **`lib/utils/office_formats.dart`**:

```dart
/// Utilidades para detectar documentos convertibles a PDF (Fase 1).
class OfficeFormats {
  static const Set<String> convertibleMimeTypes = {
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/vnd.oasis.opendocument.presentation',
    'application/rtf',
    'text/rtf',
  };

  static const Set<String> convertibleExtensions = {
    'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp', 'rtf',
  };

  /// Verdadero si el archivo debe pasar por el servicio de conversión.
  /// [mimeType] puede venir vacío o como application/octet-stream en Android;
  /// en ese caso se decide por extensión de [fileName].
  static bool isConvertible({required String mimeType, required String fileName}) {
    if (convertibleMimeTypes.contains(mimeType.toLowerCase())) return true;
    final ext = fileName.split('.').last.toLowerCase();
    return convertibleExtensions.contains(ext);
  }
}
```

---

## 8. Cambios en la app Flutter, archivo por archivo

### 8.1 `pubspec.yaml`

Sin dependencias nuevas obligatorias: la conversión usa `dio` (ya presente) y el preview usa `pdfrx` (ya presente).

### 8.2 `lib/utils/constants.dart`

Agregar dentro de `AppConstants`:

```dart
// === CONVERSIÓN OFFICE → PDF (FASE 1) ===
static const String conversionServiceUrl = String.fromEnvironment(
    'CONVERSION_SERVICE_URL',
    defaultValue: 'https://convert.kriptonshare.com');
static const Duration conversionTimeout = Duration(seconds: 120);

// Límite de conversión por plan: REUTILIZA los topes ya definidos para upload.
// Free: freeMaxFileSizeBytes (10 MB) · Premium: premiumMaxFileSizeBytes (100 MB).
static int conversionMaxBytesFor({required bool isPremium}) =>
    isPremium ? premiumMaxFileSizeBytes : freeMaxFileSizeBytes;
```

> **Regla contractual:** la conversión nunca acepta un archivo que `canUpload()` / `check_upload_limits` no aceptaría. Un usuario free jamás envía más de 10 MB al gateway y un premium jamás más de 100 MB.

### 8.3 Nuevo `lib/services/conversion_service.dart`

```dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

/// Resultado de una conversión Office → PDF.
class ConversionResult {
  final Uint8List pdfBytes;
  const ConversionResult(this.pdfBytes);
}

class ConversionException implements Exception {
  final String code;   // 'too_large' | 'unsupported_format' | 'conversion_failed'
                       // | 'conversion_timeout' | 'unauthorized' | 'network'
  final String message;
  const ConversionException(this.code, this.message);
  @override
  String toString() => 'ConversionException($code): $message';
}

/// Cliente del conversion-gateway (Fase 1).
/// Envía el documento Office en texto plano por TLS autenticado con el JWT
/// de Supabase del usuario y devuelve el PDF. El servidor no persiste nada.
class ConversionService {
  final Dio _dio;

  ConversionService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.conversionServiceUrl,
              connectTimeout: const Duration(seconds: 30),
              sendTimeout: AppConstants.conversionTimeout,
              receiveTimeout: AppConstants.conversionTimeout,
            ));

  Future<ConversionResult> convertOfficeToPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String accessToken,
    required int maxBytes, // AppConstants.conversionMaxBytesFor(isPremium: ...)
  }) async {
    if (fileBytes.length > maxBytes) {
      throw ConversionException(
        'too_large',
        'El archivo excede el límite de ${maxBytes ~/ (1024 * 1024)} MB de tu plan.',
      );
    }
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      final response = await _dio.post<List<int>>(
        '/v1/convert/office',
        data: form,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return ConversionResult(Uint8List.fromList(response.data!));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final code = switch (status) {
        401 => 'unauthorized',
        413 => 'too_large',
        415 => 'unsupported_format',
        422 => 'conversion_failed',
        504 => 'conversion_timeout',
        _ => e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout
            ? 'conversion_timeout'
            : 'network',
      };
      throw ConversionException(code, 'Error de conversión (HTTP ${status ?? '-'})');
    }
  }
}
```

> En Flutter web, `MultipartFile.fromBytes` con archivos de 100 MB puede ser limitante; Fase 1 acepta la limitación y se documenta en §11 (riesgos).

### 8.4 `lib/providers/file_provider.dart` — `FileService`

**(a) Nuevo método privado de upload genérico** para no duplicar el bloque de firma SigV4:

```dart
Future<void> _putEncryptedObject(String storageKey, Uint8List encryptedBytes) async {
  final objectPath = _objectPath(storageKey);
  final payloadHash = sha256.convert(encryptedBytes).toString();
  final signedHeaders = _r2Signer.signRequest(
    method: 'PUT',
    path: objectPath,
    payloadHash: payloadHash,
    headers: {'Content-Type': 'application/octet-stream'},
  );
  await _dio.put('${AppConstants.r2Endpoint}$objectPath',
      data: encryptedBytes, options: Options(headers: signedHeaders));
}
```

Refactorizar el bloque "2. SUBIDA DIRECTA A CLOUDFLARE R2" de `uploadAndCreateLink()` para usar este método (comportamiento idéntico).

**(b) `uploadAndCreateLink()` — inserción del paso de conversión.** Después de cifrar el original y antes del insert en `files`:

```dart
String? viewerStorageKey;
int? viewerSizeBytes;
String conversionStatus = 'none';

if (OfficeFormats.isConvertible(mimeType: mimeType, fileName: fileName)) {
  conversionStatus = 'pending';
  try {
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null) throw const ConversionException('unauthorized', 'Sin sesión');
    final result = await ConversionService().convertOfficeToPdf(
      fileBytes: fileBytes,
      fileName: fileName,
      accessToken: accessToken,
      maxBytes: AppConstants.conversionMaxBytesFor(isPremium: user.isPremium),
    );
    // Misma contraseña del usuario → el receptor solo necesita una.
    final encPreview = await Isolate.run(() => encryptFileInIsolate({
      'fileBytes': result.pdfBytes,
      'password': userPassword,
    }));
    viewerStorageKey = _uuid.v4();
    final previewPayload = Uint8List.fromList([
      ...(encPreview['salt'] as Uint8List),
      ...(encPreview['nonce'] as Uint8List),
      ...(encPreview['ciphertext'] as Uint8List),
      ...(encPreview['authTag'] as Uint8List),
    ]);
    await _putEncryptedObject(viewerStorageKey, previewPayload);
    viewerSizeBytes = result.pdfBytes.length;
    conversionStatus = 'ready';
  } on ConversionException catch (e) {
    debugPrint('[CONVERSION] Falló (${e.code}): ${e.message}. Continúa sin preview.');
    conversionStatus = 'failed';   // fallback: comportamiento actual
    viewerStorageKey = null;
  }
}
```

Y en el `insert` de `files` agregar:

```dart
'viewer_object_key': viewerStorageKey,
'viewer_file_size_bytes': viewerSizeBytes,
'conversion_status': conversionStatus,
```

**(c) `downloadAndDecryptFile()`** — agregar parámetro opcional y usarlo en el path:

```dart
Future<Uint8List> downloadAndDecryptFile(
  KriptonFile file,
  String password, {
  String? linkId,
  bool useViewerObject = false,
}) async {
  final objectKey =
      useViewerObject && file.viewerObjectKey != null
          ? file.viewerObjectKey!
          : file.storageObjectKey;
  final objectPath = '/${file.bucketName}/$objectKey';
  // ... resto del método sin cambios (descarga, split salt/nonce/tag, deriveKey, decrypt)
}
```

**(d) `deleteFile()`** — tras borrar el objeto principal, borrar también el preview si existe:

```dart
final viewerKey = file['viewer_object_key'] as String?;
if (viewerKey != null && viewerKey.isNotEmpty) {
  try {
    final p = _objectPath(viewerKey);
    final h = _r2Signer.signRequest(method: 'DELETE', path: p);
    await _dio.delete('${AppConstants.r2Endpoint}$p', options: Options(headers: h));
  } catch (e) {
    debugPrint('[R2 DELETE preview] Error: $e');
  }
}
```

### 8.5 `lib/models/kripton_file.dart`

Agregar campos y su mapeo en `fromJson`/`toJson`:

```dart
final String? viewerObjectKey;
final int? viewerFileSizeBytes;
final String conversionStatus; // 'none' | 'pending' | 'ready' | 'failed'
```

- `fromJson`: `viewerObjectKey: json['viewer_object_key'] as String?` (UUID llega como String), `viewerFileSizeBytes: json['viewer_file_size_bytes'] as int?`, `conversionStatus: json['conversion_status'] as String? ?? 'none'`.
- Constructor con defaults `conversionStatus = 'none'`.
- Helper de dominio: `bool get hasPdfPreview => conversionStatus == 'ready' && viewerObjectKey != null;`

### 8.6 `lib/screens/viewer/viewer_screen.dart`

**(a) Rama de visualización Office.** En `_buildDocumentViewer()`, sustituir el bloque `else` final ("Formato protegido") por:

```dart
} else if (OfficeFormats.isConvertible(
        mimeType: mimeType, fileName: _file!.originalFilename) &&
    _file!.hasPdfPreview) {
  // El PDF de vista previa ya fue descifrado por _decryptAndView (ver b).
  content = PdfViewer.data(
    key: ValueKey('${_file!.id}-preview'),
    _decryptedBytes!,
    sourceName: '${_file!.originalFilename} (vista previa)',
    controller: _pdfController,
    useProgressiveLoading: false,
    params: pdfParams, // mismos PdfViewerParams del caso application/pdf
  );
} else {
  // ... bloque "Formato protegido" existente, con texto ajustado:
  // si conversionStatus == 'failed': 'No se pudo generar la vista previa
  // segura de este documento. Puedes volver a subirlo o convertirlo a PDF.'
}
```

Extraer la construcción de `pdfParams` a una variable común (hoy está inline en la rama PDF) para reutilizarla en ambas ramas.

**(b) `_decryptAndView()`** — decidir qué objeto descargar:

```dart
final usePreview = OfficeFormats.isConvertible(
        mimeType: _file!.mimeType, fileName: _file!.originalFilename) &&
    _file!.hasPdfPreview;
final decrypted = await fileService.downloadAndDecryptFile(
  _file!,
  _passwordController.text,
  linkId: linkId,
  useViewerObject: usePreview,
);
```

El timer de fallback de 3 s ahora aplica también cuando `usePreview` es verdadero (no solo cuando `mimeType == 'application/pdf'`).

**(c) Watermark dinámico.** Sustituir el texto estático por identificador del receptor:

```dart
WatermarkPainter(
  text: _file!.recipientEmail ?? 'KRIPTONSHARE | CONFIDENCIAL',
  secondaryText: DateTime.now().toIso8601String().substring(0, 16),
  opacity: 0.15,
),
```

Ampliar `WatermarkPainter` con `secondaryText` opcional dibujado debajo del principal (mismo patrón de rejilla diagonal -45°, tipografía secundaria 60% del tamaño). Esto activa la disuasión de filtraciones sin cambiar el modelo visual.

### 8.7 `lib/features/upload/` (variante Clean Architecture)

Mantener **paridad funcional** con `FileService`:

- `UploadRepositoryImpl.uploadFile()`: replicar el paso de conversión de §8.4(b) usando el mismo `ConversionService` y añadiendo las 3 columnas al mapa de `createFileRecord()`. Obtener el `accessToken` desde el `SupabaseClient` que ya inyecta el datasource (inyectar `SupabaseClient` al repositorio o pasar el token como parámetro desde la capa de presentación — preferir lo segundo para no acoplar).
- `supabase_upload_datasource.dart`: sin cambios de firma; el mapa `data` ya es dinámico.
- Si la variante Clean Architecture no está cableada en producción (el flujo vivo es `FileService`), los cambios pueden marcarse con `// TODO(Fase1): paridad pendiente de activación` — pero el código debe compilar.

### 8.8 `lib/features/upload/presentation/screens/upload_screen.dart`

- Al seleccionar un archivo convertible (`OfficeFormats.isConvertible`), mostrar un chip informativo: *"Se generará una vista previa PDF segura para el receptor"*.
- Durante el upload, añadir estado visual intermedio **"Generando vista previa segura…"** entre "Cifrando" y "Subiendo" (buscar el notifier en `lib/features/upload/presentation/notifiers/` y agregar el estado; si el flujo vivo no usa ese notifier, mostrar el texto desde la pantalla).
- Si `conversionStatus == 'failed'`, completar el upload normalmente y mostrar al finalizar: *"El archivo se compartió, pero no se pudo generar la vista previa. El receptor podrá descargarlo si tú lo permites."* (No bloquear el upload por fallo de conversión.)

---

## 9. Flujos completos (contratos de comportamiento)

### 9.1 Upload de un `.docx` (camino feliz)

1. Usuario elige `informe.docx` (8 MB), contraseña y duración.
2. `canUpload()` valida cuotas (sin cambios).
3. Se detecta formato convertible → estado UI "Generando vista previa segura…".
4. `ConversionService` envía el `.docx` al gateway con el JWT del usuario; recibe PDF (p. ej. 1.2 MB) en ≤120 s.
5. Se cifran **ambos** payloads con la misma contraseña en Isolates separados.
6. PUT a R2 del original cifrado (`storageKey`) y del preview cifrado (`viewerStorageKey`).
7. `INSERT files` con `viewer_object_key`, `viewer_file_size_bytes`, `conversion_status='ready'`; `INSERT share_links` (sin cambios); contador mensual (sin cambios).
8. Si cualquier paso después de subir el preview falla, la app intenta borrar ambos objetos R2 (best-effort) antes de propagar el error — no dejar huérfanos cuando la fila no se creó.

### 9.2 Upload de `.docx` con conversión fallida

Pasos 1–4 fallan (timeout/formato corrupto) → `conversionStatus='failed'`, upload continúa como hoy, UI muestra aviso no bloqueante. El receptor verá el mensaje "Formato protegido" actualizado (§8.6a).

### 9.3 Recepción y visualización

1. Receptor abre `https://kriptonshare.com/room/<linkId>` → `ViewerScreen`.
2. `getFileByLinkId()` (RPC `get_shared_file_metadata`, versión nueva) devuelve `mime_type` Office + `hasPdfPreview=true`.
3. Ingresa la contraseña → `downloadAndDecryptFile(useViewerObject: true)` → PDF en memoria.
4. `PdfViewer.data` (pdfrx) renderiza; telemetría `page_view` por página (código existente); watermark con **su email + fecha**; `FLAG_SECURE` activo.
5. `download_complete` se registra igual que hoy (los contadores cuentan aperturas, no objetos).

### 9.4 Revocación, expiración y borrado

- `revokeLink()`: sin cambios (invalida el link; ambos objetos quedan inaccesibles).
- `cleanup_expired_files()` (pg_cron 3 AM): sin cambios; lifecycle rule de R2 elimina ambos objetos a las 72 h.
- `deleteFile()`: borra ambos objetos (§8.4d) y las filas (cascada existente).

---

## 10. Seguridad

### 10.1 Qué NO cambia

- Cifrado AES-256-GCM, PBKDF2 100k, payload y derivación: intactos.
- Zero-knowledge frente a Supabase y R2: intacto (ambos solo ven ciphertext).
- Contraseña compartida fuera de banda: intacta; el receptor sigue usando una sola contraseña.
- RLS, RPCs SECURITY DEFINER, límites freemium: intactos salvo lo indicado en §5.

### 10.2 Nuevo punto de confianza y sus mitigaciones

| Riesgo | Mitigación obligatoria |
|---|---|
| El gateway ve texto plano | Solo en memoria/tmpfs; sin swap en el host; contenedor Gotenberg con `tmpfs` y `--log-level=warn`; gateway jamás escribe el archivo a disco |
| Abuso del endpoint (costo/DoS) | JWT de Supabase obligatorio; allowlist de extensiones; límite duro por plan (10 MB free / 100 MB premium, resuelto en servidor desde `users.max_file_size_bytes`); rate-limit 10/min·usuario; timeouts 120 s |
| Fuga por logs | Prohibido registrar nombre de archivo, tamaño exacto o contenido; solo métricas agregadas |
| Exfiltración de credenciales | `SUPABASE_JWT_SECRET` solo en el host (`.env` fuera del repo, modo 600); **nunca** en `constants.dart` ni en el bundle de la app |
| Intercepción en tránsito | TLS 1.2+ terminado en Caddy; el gateway solo escucha en loopback |
| SSRF vía conversión | Gotenberg sin acceso a red externa (network interna de compose, sin DNS público si es viable) |

### 10.3 Nota de honestidad de producto

Actualizar la pantalla/sección de seguridad de la app (y `README.md`, sección *Compromisos de Seguridad*) con una línea del tipo: *"Los documentos Office se convierten a PDF en un servicio efímero propio durante la subida; el contenido nunca se almacena sin cifrar ni sale de nuestra infraestructura."* El claim "zero-knowledge" debe matizarse para archivos Office en Fase 1.

---

## 11. Plan de pruebas

### 11.1 Unitarias (`test/`)

- `office_formats_test.dart`: detección por MIME, por extensión, falsos negativos (`.pdf`, `.txt`), case-insensitive.
- `conversion_service_test.dart`: con `Mocktail`/Dio mock — 200 devuelve bytes; 413→`too_large`; 415→`unsupported_format`; timeout→`conversion_timeout`; 401→`unauthorized`.
- `kripton_file_test.dart`: round-trip JSON con/sin columnas nuevas; `hasPdfPreview` en los 4 estados de `conversion_status`.
- `crypto_service_test.dart` (existente): verificar que dos `encryptFileInIsolate` con la misma contraseña producen payloads distintos y ambos descifrables con esa contraseña.

### 11.2 Integración / E2E (extender `E2E_TEST_GUIDE.md`)

1. Subir `sample.docx` (crear fixtures `test/fixtures/sample.docx|xlsx|pptx` < 1 MB) → verificar `conversion_status='ready'` y que el objeto preview existe en R2.
2. Abrir como receptor con la contraseña → el visor muestra PDF paginado con watermark del email del receptor.
3. Subir `.docx` con el gateway apagado → upload exitoso, `conversion_status='failed'`, receptor ve mensaje de formato protegido.
4. Borrar archivo → ambos objetos desaparecen de R2 (listar bucket o HEAD 404).
5. Contraseña incorrecta → error GCM (sin cambios), sin crash.
6. Límites por plan respetados de extremo a extremo:
   - Usuario **free** con archivo de 15 MB → `canUpload()`/`check_upload_limits` lo rechaza **antes** de cualquier llamada al gateway (el gateway nunca se invoca).
   - Usuario free con 11 MB que evade la validación de cliente (cliente modificado) → el gateway responde `413` con `limit_bytes: 10485760` (validación autoritativa en servidor).
   - Usuario **premium** con 120 MB → rechazo `too_large` en cliente sin llamar al gateway; si evade el cliente, el gateway responde `413` con `limit_bytes: 104857600`.
   - Usuario premium con 95 MB → conversión exitosa.

### 11.3 Verificación operativa del gateway

- `curl -X POST https://convert.kriptonshare.com/v1/convert/office -H "Authorization: Bearer <jwt>" -F file=@sample.docx -o out.pdf` → 200 y PDF válido.
- Sin token → 401. Extensión `.exe` → 415. 11 requests en un minuto → 429.
- Con JWT de usuario free y archivo de 12 MB → 413 con `limit_bytes: 10485760`. Con JWT premium y el mismo archivo → 200. Con JWT premium y archivo de 110 MB → 413 con `limit_bytes: 104857600`.
- Inspeccionar logs del host: no debe aparecer `sample.docx` ni tamaños exactos.

---

## 12. Checklist de implementación (orden de ejecución)

1. [ ] `supabase/migrations/20260801000000_office_pdf_preview.sql` (§5) y aplicarla.
2. [ ] Verificar/rec crear con `CREATE OR REPLACE` las RPCs no versionadas (`get_shared_file_metadata` incluida en la migración; `increment_*` y `get_received_files` con las columnas nuevas).
3. [ ] `lib/utils/office_formats.dart` (§7).
4. [ ] `lib/utils/constants.dart`: constantes de conversión (§8.2).
5. [ ] `lib/services/conversion_service.dart` (§8.3).
6. [ ] `lib/models/kripton_file.dart`: campos + `hasPdfPreview` (§8.5).
7. [ ] `lib/providers/file_provider.dart`: `_putEncryptedObject`, paso de conversión, `useViewerObject`, borrado doble (§8.4).
8. [ ] `lib/screens/viewer/viewer_screen.dart`: rama preview, selección de objeto, watermark dinámico (§8.6).
9. [ ] `lib/features/upload/`: paridad Clean Architecture (§8.7) y UI de estados (§8.8).
10. [ ] `infra/conversion/`: compose + gateway Deno + Dockerfile + README (§4).
11. [ ] Pruebas unitarias e integración (§11) y actualizar `E2E_TEST_GUIDE.md`.
12. [ ] Actualizar `README.md` (característica Office + matiz zero-knowledge §10.3) y `KRIPTONSHARE_Premium_DataRoom_Especificacion_Tecnica.md` (anexar esta fase).
13. [ ] `flutter analyze` sin errores nuevos y `flutter test` en verde antes de PR.

**Criterios de aceptación:** un `.docx/.xlsx/.pptx` subido desde Android se visualiza paginado dentro de la app del receptor con una sola contraseña, con watermark identificable, sin tocar disco ni apps externas, y la conversión fallida nunca bloquea ni rompe el flujo actual de compartición.

---

## 13. Riesgos conocidos y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Fidelidad LibreOffice en PPTX animados / XLSX con macros | Medio | Aceptable para data room; Fase 2 (Apryse) mejora fidelidad. El original siempre se conserva y puede habilitarse descarga opt-in |
| Latencia de conversión en upload (10–60 s) | Medio | Convertir antes de cifrar para empezar lo antes posible; estado UI dedicado; timeout 120 s con fallback no bloqueante |
| Archivos premium de 100 MB en Flutter web | Medio | Límite duro documentado; en web sugerir app móvil para >50 MB |
| Costo del VPS de conversión | Bajo | ~5–10 USD/mes; autosuspend en Fly.io si el volumen es bajo |
| Gotenberg comprometido | Alto | Sin datos en reposo, sin red saliente, renovación de contenedor `--libreoffice-restart-after=200`, imagen pineada por digest en producción |

---

## 14. Fase 2 (referencia futura, no implementar)

Sustituir el gateway por renderizado **en el dispositivo** con Apryse SDK (`PdftronFlutter.openDocument` soporta DOCX/XLSX/PPTX tras descifrar en memoria), restaurando zero-knowledge absoluto para Office. El diseño de Fase 1 (columnas `viewer_*`, rama de preview en el visor, watermark dinámico) es compatible: Fase 2 solo cambia quién genera el documento visualizable.
