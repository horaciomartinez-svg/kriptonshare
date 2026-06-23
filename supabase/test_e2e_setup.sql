-- ==========================================================
-- KRIPTONSHARE: Setup E2E para prueba "dos usuarios / un archivo"
-- ==========================================================
-- Ejecutar este archivo en el SQL Editor de Supabase antes de la prueba.

-- ------------------------------------------------------------
-- 1. Función RPC: obtener metadata de un archivo compartido
--    por link ID. Bypassa RLS mediante SECURITY DEFINER.
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
    FROM share_links sl
    JOIN files f ON f.id = sl.file_id
    WHERE sl.id = p_link_id
      AND sl.is_active = TRUE
      AND sl.expires_at > NOW()
      AND f.status = 'active'
      AND f.expires_at > NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------
-- 2. Función RPC: incrementar contador de accesos de un link
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION increment_link_access_count(p_link_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE share_links
    SET access_count = access_count + 1,
        last_accessed_at = NOW()
    WHERE id = p_link_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------
-- 3. Función RPC: incrementar contador de descargas del archivo
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION increment_file_download_count(p_file_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE files
    SET downloads_count = downloads_count + 1
    WHERE id = p_file_id;

    UPDATE files
    SET status = 'consumed'
    WHERE id = p_file_id
      AND downloads_count >= max_downloads
      AND status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------
-- 4. Políticas de Storage para el bucket de pruebas
--    Nota: asegúrate de que el bucket 'kriptonshare-ephemeral'
--    exista en Supabase Storage antes de ejecutar estas políticas.
-- ------------------------------------------------------------

-- Política: usuarios autenticados pueden subir a su propia carpeta
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

-- Política: lectura pública de objetos encriptados (seguridad en la contraseña)
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

-- Política: solo el owner puede eliminar/modificar sus objetos
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
-- 5. Función RPC: listar archivos recibidos por el usuario autenticado
--    (links donde recipient_email coincide con auth.email())
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
    WHERE sl.recipient_email = auth.email()
      AND sl.is_active = TRUE
      AND sl.expires_at > NOW()
      AND f.status = 'active'
      AND f.expires_at > NOW()
    ORDER BY sl.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------
-- 6. Tabla de telemetría de interacción con documentos
--    Se incluye aquí para que test_e2e_setup.sql sea autocontenido.
-- ------------------------------------------------------------
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

ALTER TABLE telemetry_events ENABLE ROW LEVEL SECURITY;

-- Política: cualquier usuario autenticado puede registrar eventos (receptor).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'telemetry_events' AND policyname = 'Authenticated users can insert telemetry'
    ) THEN
        CREATE POLICY "Authenticated users can insert telemetry"
        ON telemetry_events FOR INSERT
        WITH CHECK (auth.uid() IS NOT NULL);
    END IF;
END $$;

-- Política: solo el owner del link puede ver los eventos (emisor).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'telemetry_events' AND policyname = 'Telemetry owner access'
    ) THEN
        CREATE POLICY "Telemetry owner access"
        ON telemetry_events FOR SELECT
        USING (
            EXISTS (
                SELECT 1 FROM share_links
                WHERE share_links.id = telemetry_events.link_id
                AND share_links.created_by = auth.uid()
            )
        );
    END IF;
END $$;
