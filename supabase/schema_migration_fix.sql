-- ==========================================================
-- KRIPTONSHARE: Migración de corrección de schema faltante
-- ==========================================================
-- Ejecutar este SQL en Supabase SQL Editor si la tabla files,
-- share_links o users no tienen todas las columnas definidas
-- en schema.sql.
--
-- NOTA: Usa ADD COLUMN IF NOT EXISTS para no afectar datos
-- existentes.

-- ------------------------------------------------------------
-- 1. Tabla users: columnas opcionales con valores por defecto
-- ------------------------------------------------------------
ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS subscription_tier TEXT NOT NULL DEFAULT 'free'
        CHECK (subscription_tier IN ('free', 'premium', 'enterprise')),
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS monthly_links_generated INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS monthly_links_reset_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS max_file_size_bytes BIGINT DEFAULT 10485760,
    ADD COLUMN IF NOT EXISTS max_links_monthly INTEGER DEFAULT 50,
    ADD COLUMN IF NOT EXISTS watermark_dynamic BOOLEAN DEFAULT FALSE;

-- ------------------------------------------------------------
-- 2. Tabla files: asegurar todas las columnas del schema
-- ------------------------------------------------------------
ALTER TABLE public.files
    ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ADD COLUMN IF NOT EXISTS owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS original_filename TEXT NOT NULL,
    ADD COLUMN IF NOT EXISTS file_size_bytes INTEGER NOT NULL CHECK (file_size_bytes > 0),
    ADD COLUMN IF NOT EXISTS mime_type TEXT NOT NULL,
    ADD COLUMN IF NOT EXISTS storage_provider TEXT NOT NULL DEFAULT 'r2',
    ADD COLUMN IF NOT EXISTS bucket_name TEXT NOT NULL DEFAULT 'kriptonshare-ephemeral',
    ADD COLUMN IF NOT EXISTS storage_object_key UUID NOT NULL UNIQUE,
    ADD COLUMN IF NOT EXISTS aes_key_encrypted BYTEA NOT NULL DEFAULT '\x',
    ADD COLUMN IF NOT EXISTS salt BYTEA NOT NULL DEFAULT '\x',
    ADD COLUMN IF NOT EXISTS nonce BYTEA NOT NULL DEFAULT '\x',
    ADD COLUMN IF NOT EXISTS mac_tag BYTEA NOT NULL DEFAULT '\x',
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '72 hours',
    ADD COLUMN IF NOT EXISTS max_downloads INTEGER DEFAULT 5,
    ADD COLUMN IF NOT EXISTS downloads_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active'
        CHECK (status IN ('active', 'expired', 'revoked', 'consumed'));

-- Si la tabla files ya existe pero sin algunas columnas, los defaults anteriores
-- permiten completarlas. Sin embargo, los registros existentes con valores default
-- (como '\x' en campos criptográficos) no serán válidos. Esta migración es para
-- habilitar el schema; los archivos existentes previos probablemente deban eliminarse
-- o recrearse.

-- Índices útiles
CREATE INDEX IF NOT EXISTS idx_files_expiry ON public.files(expires_at, status);
CREATE INDEX IF NOT EXISTS idx_files_owner ON public.files(owner_id, created_at DESC);

-- ------------------------------------------------------------
-- 3. Tabla share_links: asegurar todas las columnas
-- ------------------------------------------------------------
ALTER TABLE public.share_links
    ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ADD COLUMN IF NOT EXISTS file_id UUID NOT NULL REFERENCES public.files(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS pre_signed_url_hash TEXT,
    ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '72 hours',
    ADD COLUMN IF NOT EXISTS access_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS recipient_email TEXT,
    ADD COLUMN IF NOT EXISTS recipient_ip_cidr INET,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_links_owner ON public.share_links(created_by, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_links_file ON public.share_links(file_id);
CREATE INDEX IF NOT EXISTS idx_links_active ON public.share_links(is_active, expires_at);

-- ------------------------------------------------------------
-- 4. Recrear funciones RPC de prueba E2E
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_shared_file_metadata(p_link_id UUID)
RETURNS TABLE (
    id UUID,
    owner_id UUID,
    original_filename TEXT,
    file_size_bytes INTEGER,
    mime_type TEXT,
    storage_provider TEXT,
    bucket_name TEXT,
    storage_object_key UUID,
    aes_key_encrypted BYTEA,
    salt BYTEA,
    nonce BYTEA,
    mac_tag BYTEA,
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
        f.aes_key_encrypted,
        f.salt,
        f.nonce,
        f.mac_tag,
        f.created_at,
        f.expires_at,
        f.max_downloads,
        f.downloads_count,
        f.status,
        sl.id AS link_id,
        sl.expires_at AS link_expires_at,
        sl.recipient_email,
        sl.is_active
    FROM public.share_links sl
    JOIN public.files f ON f.id = sl.file_id
    WHERE sl.id = p_link_id
      AND sl.is_active = TRUE
      AND sl.expires_at > NOW()
      AND f.status = 'active'
      AND f.expires_at > NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_link_access_count(p_link_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.share_links
    SET access_count = access_count + 1,
        last_accessed_at = NOW()
    WHERE id = p_link_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_file_download_count(p_file_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.files
    SET downloads_count = downloads_count + 1
    WHERE id = p_file_id;

    UPDATE public.files
    SET status = 'consumed'
    WHERE id = p_file_id
      AND downloads_count >= max_downloads
      AND status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------
-- 5. Políticas de Storage
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can upload to own folder'
    ) THEN
        CREATE POLICY "Users can upload to own folder"
        ON storage.objects FOR INSERT
        WITH CHECK (
            bucket_id = 'kriptonshare-ephemeral'
            AND auth.uid() IS NOT NULL
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public read for shared encrypted files'
    ) THEN
        CREATE POLICY "Public read for shared encrypted files"
        ON storage.objects FOR SELECT
        USING (
            bucket_id = 'kriptonshare-ephemeral'
        );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Owners can delete own objects'
    ) THEN
        CREATE POLICY "Owners can delete own objects"
        ON storage.objects FOR DELETE
        USING (
            bucket_id = 'kriptonshare-ephemeral'
            AND auth.uid() = owner
        );
    END IF;
END $$;

-- Verificación rápida
SELECT 'files columns:' AS info, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'files'
ORDER BY ordinal_position;
