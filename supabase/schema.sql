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
    max_file_size_bytes BIGINT DEFAULT 10485760,  -- 10 MB free
    max_links_monthly INTEGER DEFAULT 50,          -- 50 links/mes free
    watermark_dynamic BOOLEAN DEFAULT FALSE
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
    aes_key_encrypted BYTEA NOT NULL,
    salt BYTEA NOT NULL,
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

-- Index for expiry cleanup
CREATE INDEX idx_files_expiry ON files(expires_at, status);
CREATE INDEX idx_files_owner ON files(owner_id, created_at DESC);

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
-- FUNCTION: Check upload limits (10MB, 50 links/mes)
-- ==========================================================
CREATE OR REPLACE FUNCTION check_upload_limits(
    p_user_id UUID,
    p_file_size INTEGER
)
RETURNS TABLE (
    can_upload BOOLEAN,
    message TEXT
) AS $$
DECLARE
    user_tier TEXT;
    links_used INTEGER;
    links_max INTEGER;
    file_size_max INTEGER;
BEGIN
    SELECT subscription_tier, monthly_links_generated, max_links_monthly, max_file_size_bytes
    INTO user_tier, links_used, links_max, file_size_max
    FROM users
    WHERE id = p_user_id;

    -- Premium/Enterprise bypass
    IF user_tier IN ('premium', 'enterprise') THEN
        RETURN QUERY SELECT TRUE, 'Premium: sin límites'::TEXT;
        RETURN;
    END IF;

    -- Check file size (10MB for free)
    IF p_file_size > file_size_max THEN
        RETURN QUERY SELECT FALSE,
            ('Archivo excede ' || (file_size_max / 1024 / 1024) || 'MB límite del plan gratuito')::TEXT;
        RETURN;
    END IF;

    -- Check links limit (50/month for free)
    IF links_used >= links_max THEN
        RETURN QUERY SELECT FALSE,
            ('Límite de ' || links_max || ' enlaces/mes alcanzado')::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'OK'::TEXT;
END;
$$ LANGUAGE plpgsql;

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
