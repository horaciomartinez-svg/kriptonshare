# RevenueCat Setup (Google Play / Google Cloud)

Checklist para activar compras reales en Kriptonshare. **Hasta completar estos
pasos, la app funciona en "modo simulación": las compras se resuelven
localmente y otorgan Premium en Supabase sin tocar Google Play.**

---

## Cómo funciona el feature flag

RevenueCat se activa SOLO si compilas con las DOS condiciones:

```bash
flutter run --dart-define=ENABLE_REVENUECAT=true \
            --dart-define=REVENUECAT_API_KEY=goog_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

- Si `ENABLE_REVENUECAT` es `false` (por defecto) → **mock**: suscribirse
  activa Premium directamente.
- Si `REVENUECAT_API_KEY` es vacía o el placeholder `goog_xxx...` → **mock**.
- Si RevenueCat está activado pero **falla en runtime** (billing no disponible,
  key inválida, Play sin publicar) → el notifier **cae automáticamente al
  mock** y el flujo continúa sin bloquear.

> La API key pública de RevenueCat (`goog_...`) NO es un secreto: va embebida
> en la app. Nunca pongas aquí la Service Account JSON de Google Cloud.

## Checklist

### 1. Google Cloud Console (para RevenueCat → Google Play)

1. Abre [console.cloud.google.com](https://console.cloud.google.com).
2. Usa el proyecto asociado a tu app (o crea uno).
3. **APIs y servicios → Biblioteca** → habilita **Google Play Developer API**.
4. **APIs y servicios → Credenciales → Crear credenciales → Cuenta de servicio**:
   - Nombre: `revenuecat`
   - Rol: `Service Account User` (basta).
5. Crea una **clave JSON** para esa cuenta y guárdala (NO se sube al repo).

### 2. Play Console

1. Asegúrate de que la app esté creada en Play Console.
2. **Configuración → Usuarios y permisos** → añade la cuenta de servicio como
   **Gerente de administración / Admin**. Aplica `Licencia para probar apps`.
3. **Configuración → Probadores de licencia** → añade los emails de test.
4. Sube un build a una pista **Interna** o **Cerrada** (el Release Manager de
   Play puede requerir datos de contacto y una declaración de seguridad).
5. Sin build publicado + tester con licencia, el billing SDK devuelve
   `billing_unavailable`. Este es el error que ocurría antes.
6. **Monetizar app → Productos** → crea los product IDs (deben coincidir
   EXACTAMENTE con los de RevenueCat), por ejemplo:
   - `premium_monthly_v2` ($12.99/mes, suscripción)
   - `premium_yearly_v2` ($103.99/año, suscripción)
   - `business_monthly_v2` ($29.99/mes, suscripción)
   - `business_yearly_v2` ($239.99/año, suscripción)

> ⚠️ No se usan add-ons (no existe `storage_1gb`): el almacenamiento efímero
> está incluido por plan (Premium 1 GB / Business 5 GB) y los límites se
> gestionan por tier, no por compras adicionales.

### 3. RevenueCat Dashboard

1. [app.revenuecat.com](https://app.revenuecat.com) → **Create App** →
   Platform: **Google Play**.
2. **Store settings** → pega la **Service Account JSON** del paso 1.4.
3. Toma la **Public SDK Key** que empieza por `goog_` (para Android).
4. **Offerings** → crea un offering `premium` con los productos
   `premium_monthly_v2` y `premium_yearly_v2` como **switches**.
5. **Offerings** → crea un offering `business` con los productos
   `business_monthly_v2` y `business_yearly_v2` como **switches**.
6. Activa el offering que quieras promocionar como **current**.

> ⚠️ Los tests de compra real SOLO funcionan en un build firmado subido a una
> pista de testing con los testers de licencia. Un `flutter run` en debug NO
> puede completar una compra real.

### 4. Supabase (opcional pero recomendado)

Cuando una compra real se complete, Google Play notifica a RevenueCat y éste a
tu servidor vía **webhook** (Dashboard → Integrations → Webhooks). Recomendado:

- Añade un webhook en RevenueCat que llame a tu Supabase Edge Function o
  backend para hacer `UPDATE users SET subscription_tier=...` según el
  producto: `premium_*_v2` → `premium`, `business_*_v2` → `business`.
- Sin ese webhook, una compra real NO cambia el tier en Supabase por sí sola.
  El mock, en cambio, sí lo hace localmente (a propósito).

### 5. Compilar con RevenueCat

```bash
# Build release para la pista de testing:
flutter build apk --release \
  --dart-define=ENABLE_REVENUECAT=true \
  --dart-define=REVENUECAT_API_KEY=goog_tu_public_key_aqui
```

## Errores comunes

| Error | Causa | Solución |
| --- | --- | --- |
| `billing_unavailable / Billing service is not connected` | Play no publica / sin billing habilitado / sin tester de licencia | Pasos 2.4 y 2.5 |
| `PurchaseCancelledError` | Usuario canceló la caja de compra | No es un fallo |
| `Product is not available for purchase` | Product ID no existe en Play o mal escrito | Revisa 2.6 y 3.4 |
| La app "compra" pero no da Premium | Falta webhook RevenueCat → Supabase | Paso 4 |

## Rollback

Para volver al modo simulación solo elimina los `--dart-define` al compilar.
No hay cambios de código necesarios.
