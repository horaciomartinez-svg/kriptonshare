# App Links / Universal Links (KRIPTONSHARE)

Los links de acceso (`https://kriptonshare.com/room/<id>`) deben abrir la app
directamente si está instalada, y caer al landing (`/room/`) si no lo está.

## URIs soportadas

| Tipo | URI |
|------|-----|
| App Link / Universal Link | `https://kriptonshare.com/room/<id>` |
| Deep link (custom scheme) | `kriptonshare://room/<id>` |
| Short link | `https://kriptonshare.com/d/<id>` |

## Flujo en la app

`lib/main.dart` usa `app_links`:

- `getInitialLink()` → link que abrió la app cerrada.
- `uriLinkStream.listen(...)` → links mientras la app está en ejecución.

Ambos derivan a `_handleDeepLink`, que mapea `room` y `d` al mismo handler:

```dart
if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'room') {
  final linkId = uri.pathSegments[1];
  router.go('/room/$linkId');
}
```

El `GoRouter` (`lib/providers/router_provider.dart`) ya registra:

- `/room/:id` → `ViewerScreen(linkId: id)` (también sirve para `https://…/room/<id>`).
- `/d/:linkId` → `ViewerScreen`.

Si el usuario no está autenticado, el redirect conserva la ruta
(`/auth?redirect=<encoded>`), de forma que tras el login vuelve al room.

## Android — App Links

El manifest ya declara el intent filter con verificación automática:

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https"
        android:host="kriptonshare.com"
        android:pathPrefix="/room/" />
</intent-filter>
```

Queda fuera del repo (se sirve desde el dominio, no se commitea):

`https://kriptonshare.com/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.kriptonshare.app",
      "sha256_cert_fingerprints": [
        "SHA-256 FINGERPRINT DEL CERTIFICADO DE FIRMA (PENDING — ver TODO abajo)"
      ]
    }
  }
]
```

La verificación `autoVerify` falla hasta que se publique el fingerprint real.

> **TODO (manual):** obtener el fingerprint SHA-256 del certificado de firma
> con `keytool -printcert -jarfile app-release.apk` (o
> `keytool -list -v -keystore <keystore> -alias <alias>`), pegar el valor en
> `assetlinks.json` y servirlo en `https://kriptonshare.com/.well-known/`.

## iOS — Universal Links

`ios/Runner/Info.plist` ya declara el associated domain:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:kriptonshare.com</string>
</array>
```

Fichero fuera del repo, servido desde el dominio:

`https://kriptonshare.com/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TEAM_ID>.com.kriptonshare.app",
        "paths": ["/room/*", "/d/*"]
      }
    ]
  }
}
```

> **TODO (manual):** sustituir `<TEAM_ID>` por el Team ID real de Apple
> (Apple Developer Portal → Membership). Requerido para que iOS verifique el
> dominio tras el primer arranque con entitlements activados.

## Landing (fallback web)

Si el usuario no tiene la app instalada, el navegador abre
`https://kriptonshare.com/room/<id>`. La app Flutter Web no está destinada a
resolver ese camino; en su lugar se sirve la página estática
`web/room_landing/index.html` (CAMBIO 3c) que:

1. Lee el `<id>` de la URL.
2. Intenta abrir la app con `kriptonshare://room/<id>` (delay + `window.location`).
3. Muestra botones de tiendas (TODO: enlaces reales) y el logo de KRIPTONSHARE.

> **TODO (manual):** publicar la carpeta `web/room_landing` en el hosting de
> `kriptonshare.com` y configurar el servidor para que `/room/*` sirva
> `index.html` de esa carpeta (además de los ficheros de verificación
> `assetlinks.json` y `apple-app-site-association`).

## Verificación rápida

1. App instalada → navegar a `https://kriptonshare.com/room/<id>` desde un
   navegador: debe abrir la app (Android: `adb shell dumpsys package
   com.kriptonshare.app` para comprobar `autoVerify` state="verified").
2. Sin app instalada → el landing abre (`https://kriptonshare.com/room/<id>`).
3. Custom scheme: `adb shell am start -a android.intent.action.VIEW -d
   "kriptonshare://room/<id>"` (Android) / `xcrun simctl openurl booted
   "kriptonshare://room/<id>"` (iOS).