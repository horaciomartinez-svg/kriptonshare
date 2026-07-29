# Guía de Prueba E2E — KRIPTONSHARE

Esta guía te lleva paso a paso para validar el flujo completo de **un usuario que sube un archivo cifrado y otro usuario lo abre en un móvil Android**.

---

## 1. Preparar el backend en Supabase

### 1.1 Crear el bucket de Storage

1. Ve a tu proyecto de Supabase → **Storage**.
2. Crea un bucket llamado exactamente: `kriptonshare-ephemeral`.
3. Desactiva la opción "Public" si te lo pregunta (las políticas las aplicaremos por SQL).

### 1.2 Ejecutar el SQL de pruebas

1. Abre **SQL Editor** en Supabase.
2. Crea una "New query".
3. Copia y pega el contenido completo de:
   ```
   supabase/test_e2e_setup.sql
   ```
4. Ejecuta el script.
5. Verifica que las funciones `get_shared_file_metadata`, `increment_link_access_count`, `increment_file_download_count` y `get_received_files` aparezcan en **Database → Functions**.

### 1.3 Crear los dos usuarios de prueba

1. Ve a **Authentication → Users**.
2. Crea dos usuarios manualmente:

   | Rol      | Email                          | Password          |
   |----------|--------------------------------|-------------------|
   | Emisor   | `emisor@kriptonshare.test`     | `KriptonTest2026!` |
   | Receptor | `receptor@kriptonshare.test`   | `KriptonTest2026!` |

3. Anota el **UUID** de cada usuario (columna ID).
4. Abre `supabase/test_users_setup.sql`, reemplaza `<UUID_EMISOR>` y `<UUID_RECEPTOR>` y ejecútalo en SQL Editor.
5. Verifica que ambos usuarios aparezcan en **Table Editor → users**.

---

## 2. Compilar e instalar la app en los dos dispositivos

### 2.1 Requisitos

- Flutter SDK 3.x instalado.
- Dos dispositivos Android con **USB debugging** activado, o transferencia manual del APK.
- `adb` disponible en PATH.

### 2.2 Comandos

Desde la raíz del proyecto ejecuta:

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```

Si `flutter analyze` muestra errores, corrígelos antes de continuar.

### 2.3 Instalar en ambos dispositivos

Conecta ambos dispositivos y ejecuta:

```bash
adb devices
adb -s <ID_DISPOSITIVO_EMISOR> install build/app/outputs/flutter-apk/app-debug.apk
adb -s <ID_DISPOSITIVO_RECEPTOR> install build/app/outputs/flutter-apk/app-debug.apk
```

O transfiere el APK manualmente vía email/Slack/etc. e instálalo en cada móvil.

---

## 3. Ejecutar la prueba

### 3.1 Dispositivo Emisor

1. Abre **KRIPTONSHARE**.
2. Inicia sesión con:
   - Email: `emisor@kriptonshare.test`
   - Password: `KriptonTest2026!`
3. En el Dashboard, toca el botón flotante **(+)**.
4. Selecciona un archivo pequeño para la prueba:
   - **Recomendado**: un PDF o una imagen `.jpg`/`.png` (ambos se visualizan directamente dentro de la app).
   - También funciona con archivos de texto.
5. Ingresa una **contraseña de cifrado** (por ejemplo: `MiClaveSegura123`).
6. (Opcional) Ingresa el email del receptor: `receptor@kriptonshare.test`.
7. Toca **"Cifrar y generar enlace"**.
   - Si seleccionas un documento Office (`.docx`, `.xlsx`, `.pptx`), la app mostrará el estado **"Generando vista previa segura..."**. El PDF de vista previa se cifra con la misma contraseña.
8. Cuando aparezca el link, toca **Compartir** y envíalo al dispositivo receptor (WhatsApp, email, SMS, etc.).

> El mensaje compartido incluye dos links:
> - `https://kriptonshare.com/room/<linkId>` (link web/app)
> - `kriptonshare://room/<linkId>` (fallback directo a la app)

### 3.2 Dispositivo Receptor

