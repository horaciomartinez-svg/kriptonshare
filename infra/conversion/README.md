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
