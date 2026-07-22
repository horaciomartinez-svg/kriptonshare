# Configuración de Cloudflare para KRIPTONSHARE

Esta guía configura:

1. **Dominio `kriptonshare.com`** apuntando a Cloudflare (nameservers).
2. **Landing page** en `kriptonshare.com` para deep links `/room/<id>` y App Links de Android.
3. **App Flutter web** en `app.kriptonshare.com`.
4. **Cloudflare R2 CORS** para permitir peticiones desde la app web.

---

## 1. Apuntar el dominio de Namecheap a Cloudflare

### En Cloudflare
1. Ve a [dash.cloudflare.com](https://dash.cloudflare.com/) → **Add a Site**.
2. Escribe `kriptonshare.com` y selecciona el plan **Free**.
3. Cloudflare escaneará tus registros DNS actuales. Revisa que estén correctos.
4. Cloudflare te dará dos **nameservers**, por ejemplo:
   ```text
   greg.ns.cloudflare.com
   zara.ns.cloudflare.com
   ```

### En Namecheap
1. Ve a **Domain List** → selecciona `kriptonshare.com`.
2. En la pestaña **Domain** → **Nameservers**, selecciona **Custom DNS**.
3. Pega los dos nameservers que te dio Cloudflare.
4. Guarda. La propagación puede tardar de minutos a horas.

---

## 2. Estructura de proyectos en Cloudflare Pages

| Proyecto | Dominio | Propósito |
|----------|---------|-----------|
| `kriptonshare-landing` | `kriptonshare.com` | Landing page estática + App Links |
| `kriptonshare-web` | `app.kriptonshare.com` | App Flutter web completa |

---

## 3. Landing page (`kriptonshare.com`)

Los archivos de la landing están en `web_landing/` de este repositorio.

```text
web_landing/
├── index.html
├── _routes.json
└── .well-known/
    └── assetlinks.json
```

### `_routes.json`

Sirve `index.html` para cualquier ruta, funcionando como SPA:

```json
{
  "version": 1,
  "include": ["/*"],
  "exclude": ["/.well-known/*"]
}
```

### `.well-known/assetlinks.json`

Obligatorio para Android App Links. Debes reemplazar `<SHA256_DEBUG>` por la huella SHA-256 de tu certificado de firma.

#### Obtener fingerprint SHA-256 de debug (Windows)

```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Busca la línea **SHA256:**, quita los dos puntos y pégala en el JSON:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.kriptonshare.app",
    "sha256_cert_fingerprints": [
      "<SHA256_DEBUG>"
    ]
  }
}]
```

> Cuando publiques en Play Store, agrega también el SHA-256 de tu keystore de producción.

### Desplegar landing page

1. Cloudflare Dashboard → **Pages** → **Create a project** → **Upload assets**.
2. Sube la carpeta `web_landing/`.
3. Ve a **Custom domains** → agrega `kriptonshare.com`.
4. Cloudflare creará automáticamente los registros DNS necesarios.

---

## 4. App Flutter web (`app.kriptonshare.com`)

### Compilar

```bash
flutter build web --release
```

El resultado queda en `build/web/`.

### `_routes.json` para Flutter web

Crea `build/web/_routes.json` con:

```json
{
  "version": 1,
  "include": ["/*"],
  "exclude": ["/assets/*", "/.well-known/*"]
}
```

Esto permite que GoRouter maneje rutas como `/room/<id>`.

### Desplegar

1. Crea otro proyecto en **Cloudflare Pages**.
2. Sube la carpeta `build/web/` (drag & drop).
3. Ve a **Custom domains** → agrega `app.kriptonshare.com`.
4. Si no se crea automáticamente, agrega el registro DNS:
   - Tipo: `CNAME`
   - Name: `app`
   - Target: `kriptonshare-web.pages.dev`

---

## 5. DNS esperado en Cloudflare

| Tipo | Name | Target |
|------|------|--------|
| CNAME | `@` | `kriptonshare-landing.pages.dev` |
| CNAME | `www` | `kriptonshare-landing.pages.dev` |
| CNAME | `app` | `kriptonshare-web.pages.dev` |

---

## 6. Configurar CORS en Cloudflare R2

Desde el dashboard de Cloudflare R2:

1. Ve a tu bucket `kriptonshare-ephemeral`.
2. Ve a la pestaña **CORS**.
3. Agrega una regla:

```json
[
  {
    "AllowedOrigins": ["https://app.kriptonshare.com"],
    "AllowedMethods": ["GET", "PUT", "DELETE"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3000
  }
]
```

---

## 7. Verificar Android App Links

Una vez desplegado, abre en el navegador del móvil:

```text
https://kriptonshare.com/.well-known/assetlinks.json
```

Debe mostrar el JSON correctamente.

Luego prueba tocar un link como:

```text
https://kriptonshare.com/room/abc-123
```

Si todo está configurado, Android debería abrir KRIPTONSHARE directamente.

---

## 8. Notas importantes

- Mientras configuras Cloudflare, puedes seguir probando el flujo con el link directo a la app:
  ```text
  kriptonshare://room/<id>
  ```
- Para reemplazar el favicon y los iconos de la app web, sobreescribe los archivos en `web/icons/` y `web/favicon.png` con versiones redimensionadas de `assets/KRIPTONSHARE_App_Icon.png`.
- Si usas `--dart-define` para credenciales de R2/Supabase, asegúrate de pasarlos también al build web:
  ```bash
  flutter build web --release --dart-define=R2_ENDPOINT=... --dart-define=R2_ACCESS_KEY_ID=... --dart-define=R2_SECRET_ACCESS_KEY=...
  ```
