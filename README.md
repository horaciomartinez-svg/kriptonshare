# KRIPTONSHARE

<p align="center">
  <img src="assets/logo.png" alt="KRIPTONSHARE Logo" width="200">
</p>

<p align="center">
  <strong>Plataforma de Intercambio Seguro de Archivos con Almacenamiento Efímero</strong>
</p>

<p align="center">
  <a href="#características">Características</a> •
  <a href="#stack-tecnológico">Stack</a> •
  <a href="#arquitectura">Arquitectura</a> •
  <a href="#instalación">Instalación</a> •
  <a href="#seguridad">Seguridad</a> •
  <a href="#roadmap">Roadmap</a>
</p>

---

## 📋 Descripción

**KRIPTONSHARE** es una aplicación móvil de Data Room que permite compartir documentos confidenciales de forma segura mediante una arquitectura de **almacenamiento efímero**. Cada archivo compartido tiene una vida limitada: se auto-destruye después de un tiempo configurable o número de visualizaciones, garantizando que la información sensible no permanezca indefinidamente en dispositivos de terceros.

Ideal para:
- **Due diligence** financiera y legal
- Compartir **contratos y acuerdos** confidenciales
- Distribuir **memorandos de colocación privada (PPM)**
- Intercambio de **documentos corporativos sensibles**
- Protección de **propiedad intelectual** en negociaciones

---

## ✨ Características

### 🔐 Seguridad de Nivel Empresarial

- **Cifrado de extremo a extremo** (AES-256) para todos los archivos
- **Links temporales** con expiración configurable (tiempo o vistas)
- **Protección contra screenshots** (detección y prevención)
- **Watermark dinámico** con identificador del receptor
- **Control de acceso** por email, contraseña o autenticación 2FA

### 📱 Funcionalidades Principales

- **Data Room móvil** con organización por carpetas y etiquetas
- **Visualizador seguro** con prevención de descarga directa
- **Gestión de permisos** granulares por archivo y usuario
- **Auditoría completa** de accesos y visualizaciones
- **Notificaciones en tiempo real** de actividad del Data Room
- **Dashboard de analytics** con métricas de engagement

### 🏗️ Arquitectura de Almacenamiento Efímero

- **Auto-eliminación** programada post-lectura
- **No almacenamiento local** en dispositivos del receptor
- **Streaming seguro** sin persistencia en caché
- **Revocación instantánea** de accesos por el emisor

---

## 🛠 Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| **Framework** | Flutter 3.x |
| **Lenguaje** | Dart |
| **Backend** | Supabase (PostgreSQL + Edge Functions) |
| **Autenticación** | Supabase Auth (JWT) |
| **Almacenamiento** | Supabase Storage |
| **Cifrado** | AES-256 + RSA-4096 |
| **Estado** | Provider (Riverpod en roadmap) |
| **Routing** | GoRouter |
| **UI** | Material Design 3 + Custom Theme |

---

## 🏛 Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                    CLIENTE (Flutter)                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │  Auth    │ │  File    │ │  Viewer  │            │
│  │ Provider │ │ Provider │ │ Screen   │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Crypto   │ │ Screenshot│ │ Link    │            │
│  │ Service  │ │ Service  │ │ Gauge    │            │
│  └──────────┘ └──────────┘ └──────────┘            │
└─────────────────────────────────────────────────────┘
                         │
                         │ HTTPS + WebSocket
                         ▼
┌─────────────────────────────────────────────────────┐
│                    SUPABASE CLOUD                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │  Auth    │ │ Database │ │ Storage  │            │
│  │ (JWT)    │ │(PostgreSQL)│ │ (S3)    │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│  ┌──────────┐ ┌──────────┐                         │
│  │ Realtime │ │ Edge     │                         │
│  │ (WS)     │ │ Functions│                         │
│  └──────────┘ └──────────┘                         │
└─────────────────────────────────────────────────────┘
```

### Flujo de Seguridad

1. **Upload**: Archivo cifrado con AES-256 antes de subir
2. **Storage**: Almacenamiento cifrado en Supabase Storage
3. **Link**: Generación de URL temporal con token JWT
4. **View**: Descifrado en memoria, streaming directo al visor
5. **Destroy**: Eliminación automática post-expiración

---

## 📥 Instalación

### Requisitos Previos

- Flutter SDK 3.x ([instalar](https://docs.flutter.dev/get-started/install))
- Dart SDK (incluido con Flutter)
- Android Studio / VS Code con plugins de Flutter
- Cuenta en Supabase ([crear](https://supabase.com))

### Pasos

```bash
# 1. Clonar el repositorio
git clone https://github.com/TU_USUARIO/kriptonshare.git
cd kriptonshare

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales de Supabase