1. Recibe el mensaje con el link.
2. Toca el link. KRIPTONSHARE debería abrirse mostrando la pantalla de visor.
   - Si la app no se abre con el link `https://`, prueba con el link `kriptonshare://`.
3. Si no has iniciado sesión, la app te pedirá login. Usa:
   - Email: `receptor@kriptonshare.test`
   - Password: `KriptonTest2026!`
   - Tras el login, la app regresará automáticamente al link.
4. Verás la pantalla **"Has recibido un archivo cifrado"** con el nombre del archivo. Ingresa la **misma contraseña de cifrado** que usó el emisor (`MiClaveSegura123`).
5. Toca **"Descifrar y ver"**.
6. Verifica que el archivo se muestra correctamente:
   - PDF: se abre dentro de la app con el visor nativo.
   - Documentos Office (Word, Excel, PowerPoint): se abre el **PDF de vista previa segura** dentro de la app, con watermark del email del receptor.
   - Imagen: se ve dentro de la app.
   - Texto: se muestra en pantalla.
   - Otros formatos: aparece confirmación de descifrado y mensaje de formato protegido.

> **Nota**: Si el emisor ingresó tu email como destinatario, el archivo también aparecerá en la sección **"Archivos recibidos"** del Dashboard, para que puedas volver a abrirlo sin necesidad del link.

---

## 4. Resultado esperado

- ✅ El emisor sube el archivo y genera un link.
- ✅ El receptor abre el link en la app.
- ✅ El receptor inicia sesión y accede al visor.
- ✅ Aparece el mensaje "Has recibido un archivo cifrado".
- ✅ El archivo se descifra correctamente con la contraseña.
- ✅ El archivo se visualiza dentro de la app (PDF, imagen, texto) o se puede abrir/compartir.
- ✅ (Si hay destinatario) El archivo aparece en "Archivos recibidos" del Dashboard.

---

## 5. Solución de problemas

| Síntoma | Posible causa | Solución |
|---------|---------------|----------|
| "Enlace inválido, expirado o revocado" | El link ya caducó o se revocó | Crea un nuevo link desde el dispositivo emisor. |
| "Contraseña incorrecta o archivo corrupto" | La contraseña no coincide | Verifica que ambos usuarios usen exactamente la misma contraseña. |
| La app no se abre al tocar el link `https://` | Android App Links no verificado en debug | Usa el link `kriptonshare://room/<id>` como fallback. |
| Error al compartir un PDF descifrado | Permisos de almacenamiento | Asegúrate de que la app tenga permiso de almacenamiento en Android. |
| "Este archivo fue enviado a..." | El link tiene un destinatario y no coinciden las cuentas | Inicia sesión con el email al que fue enviado el archivo. |
| "Error al cargar el documento" | La función RPC no existe | Re-ejecuta `supabase/test_e2e_setup.sql` y verifica que no haya errores. |

---

## 6. Pruebas específicas de documentos Office (Fase 1)

### 6.1 Vista previa exitosa

1. En el dispositivo emisor, selecciona un archivo `.docx` o `.xlsx` pequeño (< 1 MB).
2. Súbelo con contraseña.
3. En Supabase, verifica que la fila de `files` tiene `conversion_status = 'ready'` y `viewer_object_key` no nulo.
4. En el dispositivo receptor, abre el link e ingresa la contraseña.
5. Verifica que el documento se visualiza como PDF paginado dentro de la app y muestra el watermark con el email del receptor.

### 6.2 Conversión fallida (fallback)

1. Apaga el servicio `conversion-gateway` (o desconecta el dispositivo emisor de internet durante la conversión).
2. Sube un `.docx`.
3. El upload debe completarse y mostrar el aviso: *"El archivo se compartió, pero no se pudo generar la vista previa."*
4. En Supabase, `conversion_status` debe ser `'failed'`.
5. El receptor verá el mensaje de formato protegido.

### 6.3 Límites por plan

- Usuario **free** con archivo de 15 MB → `canUpload()`/`check_upload_limits` lo rechaza **antes** de llamar al gateway.
- Usuario **premium** con 95 MB → conversión exitosa.

## 7. Limpieza post-prueba

