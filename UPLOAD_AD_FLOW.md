# Flujo de Estado: Cifrado + Anuncio Nativo en UploadScreen

El siguiente diagrama de secuencia garantiza que el ciclo de vida del anuncio nativo coincida con el procesamiento del cifrado pesado.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as UploadScreen
    participant AdMob as Google Mobile Ads
    participant Crypto as CryptoService (AES-256)
    participant Net as Supabase

    User->>UI: Selecciona 48h en Slider + Clic "Cifrar"
    UI->>AdMob: Request NativeAd (B2B Profile)
    AdMob-->>UI: Retorna Ad Instance
    UI->>UI: Muestra ProcessingAdOverlay (Zona 1, 2, 3)
    UI->>Crypto: Ejecutar deriveKey y encryptFile (Isolate)
    Crypto-->>UI: Retorna Payload Cifrado
    UI->>UI: Actualiza Progreso (Zona de Autoridad a 60%)
    UI->>Net: Upload Cloudflare R2 / Supabase
    Net-->>UI: Retorna Link OK
    UI->>UI: Oculta AdOverlay -> Muestra Código QR y URL
```

## Descripción de zonas del overlay

1. **Zona de Autoridad (40% superior):** indica progreso de cifrado y confianza técnica.
2. **Zona de Anuncio Nativo B2B (40% central):** renderiza el `NativeAd` de AdMob con estilo `NativeTemplateStyle`.
3. **Zona de Escape (20% inferior):** upsell a KRIPTONSHARE Premium para eliminar publicidad.
