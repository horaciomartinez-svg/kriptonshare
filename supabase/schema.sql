-- ==========================================================
-- KRIPTONSHARE Supabase Schema (PostgreSQL + RLS)
-- Versión: Clean Architecture + Offline-First + Optimización
-- ==========================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "pg_partman";
CREATE EXTENSION IF NOT EXISTS "pgsodium";

-- ==========================================================
-- SUPABASE VAULT: Secretos internos (tokens R2, API keys)
-- ==========================================================
-- La extensión pgsodium crea automáticamente el esquema vault
-- y la tabla vault.secrets con Transparent Column Encryption.
-- Verificar que exista:
CREATE TABLE IF NOT EXISTS vault.secrets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    secret TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================
-- TABLE: users (managed by Supabase Auth, extended)
-- ==========================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'enterprise')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    monthly_links_generated INTEGER DEFAULT 0,
    monthly_links_reset_at TIMESTAMPTZ DEFAULT NOW(),
    max_file_size_bytes BIGINT DEFAULT 10485760,        -- 10 MB free
    max_links_monthly INTEGER DEFAULT 20,               -- 20 links/mes free
    watermark_dynamic BOOLEAN DEFAULT FALSE,
    total_storage_used_bytes BIGINT DEFAULT 0,          -- bóveda acumulada
    max_storage_premium_bytes BIGINT DEFAULT 2147483648,-- 2 GB legacy Premium
    max_storage_bytes BIGINT DEFAULT 1073741824         -- 1 GB base actual
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own data
CREATE POLICY user_self_access ON users
    FOR ALL
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Trigger: Reset monthly links counter
CREATE OR REPLACE FUNCTION reset_monthly_links()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.monthly_links_reset_at IS DISTINCT FROM OLD.monthly_links_reset_at THEN
        NEW.monthly_links_generated = 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reset_monthly_links_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION reset_monthly_links();

-- ==========================================================
-- TABLE: files (metadata only, never content)
-- ==========================================================
CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    original_filename TEXT NOT NULL,
    file_size_bytes INTEGER NOT NULL CHECK (file_size_bytes > 0),
    mime_type TEXT NOT NULL,
    storage_provider TEXT NOT NULL DEFAULT 'r2',
    bucket_name TEXT NOT NULL DEFAULT 'kriptonshare-ephemeral',
    storage_object_key UUID NOT NULL UNIQUE,
    viewer_object_key UUID,
    viewer_file_size_bytes INTEGER
        CHECK (viewer_file_size_bytes IS NULL OR viewer_file_size_bytes > 0),
    conversion_status TEXT NOT NULL DEFAULT 'none'
        CHECK (conversion_status IN ('none', 'pending', 'ready', 'failed')),
    aes_key_encrypted BYTEA NOT NULL,
    salt BYTEA NOT NULL,
    encryption_salt BYTEA NOT NULL,
    nonce BYTEA NOT NULL,
    mac_tag BYTEA NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    max_downloads INTEGER DEFAULT 5,
    downloads_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'revoked', 'consumed'))
);

-- Enable RLS
ALTER TABLE files ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own files
CREATE POLICY file_owner_access ON files
    FOR ALL
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

-- Policy: Recipients can read file metadata via their share_links
CREATE POLICY file_recipient_access ON files
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM share_links
            WHERE share_links.file_id = files.id
              AND LOWER(share_links.recipient_email) = LOWER(auth.email())
        )
    );

-- Index for expiry cleanup
CREATE INDEX idx_files_expiry ON files(expires_at, status);
CREATE INDEX idx_files_owner ON files(owner_id, created_at DESC);
CREATE UNIQUE INDEX idx_files_viewer_object_key ON files(viewer_object_key) WHERE viewer_object_key IS NOT NULL;

-- ==========================================================
-- TABLE: share_links
-- ==========================================================
CREATE TABLE IF NOT EXISTS share_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pre_signed_url_hash TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,
    recipient_email TEXT,
    recipient_ip_cidr INET,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE share_links ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own links