Si deseas eliminar los usuarios de prueba y los archivos creados:

```sql
-- Eliminar archivos y links de los usuarios de prueba
DELETE FROM share_links WHERE created_by IN (
  SELECT id FROM auth.users WHERE email IN ('emisor@kriptonshare.test', 'receptor@kriptonshare.test')
);
DELETE FROM files WHERE owner_id IN (
  SELECT id FROM auth.users WHERE email IN ('emisor@kriptonshare.test', 'receptor@kriptonshare.test')
);
DELETE FROM public.users WHERE email IN ('emisor@kriptonshare.test', 'receptor@kriptonshare.test');
```

Luego elimina los usuarios desde **Authentication → Users**.


---

## 6. Prueba E2E — Virtual Data Room Premium

### 6.1 Prerrequisitos

- Migración `supabase/migrations/20260729000000_vdr_architecture_update.sql` aplicada en Supabase.
- Usuario emisor con `subscription_tier = 'premium'` y `max_storage_bytes = 1073741824`.
- Edge Function `billing-sync` desplegada y webhook de RevenueCat apuntando a ella (o activar **Modo prueba Premium** desde la app).

### 6.2 Flujo a validar

1. **Emisor — Activar Premium de prueba**
   - Inicia sesión como `emisor@kriptonshare.test`.
   - Ve a **Bóveda y Almacenamiento** → pulsa **Activar Premium de prueba**.
   - Confirma que la capacidad muestra **1.00 GB**.

2. **Emisor — Crear carpeta y subir lote**
   - Desde el Dashboard o menú, navega a **Mi Bóveda Data Room** (`/data-room`).
   - Pulsa **Nueva carpeta** y nómbrala `Ronda_Inversion_Serie_A`.
   - Pulsa **Subida múltiple** y selecciona 3 archivos ≤ 100 MB cada uno.
   - Verifica que la barra de progreso avanza y que al finalizar los 3 archivos aparecen en la carpeta con badge **AES-256-GCM**.

3. **Emisor — Compartir carpeta completa**
   - En la tarjeta de la carpeta, pulsa el ícono de **compartir**.
   - Selecciona expiración de **30 días**, correo receptor obligatorio y watermark activado.
   - Copia el enlace generado con formato `https://kriptonshare.com/f/<id>#<fragmento>`.

4. **Receptor — Abrir enlace de carpeta**
   - En el dispositivo receptor, abre el enlace (deep link o navegador).
   - Inicia sesión como `receptor@kriptonshare.test` si es necesario.
   - Ingresa el correo cuando el modal lo solicite.
   - Verifica que aparece el **watermark dinámico** con el email, IP y fecha sobre el lobby.

5. **Receptor — Descifrar un archivo en RAM**
   - Ingresa la contraseña del Data Room.
   - Selecciona un archivo PDF y pulsa **Abrir y descifrar en memoria RAM**.
   - Confirma que el visor `pdfrx` renderiza el documento.
   - Cambia de página y verifica que no hay errores de memoria.
   - Cierra el visor y confirma que `purgeRAM()` liberó el buffer (puedes revisar en logs).

6. **Emisor — Verificar auditoría**
   - En Supabase SQL Editor ejecuta:
     ```sql
     SELECT event_type, file_id, page_number, duration_ms, recipient_email
     FROM public.journey_telemetry
     WHERE share_link_id = '<ID_DEL_ENLACE>'
     ORDER BY created_at ASC;
     ```
   - Debes ver eventos: `lobby_enter`, `file_open`, `page_view`, `lobby_exit`.

### 6.3 Validaciones de límites

- Intenta subir un archivo de **101 MB**; la app debe rechazarlo antes de cifrar.
- Intenta crear un enlace con expiración de **31 días**; el servidor debe rechazarlo (`validate_share_link_expiration`).
- Llena la carpeta hasta superar **1 GB**; la siguiente carga debe bloquearse y ofrecer **Expandir +1 GB**.

### 6.4 Comandos de verificación local

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Si `flutter analyze` reporta errores, corrígelos antes de desplegar la migración o ejecutar la prueba E2E.
