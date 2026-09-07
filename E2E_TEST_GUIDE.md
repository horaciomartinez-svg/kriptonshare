# Guía de Prueba E2E — KRIPTONSHARE (MVP)

Esta guía valida el flujo completo del MVP: **un usuario sube un archivo cifrado y
otro lo abre**, incluyendo límites por plan, bloqueo de formatos Office, trial de
14 días, paywalls contextuales y telemetría de funnel. No existe conversión
Office→PDF, publicidad ni carpetas virtuales en este producto.

---

## 1. Preparar el backend en Supabase

### 1.1 Crear el bucket de Storage

1. Ve a tu proyecto de Supabase → **Storage**.
2. Crea un bucket llamado exactamente: `kriptonshare-ephemeral`.
3. Desactiva "Public" (las políticas se aplican por SQL).

### 1.2 Aplicar la migración del MVP

1. Abre **SQL Editor**.
2. Ejecuta el contenido de:
   ```
   supabase/migrations/20260907000000_mvp_realignment.sql
   ```
3. Verifica que existen las funciones:
   - `check_upload_limits`
   - `get_shared_file_metadata`
   - `get_received_files`
   - `validate_share_link_expiration`
   - `increment_link_access_count`
   - `increment_file_download_count`
   - `log_first_recipient_view` (SECURITY DEFINER)
4. Verifica el trigger que fija `trial_ends_at = now() + 14 days` para todo
   usuario nuevo (columna en `public.users`).

### 1.3 Crear los dos usuarios de prueba

1. Ve a **Authentication → Users** y crea dos usuarios manualmente:

   | Rol      | Email                        | Password          |
   |----------|------------------------------|-------------------|
   | Emisor   | `emisor@kriptonshare.test`   | `KriptonTest2026!` |
   | Receptor | `receptor@kriptonshare.test` | `KriptonTest2026!` |

2. Anota el UUID de cada uno (columna ID).
3. Abre `supabase/test_users_setup.sql`, reemplaza `<UUID_EMISOR>` y
   `<UUID_RECEPTOR>` y ejecútalo.
4. Verifica que ambos aparecen en **Table Editor → users**.
5. Confirma que ambos tienen `trial_ends_at` ≈ `now() + 14 days` (lo fija el
   trigger, nunca el cliente). Este trial les da Premium temporal sin tarjeta.

---

## 2. Compilar e instalar la app

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
```

Conecta dos dispositivos e instala:

```bash
adb devices
adb -s <ID_EMISOR> install build/app/outputs/flutter-apk/app-debug.apk
adb -s <ID_RECEPTOR> install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 3. Flujo principal

### 3.1 Emisor

1. Abre **KRIPTONSHARE** e inicia sesión como `emisor@kriptonshare.test`.
2. En el Dashboard debe aparecer el **banner de trial** (Premium por 14 días,
   sin tarjeta). Mientras el trial esté activo aplican límites premium.
3. Toca **(+)** → **Nueva subida**. Verifica que **no hay anuncios** en la
   vista de progreso ni en ninguna pantalla.
4. Selecciona un PDF o imagen `.jpg`/`.png` pequeño, ingresa una contraseña de
   cifrado (p. ej. `MiClaveSegura123`) y toca **Cifrar y generar enlace**.
5. Con trial activo, el slider de duración llega hasta **30 días**.
6. Cuando aparezca el link, compártelo con el receptor.

> El mensaje incluye dos links: `https://kriptonshare.com/room/<id>` (web/app)
> y `kriptonshare://room/<id>` (fallback directo a la app).

### 3.2 Receptor

1. Toca el link (usa el fallback `kriptonshare://` si el `https://` no abre).
2. Inicia sesión como `receptor@kriptonshare.test` si te lo pide; la app
   regresa automáticamente al link.
3. Verás **"Has recibido un archivo cifrado"**. Ingresa la misma contraseña y
   toca **Descifrar y ver**.
4. Verifica que el PDF/imagen se muestra dentro de la app.
5. (Verificación) En SQL Editor, confirma que se insertó una sola fila en
   `funnel_events`:
   ```sql
   SELECT event_type, link_id, created_at
   FROM public.funnel_events
   WHERE event_type = 'first_recipient_view'
   ORDER BY created_at DESC LIMIT 3;
   ```
   Reabre el link en otro dispositivo/sesión y confirma que **no** se duplica
   el evento (una vez por owner).

---

## 4. Límites, formatos y paywalls

### 4.1 Un `.docx` NO se sube

1. Como emisor (trial activo o no), intenta subir un `report.docx`.
2. Aparece el **diálogo bloqueante** con la lista de formatos soportados
   (PDF, imágenes, texto, video) y el consejo de convertirlo a PDF.
3. Nada se sube, nada se cifra: el archivo ni siquiera aparece en `files`.

### 4.2 Free sin trial (forzar `trial_ends_at` en el pasado)