# 4. Ejecutar en modo desarrollo
flutter run

# 5. Para producción
flutter build apk --release    # Android
flutter build ios --release    # iOS
```

### Configuración de Supabase

1. Crear proyecto en [Supabase](https://supabase.com)
2. Obtener `SUPABASE_URL` y `SUPABASE_ANON_KEY`
3. Configurar buckets de Storage con políticas de seguridad
4. Ejecutar migraciones SQL en `supabase/migrations/`

---

## 📖 Uso

### Crear un Data Room

1. Inicia sesión en la app
2. Ve a **"Nuevo Data Room"**
3. Sube los archivos confidenciales
4. Configura permisos de acceso
5. Genera el link de invitación seguro

### Compartir un Archivo

1. Selecciona el archivo en el Data Room
2. Toca **"Compartir"**
3. Configura:
   - Tiempo de expiración (1h, 24h, 7d, custom)
   - Número máximo de visualizaciones
   - Protección por contraseña (opcional)
4. Copia el link generado y compártelo

### Monitorear Accesos

1. Ve a **"Analytics"** en el Dashboard
2. Revisa quién accedió, cuándo y desde dónde
3. Revoca accesos si es necesario

---

## 🔒 Seguridad

### Compromisos de Seguridad

- ✅ **Cifrado en tránsito**: TLS 1.3 para todas las comunicaciones
- ✅ **Cifrado en reposo**: AES-256 para archivos almacenados
- ✅ **Zero-knowledge**: Nosotros no podemos ver tu contenido
- ✅ **Auditoría completa**: Registro de todas las acciones
- ✅ **Cumplimiento**: Diseñado para cumplir GDPR, CCPA, SOC2

### Reportar Vulnerabilidades

Si descubres una vulnerabilidad de seguridad, por favor envía un email a [security@kriptonshare.com](mailto:security@kriptonshare.com) en lugar de crear un issue público.

---

## 🗺 Roadmap

### MVP (Actual)
- [x] Data Room móvil con organización
- [x] Upload/download seguro con cifrado
- [x] Links temporales con expiración
- [x] Protección contra screenshots
- [x] Dashboard de analytics
- [x] Autenticación y autorización

### Q3 2026
- [ ] Sistema de watermark dinámico
- [ ] Integración con firmas digitales (DocuSign, Adobe Sign)
- [ ] Soporte para documentos Office y PDF con anotaciones
- [ ] Notificaciones push avanzadas
- [ ] Modo offline para documentos pre-autorizados

### Q4 2026
- [ ] Blockchain para prueba de integridad (opcional)
- [ ] Integración con sistemas ERP (SAP, Oracle)
- [ ] API pública para integraciones de terceros
- [ ] White-label para empresas
- [ ] Certificación ISO 27001

### 2027
- [ ] Soporte multi-idioma (es, en, pt, fr, de)
- [ ] Aplicación de escritorio (Windows, macOS, Linux)
- [ ] Extensión de navegador
- [ ] Marketplace de templates de Data Room

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Por favor, lee nuestra [Guía de Contribución](CONTRIBUTING.md) antes de enviar un PR.

### Cómo Contribuir

1. Fork del repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit de tus cambios (`git commit -m 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está licenciado bajo la **Licencia MIT**. Ver [LICENSE](LICENSE) para más detalles.

---

## 📞 Contacto

- **Email**: [contacto@kriptonshare.com](mailto:contacto@kriptonshare.com)
- **LinkedIn**: [KRIPTONSHARE](https://linkedin.com/company/kriptonshare)
- **Web**: [www.kriptonshare.com](https://www.kriptonshare.com)

---

<p align="center">
  <strong>🔒 Seguridad. ⚡ Velocidad. 🕐 Temporalidad.</strong>
</p>

<p align="center">
  <sub>Construido con ❤️ para proteger la información confidencial del mundo empresarial.</sub>
</p>
