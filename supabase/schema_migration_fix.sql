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
    ADD COLUMN IF NOT EXISTS max_links_monthly INTEGER DEFAULT 20,
    ADD COLUMN IF NOT EXISTS watermark_dynamic BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS total_storage_used_bytes BIGINT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS max_storage_premium_bytes BIGINT DEFAULT 2147483648,
    ADD COLUMN IF NOT EXISTS max_storage_bytes BIGINT DEFAULT 1073741824;

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
    ADD COLUMN IF NOT EXISTS viewer_object_key UUID,
    ADD COLUMN IF NOT EXISTS viewer_file_size_bytes INTEGER
        CHECK (viewer_file_size_bytes IS NULL OR viewer_file_size_bytes > 0),
    ADD COLUMN IF NOT EXISTS conversion_status TEXT NOT NULL DEFAULT 'none'
        CHECK (conversion_status IN ('none', 'pending', 'ready', 'failed')),
    ADD COLUMN IF NOT EXISTS aes_key_encrypted BYTEA NOT NULL DEFAULT '\x',
    ADD COLUMN IF NOT EXISTS salt BYTEA NOT NULL DEFAULT '\x',
    ADD COLUMN IF NOT EXISTS encryption_salt BYTEA NOT NULL DEFAULT '\x',
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
CREATE UNIQUE INDEX IF NOT EXISTS idx_files_viewer_object_key ON public.files(viewer_object_key) WHERE viewer_object_key IS NOT NULL;

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
DROP FUNCTION IF EXISTS get_shared_file_metadata(p_link_id UUID);
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
    viewer_object_key UUID,
    viewer_file_size_bytes INTEGER,
    conversion_status TEXT,
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
        f.viewer_object_key,
        f.viewer_file_size_bytes,
        f.conversion_status,
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

DROP FUNCTION IF EXISTS increment_link_access_count(p_link_id UUID);
CREATE OR REPLACE FUNCTION increment_link_access_count(p_link_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.share_links
    SET access_count = access_count + 1,
        last_accessed_at = NOW()
    WHERE id = p_link_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS increment_file_download_count(p_file_id UUID);
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

-- ------------------------------------------------------------
-- 6. Políticas RLS para que receptores puedan ver links y metadatos de archivos
-- ------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'share_links' AND policyname = 'link_recipient_access'
    ) THEN
        CREATE POLICY "link_recipient_access"
        ON public.share_links FOR SELECT
        USING (LOWER(recipient_email) = LOWER(auth.email()));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'files' AND policyname = 'file_recipient_access'
    ) THEN
        CREATE POLICY "file_recipient_access"
        ON public.files FOR SELECT
        USING (
            EXISTS (
                SELECT 1 FROM public.share_links
                WHERE public.share_links.file_id = public.files.id
                  AND LOWER(public.share_links.recipient_email) = LOWER(auth.email())
            )
        );
    END IF;
END $$;

-- ------------------------------------------------------------
-- 7. Función RPC para listar archivos recibidos (case-insensitive)
-- ------------------------------------------------------------
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
    FROM public.share_links sl
    JOIN public.files f ON f.id = sl.file_id
    WHERE LOWER(sl.recipient_email) = LOWER(auth.email())
      AND sl.is_active = TRUE
      AND sl.expires_at > NOW()
      AND f.status = 'active'
      AND f.expires_at > NOW()
    ORDER BY sl.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------
-- 7. Función de validación de límites de upload (firma única)
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS public.check_upload_limits(UUID, INTEGER, BOOLEAN);

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


-- Verificación rápida
SELECT 'files columns:' AS info, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'files'
ORDER BY ordinal_position;


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