CREATE POLICY link_owner_access ON share_links
    FOR ALL
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

-- Policy: Recipients can see links sent to them (fallback for direct queries)
CREATE POLICY link_recipient_access ON share_links
    FOR SELECT
    USING (LOWER(recipient_email) = LOWER(auth.email()));

-- Index
CREATE INDEX idx_links_owner ON share_links(created_by, created_at DESC);
CREATE INDEX idx_links_file ON share_links(file_id);
CREATE INDEX idx_links_active ON share_links(is_active, expires_at);

-- ==========================================================
-- TABLE: chat_messages (Q&A Contextual B2B)
-- Compresión LZ4 para textos largos
-- ==========================================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    link_id UUID NOT NULL REFERENCES share_links(id) ON DELETE CASCADE,
    author_email TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Aplicar compresión rápida para textos largos (TOAST)
ALTER TABLE chat_messages ALTER COLUMN message SET COMPRESSION lz4;

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Only link participants can see messages
CREATE POLICY chat_link_access ON chat_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM share_links
            WHERE share_links.id = chat_messages.link_id
            AND (share_links.created_by = auth.uid() OR share_links.recipient_email = auth.email())
        )
    );

-- ==========================================================
-- TABLE: telemetry_events (Premium feature, basic for free)
-- OPTIMIZADO: Índice BRIN para series temporales
-- ==========================================================
CREATE TABLE IF NOT EXISTS telemetry_events (
    id BIGSERIAL PRIMARY KEY,
    link_id UUID NOT NULL REFERENCES share_links(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('page_view', 'download_start', 'download_complete', 'screenshot_blocked')),
    page_number INTEGER,
    duration_ms INTEGER NOT NULL,
    timestamp_ms BIGINT NOT NULL,
    ip_address INET,
    user_agent TEXT,
    geolocation JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE telemetry_events ENABLE ROW LEVEL SECURITY;

-- Policy: Only link owners can see their telemetry
CREATE POLICY telemetry_owner_access ON telemetry_events
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM share_links
            WHERE share_links.id = telemetry_events.link_id
            AND share_links.created_by = auth.uid()
        )
    );

-- Eliminar índice B-Tree si existe (legacy)
DROP INDEX IF EXISTS idx_telemetry_created_at;

-- Crear índice BRIN optimizado para series temporales (ahorro >99% RAM)
CREATE INDEX brin_telemetry_created_at_idx ON telemetry_events
USING BRIN (created_at) WITH (pages_per_range = 64);

-- ==========================================================
-- FUNCTION: Cleanup expired files (can be called via cron/job)
-- ==========================================================
CREATE OR REPLACE FUNCTION cleanup_expired_files()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    UPDATE files
    SET status = 'expired'
    WHERE expires_at < NOW()
    AND status = 'active';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ==========================================================