En la DB, pon `public.users.trial_ends_at = now() - interval '1 day'` para el
emisor y recarga la app. Ahora los límites son free:

| Acción | Resultado esperado |
|--------|--------------------|
| Subir un PDF de **25 MB** | Paywall `file_size` ("File too large"); el CTA lleva a `/plans` |
| Crear el **4.º link activo** | Paywall `active_links` |
| Crear el **21.er link del mes** | Paywall `monthly_quota` |
| Slider de duración | Tope en **7 días** (168 h); moverlo más allá dispara el paywall `link_duration` |
| Subir 20 MB + llenar 20 MB × 3 activos | Paywall `storage` cuando `total_storage_used_bytes` alcanza la cuota efectiva |

Cada paywall muestra título y cuerpo distintos y registra `paywall_shown`; el
CTA registra `paywall_cta_clicked` y "Ahora no" registra `paywall_dismissed`.

### 4.3 Compra mock (sin RevenueCat) de Premium y Business

En `/plans`, toca **Comprar** en Premium (mensual). Verifica:
- El tier pasa a `premium` y la cuota sube a 100 MB / slider 30 días / 1 GB.
- Se registra `purchase_completed` en `funnel_events` con `product_id`.

Repite con **Business**:
- Tier `business`: 200 MB por archivo, slider hasta **60 días**, 5 GB.
- Sube un PDF de **150 MB** → aceptado.
- La RPC acepta 60 días de caducidad y **rechaza 61**.
- Llena los 5 GB: el paywall `storage` en Business **no ofrece upgrade**,
  solo el botón para liberar espacio (borrar/expirar links).

### 4.4 Regresión: link pre-migración con archivo Office

Si queda un link antiguo cuyo `files.original_filename` es `.docx`, al abrirlo
el visor muestra la pantalla de **formato no soportado** (sin crash, sin llamar
a ningún conversor).

---

## 5. Verificación de telemetría

En SQL Editor, comprueba la secuencia esperada del funnel:

```sql
SELECT event_type, count(*)
FROM public.funnel_events
WHERE user_id = '<UUID_EMISOR>'
GROUP BY event_type ORDER BY event_type;
```

Deben aparecer, según lo ejercitado: `signup_completed`, `trial_started`,
`first_link_created`, `paywall_shown`, `paywall_cta_clicked`,
`paywall_dismissed`, `checkout_started`, `purchase_completed`,
`first_recipient_view`.

---

## 6. Validación de internacionalización (i18n/l10n)

La app soporta **es, en, fr, de, pt**. Tras cualquier cambio en `lib/l10n/*.arb`:

```bash
flutter gen-l10n
flutter analyze
flutter test
```

Flujo mínimo a validar en cada idioma (Perfil → Idioma):
- **Dashboard** (`/dashboard`): banner de trial y tarjeta de plan.
- **Nueva subida** (`/upload`): diálogo de formato no soportado.
- **Enlaces activos** (`/links`) y **visor** (`/room/:id`).
- **Planes** (`/plans`): precios, dos planes, cuatro paquetes, gauge de
  almacenamiento.
- **Paywalls** en cada trigger.

Verifica que no queden literales hardcodeadas y que fechas/tamaños respeten el
locale (p. ej. `2,5 MB` en alemán/francés).

---

## 7. Limpieza post-prueba

```sql
DELETE FROM public.funnel_events WHERE user_id IN (
  SELECT id FROM auth.users WHERE email LIKE '%@kriptonshare.test'
);
DELETE FROM share_links WHERE created_by IN (
  SELECT id FROM auth.users WHERE email LIKE '%@kriptonshare.test'
);
DELETE FROM files WHERE owner_id IN (
  SELECT id FROM auth.users WHERE email LIKE '%@kriptonshare.test'
);
DELETE FROM public.users WHERE email LIKE '%@kriptonshare.test';
```

Luego elimina los usuarios desde **Authentication → Users**.

---

## 8. Solución de problemas

| Síntoma | Posible causa | Solución |
|---------|---------------|----------|
| "Enlace inválido, expirado o revocado" | El link caducó o se revocó | Crea un nuevo link. |
| "Contraseña incorrecta o archivo corrupto" | La contraseña no coincide | Usa exactamente la misma contraseña. |
| La app no abre el link `https://` | Android App Links sin verificar | Usa `kriptonshare://room/<id>` como fallback. |
| El `.docx` sí se sube | Build viejo con la función de conversión | Reconstruye la app; los Office deben bloquearse en origen |
| Aparecen anuncios | Build viejo | `flutter pub get` y rebuild; no debe quedar SDK de publicidad en `pubspec.yaml` |
| Trial no asigna Premium | Trigger no aplicado | Verifica la migración del MVP y que `trial_ends_at` esté en el futuro. |
| "Error al cargar el documento" | Falta una RPC | Re-ejecuta la migración y verifica las 7 funciones de §1.2. |
