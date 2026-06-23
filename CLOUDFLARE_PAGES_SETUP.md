# Configuración de Cloudflare Pages para KRIPTONSHARE

Esta guía configura una landing page mínima en **Cloudflare Pages** para que los links `https://kriptonshare.com/room/<id>`:

1. Abran la app Android/iOS si está instalada.
2. Muestren una página de fallback si la app no está instalada.
3. Sirvan el `assetlinks.json` necesario para Android App Links.

---

## 1. Estructura de archivos

Crea una carpeta en tu computadora con esta estructura:

```
kriptonshare-web/
├── index.html
├── _routes.json
└── .well-known/
    └── assetlinks.json
```

(El archivo `apple-app-site-association` para iOS es opcional para esta prueba; si más adelante quieres soportar iOS, avísame.)

---

## 2. Contenido de `index.html`

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>KRIPTONSHARE — Documento seguro</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0A0A0F;
      color: #E8E8E8;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
      text-align: center;
    }
    .container {
      max-width: 420px;
      width: 100%;
    }
    .logo {
      width: 72px;
      height: 72px;
      background: linear-gradient(135deg, #39FF14, #4E9B47);
      border-radius: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
      font-size: 32px;
      font-weight: 700;
      color: #0A0A0F;
    }
    h1 { font-size: 24px; margin-bottom: 8px; }
    p { color: #A0A0A0; line-height: 1.5; margin-bottom: 24px; }
    .btn {
      display: block;
      width: 100%;
      padding: 16px;
      border-radius: 12px;
      text-decoration: none;
      font-weight: 600;
      margin-bottom: 12px;
      border: none;
      cursor: pointer;
      font-size: 16px;
    }
    .btn-primary {
      background: #39FF14;
      color: #0A0A0F;
    }
    .btn-secondary {
      background: transparent;
      color: #E8E8E8;
      border: 1px solid #3A3A3A;
    }
    .footer {
      margin-top: 32px;
      font-size: 12px;
      color: #6B6B6B;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">K</div>
    <h1>Documento seguro</h1>
    <p>
      Has recibido un documento cifrado a través de KRIPTONSHARE.
      Ábrelo en la app para descifrarlo.
    </p>
    <a id="openAppBtn" class="btn btn-primary" href="#">Abrir en KRIPTONSHARE</a>
    <a class="btn btn-secondary" href="https://play.google.com/store/apps/details?id=com.kriptonshare.app">
      Descargar para Android
    </a>
    <div class="footer">
      Si no tienes la app instalada, descárgala desde la tienda.
    </div>
  </div>

  <script>
    // Extrae el linkId de la URL, ej: /room/abc-123
    const pathParts = window.location.pathname.split('/').filter(Boolean);
    const linkId = pathParts.length >= 2 && pathParts[0] === 'room' ? pathParts[1] : null;

    const openAppBtn = document.getElementById('openAppBtn');

    if (linkId) {
      const appLink = `kriptonshare://room/${linkId}`;
      openAppBtn.href = appLink;

      // Intenta abrir la app automáticamente al cargar la página
      window.location.href = appLink;

      // Si después de 1.5 segundos seguimos aquí, probablemente la app no esté instalada.
      setTimeout(() => {
        // No hacemos nada; el usuario puede tocar el botón o descargar la app.
      }, 1500);
    } else {
      openAppBtn.style.display = 'none';
      document.querySelector('p').textContent = 'Enlace inválido o expirado.';
    }
  </script>
</body>
</html>
```

---

## 3. Contenido de `_routes.json`

Este archivo hace que Cloudflare Pages sirva `index.html` para cualquier ruta `/room/*`, funcionando como una SPA.

```json
{
  "version": 1,
  "include": ["/*"],
  "exclude": ["/well-known/*"]
}
```

---

## 4. Contenido de `.well-known/assetlinks.json`

Este archivo es obligatorio para que Android abra la app directamente desde `https://kriptonshare.com/room/<id>`.

Debes reemplazar `<SHA256_DEBUG>` y `<SHA256_RELEASE>` por las huellas SHA-256 de tu certificado de firma.

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.kriptonshare.app",
    "sha256_cert_fingerprints": [
      "<SHA256_DEBUG>",
      "<SHA256_RELEASE>"
    ]
  }
}]
```

### Cómo obtener el fingerprint SHA-256

#### Para debug (el que usas ahora en desarrollo)

```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Busca la línea **SHA256:** y copia el valor, por ejemplo:

```
SHA256: A1:B2:C3:...:FF
```

Quita los dos puntos y ponlo en mayúsculas/minúsculas (no importa) en `assetlinks.json`:

```json
"sha256_cert_fingerprints": [
  "A1B2C3...FF"
]
```

#### Para release (cuando publiques en Play Store)

Usa el keystore de producción:

```bash
keytool -list -v -keystore ruta\a\tu\keystore.jks -alias tu_alias -storepass tu_password
```

---

## 5. Desplegar en Cloudflare Pages

1. Ve a [Cloudflare Dashboard](https://dash.cloudflare.com/) → **Pages**.
2. Crea un nuevo proyecto.
3. Sube la carpeta `kriptonshare-web` arrastrándola (drag & drop).
4. Cloudflare te dará una URL temporal como `https://kriptonshare.pages.dev`.
5. Ve a **Custom domains** y agrega `kriptonshare.com`.
6. Sigue las instrucciones de Cloudflare para actualizar los DNS en Namecheap.

### DNS en Namecheap (ejemplo)

En el panel de Namecheap, para el dominio `kriptonshare.com`, configura:

| Tipo | Host | Valor |
|------|------|-------|
| CNAME | @ | `kriptonshare.pages.dev` |
| CNAME | www | `kriptonshare.pages.dev` |

(O usa los registros que Cloudflare te indique exactamente.)

---

## 6. Verificar Android App Links

Una vez desplegado, abre en el navegador del móvil:

```
https://kriptonshare.com/.well-known/assetlinks.json
```

Debe mostrar el JSON correctamente.

Luego prueba tocar un link como:

```
https://kriptonshare.com/room/abc-123
```

Si todo está configurado, Android debería abrir KRIPTONSHARE directamente.

---

## 7. Nota importante para la prueba actual

Mientras configuras Cloudflare, puedes seguir probando el flujo con el link directo a la app:

```
kriptonshare://room/<id>
```

Ese link se incluye en el mensaje compartido y no requiere servidor web.
