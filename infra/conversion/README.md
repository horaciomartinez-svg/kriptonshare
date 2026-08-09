# Gateway de conversión Office → PDF

Servicio efímero de conversión de documentos Microsoft Office a PDF para KRIPTONSHARE Fase 1.

## Componentes

- **Gotenberg**: servicio de conversión con LibreOffice, sin puertos públicos.
- **Gateway Deno**: proxy de autenticación y límites frente a Gotenberg.

## Requisitos

- Docker y Docker Compose
- Proxy TLS (Caddy recomendado) terminando en `convert.kriptonshare.com`
- Variables de entorno de Supabase:
  - `SUPABASE_JWT_SECRET`
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`

## Desarrollo local

La app en Flutter apunta por defecto a `http://localhost:8080` (configurable con
`--dart-define=CONVERSION_SERVICE_URL=...`).

```bash
cd infra/conversion
# Crea un archivo .env (está en .gitignore, no versiones secretos) con:
#   SUPABASE_JWT_SECRET=...
#   SUPABASE_URL=https://your-project-ref.supabase.co
#   SUPABASE_SERVICE_ROLE_KEY=...
docker compose up -d
```

> **DEV_INSECURE_JWT** (solo desarrollo): por defecto `true` en `docker-compose.yml`.
> Cuando la firma HMAC no valida, el gateway acepta el token si sus claims
> (`sub`, `iss` conteniendo "supabase" y `exp > ahora`) son correctos, y registra
> por consola un JSON de depuración (claims, algoritmo, emisor, longitudes de
> clave intentadas) **sin exponer el secreto**. En producción ponerlo a `false`.

- **Android emulator**: usa `--dart-define=CONVERSION_SERVICE_URL=http://10.0.2.2:8080`
  (desde el emulador `localhost` apunta al propio emulador).
- **Flutter Web**: el gateway ya responde preflight CORS (`OPTIONS`) para que el
  navegador permita el header `Authorization`.

## Despliegue

1. Crear un VPS (o Fly.io/Railway) con Docker.
2. Copiar este directorio al host.
3. Crear un archivo `.env` con las variables anteriores (modo 600).
4. Levantar los servicios:

```bash
cd infra/conversion
docker compose up -d
```

5. Configurar DNS `convert.kriptonshare.com` → IP del host.
6. Configurar Caddy/Nginx para terminar TLS y proxy_pass a `127.0.0.1:8080`.

## Verificación

```bash
curl -X POST https://convert.kriptonshare.com/v1/convert/office \
  -H "Authorization: Bearer <supabase_jwt>" \
  -F "file=@sample.docx" \
  -o out.pdf
```

## Seguridad

- El gateway solo escucha en loopback; TLS lo termina el proxy.
- Gotenberg no tiene puertos públicos y trabaja en `tmpfs`.
- No se registra nombre de archivo, tamaño exacto ni contenido.
- Los límites por plan se resuelen en servidor desde `users.max_file_size_bytes`.