-- FUNCTION: Check upload limits (Multi-tier, firma única)
-- ==========================================================
CREATE OR REPLACE FUNCTION public.check_upload_limits(
    p_user_id UUID,
    p_file_size INTEGER
)
RETURNS TABLE (
    can_upload BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_tier TEXT;
    v_links_used INTEGER;
    v_links_max INTEGER;
    v_file_size_max BIGINT;
    v_active_links_count INTEGER;
    v_storage_used BIGINT;
    v_storage_max BIGINT;
BEGIN
    SELECT subscription_tier,
           COALESCE(monthly_links_generated, 0),
           COALESCE(max_links_monthly, 20),
           COALESCE(max_file_size_bytes, 10485760),
           COALESCE(total_storage_used_bytes, 0),
           COALESCE(max_storage_bytes, max_storage_premium_bytes, 2147483648)
    INTO v_tier, v_links_used, v_links_max, v_file_size_max, v_storage_used, v_storage_max
    FROM public.users
    WHERE id = p_user_id;

    -- Premium/Enterprise
    IF v_tier IN ('premium', 'enterprise') THEN
        IF p_file_size > v_file_size_max THEN
            RETURN QUERY SELECT FALSE,
                ('Premium: El archivo excede el límite de ' || (v_file_size_max / 1048576) || ' MB por documento.')::TEXT;
            RETURN;
        END IF;

        IF (v_storage_used + p_file_size) > v_storage_max THEN
            RETURN QUERY SELECT FALSE,
                ('Premium: Capacidad de almacenamiento saturada. Límite de ' || (v_storage_max / 1073741824) || ' GB alcanzado.')::TEXT;
            RETURN;
        END IF;

        RETURN QUERY SELECT TRUE, 'Validación Premium exitosa'::TEXT;
        RETURN;
    END IF;

    -- Free
    IF p_file_size > v_file_size_max THEN
        RETURN QUERY SELECT FALSE,
            ('Plan Gratis: El archivo excede el límite de ' || (v_file_size_max / 1048576) || ' MB.')::TEXT;
        RETURN;
    END IF;

    IF v_links_used >= v_links_max THEN
        RETURN QUERY SELECT FALSE,
            ('Plan Gratis: Límite de ' || v_links_max || ' enlaces mensuales alcanzado.')::TEXT;
        RETURN;
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_active_links_count
    FROM public.share_links
    WHERE created_by = p_user_id
      AND is_active = TRUE
      AND expires_at > NOW();

    IF v_active_links_count >= 3 THEN
        RETURN QUERY SELECT FALSE, 'Plan Gratis: Límite de 3 enlaces activos simultáneos alcanzado.'::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Validación Freemium exitosa'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================================
-- FUNCTION: Metadata of a shared file (including Office preview)
-- ==========================================================
DROP FUNCTION IF EXISTS get_shared_file_metadata(p_link_id UUID);
CREATE OR REPLACE FUNCTION get_shared_file_metadata(p_link_id UUID)
RETURNS TABLE (
    id UUID, owner_id UUID, original_filename TEXT,
    file_size_bytes INTEGER, mime_type TEXT,
    storage_provider TEXT, bucket_name TEXT, storage_object_key UUID,
    viewer_object_key UUID, viewer_file_size_bytes INTEGER,
    conversion_status TEXT,
    created_at TIMESTAMPTZ, expires_at TIMESTAMPTZ,
    max_downloads INTEGER, downloads_count INTEGER, status TEXT,
    link_id UUID, link_expires_at TIMESTAMPTZ,
    recipient_email TEXT, is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT f.id, f.owner_id, f.original_filename, f.file_size_bytes, f.mime_type,
           f.storage_provider, f.bucket_name, f.storage_object_key,
           f.viewer_object_key, f.viewer_file_size_bytes, f.conversion_status,
           f.created_at, f.expires_at, f.max_downloads, f.downloads_count, f.status,
           sl.id, sl.expires_at, sl.recipient_email, sl.is_active
    FROM share_links sl
    JOIN files f ON f.id = sl.file_id
    WHERE sl.id = p_link_id
      AND sl.is_active = TRUE
      AND sl.expires_at > NOW()
      AND f.status = 'active'
      AND f.expires_at > NOW()
      AND f.downloads_count < f.max_downloads
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================================
-- FUNCTION: Increment share_link access counter
-- ==========================================================
DROP FUNCTION IF EXISTS increment_link_access_count(p_link_id UUID);
CREATE OR REPLACE FUNCTION increment_link_access_count(p_link_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE share_links
    SET access_count = access_count + 1,
        last_accessed_at = NOW()
    WHERE id = p_link_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================================
-- FUNCTION: Increment file download counter
-- ==========================================================
DROP FUNCTION IF EXISTS increment_file_download_count(p_file_id UUID);
CREATE OR REPLACE FUNCTION increment_file_download_count(p_file_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE files
    SET downloads_count = downloads_count + 1
    WHERE id = p_file_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================================
-- FUNCTION: List files received by the authenticated user
-- ==========================================================
DROP FUNCTION IF EXISTS get_received_files();
CREATE OR REPLACE FUNCTION get_received_files()
RETURNS TABLE (
    id UUID,
    owner_id UUID,
    original_filename TEXT,
    file_size_bytes INTEGER,
    mime_type TEXT,
    storage_provider TEXT,
    bucket_name TEXT,
    storage_object_key UUID,
    created_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    max_downloads INTEGER,
    downloads_count INTEGER,
    status TEXT,
    link_id UUID,
    link_expires_at TIMESTAMPTZ,
    recipient_email TEXT,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id,
        f.owner_id,
        f.original_filename,
        f.file_size_bytes,
        f.mime_type,
        f.storage_provider,
        f.bucket_name,
        f.storage_object_key,
        f.viewer_object_key,
        f.viewer_file_size_bytes,
        f.conversion_status,
        f.created_at,
        f.expires_at,
        f.max_downloads,
        f.downloads_count,
        f.status,
        sl.id AS link_id,
        sl.expires_at AS link_expires_at,
        sl.recipient_email,
        sl.is_active
    FROM share_links sl
    JOIN files f ON f.id = sl.file_id
    WHERE LOWER(sl.recipient_email) = LOWER(auth.email())
      AND sl.is_active = TRUE
      AND sl.expires_at > NOW()
      AND f.status = 'active'
      AND f.expires_at > NOW()
    ORDER BY sl.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================================
-- CRON: Mantenimiento autónomo diario (pg_cron + pg_partman)
-- ==========================================================
-- Programar limpieza de archivos expirados todos los días a las 3:00 AM
SELECT cron.schedule('kriptonshare-cleanup', '0 3 * * *', $$SELECT cleanup_expired_files()$$);

-- ==========================================================
-- Particionamiento dinámico para tablas efímeras (pg_partman)
-- ==========================================================
-- Configurar particionamiento mensual en telemetry_events para eliminar
-- rápidamente datos antiguos sin bloat (DROP TABLE en lugar de DELETE)
SELECT partman.create_parent(
    p_parent_table := 'public.telemetry_events',
    p_control := 'created_at',
    p_type := 'native',
    p_interval := 'monthly',
    p_premake := 2,
    p_start_partition := (NOW() - interval '1 month')::text
);

-- Mantenimiento automático de particiones (crear nuevas, eliminar viejas)
SELECT cron.schedule('kriptonshare-partition-maintenance', '0 4 * * *', $$CALL partman.run_maintenance_proc()$$);

-- ==========================================================
-- STORAGE BUCKET SETUP (run via Supabase Dashboard or API)
-- ==========================================================
-- Create bucket: kriptonshare-ephemeral
-- Set RLS policies on storage objects
-- Set lifecycle policy: delete objects after 72 hours
-- Configure CORS for Flutter app access

-- ==========================================================
-- SAMPLE RLS POLICY FOR STORAGE (Supabase Storage)
-- ==========================================================
-- Users can only upload to their own path
-- Users can only download files they own or have links to

-- NOTE: Storage RLS policies must be configured via Supabase Dashboard
-- or Storage API. The following is pseudocode for reference:
--
-- CREATE POLICY "Users can upload to their own folder"
-- ON storage.objects FOR INSERT
-- USING (auth.uid() = owner);
--
-- CREATE POLICY "Users can read their own files"
-- ON storage.objects FOR SELECT
-- USING (auth.uid() = owner);


-- ==========================================================
-- VIRTUAL DATA ROOM (VDR) UPDATE — 2026-07-29
-- ==========================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(5) DEFAULT 'en'
    CHECK (preferred_language IN ('es', 'en', 'fr', 'de', 'pt')),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.folders
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_folders_touch ON public.folders;
CREATE TRIGGER trg_folders_touch
  BEFORE UPDATE ON public.folders
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_users_touch ON public.users;
CREATE TRIGGER trg_users_touch
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

ALTER TABLE public.share_links
  ADD COLUMN IF NOT EXISTS link_type TEXT NOT NULL DEFAULT 'single_file'
    CHECK (link_type IN ('single_file', 'full_folder')),
  ADD COLUMN IF NOT EXISTS require_recipient_email BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS enable_watermark BOOLEAN DEFAULT TRUE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'share_links'
      AND constraint_name = 'chk_share_link_type_coherence'
  ) THEN
    ALTER TABLE public.share_links
      ADD CONSTRAINT chk_share_link_type_coherence CHECK (
        (file_id IS NOT NULL AND link_type = 'single_file') OR
        (folder_id IS NOT NULL AND link_type = 'full_folder')
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_share_links_folder
  ON public.share_links(folder_id) WHERE is_active = TRUE;

CREATE OR REPLACE FUNCTION validate_share_link_expiration(
  p_user_id UUID,
  p_expires_at TIMESTAMPTZ
)
RETURNS TABLE (is_valid BOOLEAN, message TEXT) AS $$
DECLARE
  v_tier TEXT;
  v_max_freemium TIMESTAMPTZ := NOW() + INTERVAL '48 hours';
  v_max_premium  TIMESTAMPTZ := NOW() + INTERVAL '30 days';
BEGIN
  SELECT subscription_tier INTO v_tier FROM public.users WHERE id = p_user_id;

  IF p_expires_at <= NOW() THEN
    RETURN QUERY SELECT FALSE, 'La fecha de expiración debe ser futura.'::TEXT;
    RETURN;
  END IF;

  IF v_tier IN ('premium', 'enterprise') THEN
    IF p_expires_at > v_max_premium THEN
      RETURN QUERY SELECT FALSE,
        'Premium: La expiración máxima de un enlace es de 30 días.'::TEXT;
      RETURN;
    END IF;
    RETURN QUERY SELECT TRUE, 'Expiración Premium válida (<= 30 días).'::TEXT;
    RETURN;
  END IF;

  IF p_expires_at > v_max_freemium THEN
    RETURN QUERY SELECT FALSE,
      'Plan Gratis: La expiración máxima de un enlace es de 48 horas.'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Expiración Freemium válida (<= 48 h).'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION recalc_user_storage()
RETURNS TRIGGER AS $$
DECLARE
  v_owner UUID;
BEGIN
  v_owner := COALESCE(NEW.owner_id, OLD.owner_id);
  UPDATE public.users u
     SET total_storage_used_bytes = COALESCE((
       SELECT SUM(f.file_size_bytes)
         FROM public.files f
        WHERE f.owner_id = v_owner AND f.is_deleted = FALSE
     ), 0)
   WHERE u.id = v_owner;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_files_recalc_storage ON public.files;
CREATE TRIGGER trg_files_recalc_storage
  AFTER INSERT OR UPDATE OF file_size_bytes, is_deleted OR DELETE
  ON public.files
  FOR EACH ROW EXECUTE FUNCTION recalc_user_storage();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'share_links'
      AND policyname = 'share_links_public_read_active'
  ) THEN
    CREATE POLICY share_links_public_read_active ON public.share_links
      FOR SELECT USING (is_active = TRUE AND expires_at > NOW());
  END IF;
END $$;


-- ==========================================================
-- VDR RLS: lectura pública de carpetas y archivos vía links activos
-- ==========================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'folders'
      AND policyname = 'folders_public_read_active_link'
  ) THEN
    CREATE POLICY folders_public_read_active_link ON public.folders
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.share_links sl
          WHERE sl.folder_id = folders.id
            AND sl.is_active = TRUE
            AND sl.expires_at > NOW()
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'files'
      AND policyname = 'files_public_read_active_folder_link'
  ) THEN
    CREATE POLICY files_public_read_active_folder_link ON public.files
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.share_links sl
          WHERE sl.folder_id = files.folder_id
            AND sl.is_active = TRUE
            AND sl.expires_at > NOW()
        )
      );
  END IF;
END $$;
