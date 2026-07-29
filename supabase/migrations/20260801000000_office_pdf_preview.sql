-- ==========================================================
-- FASE 1: Vista previa PDF para documentos Microsoft Office
-- Agrega columnas de preview a files y expone nuevas RPCs.
-- ==========================================================

ALTER TABLE files
  ADD COLUMN IF NOT EXISTS viewer_object_key UUID,
  ADD COLUMN IF NOT EXISTS viewer_file_size_bytes INTEGER
      CHECK (viewer_file_size_bytes IS NULL OR viewer_file_size_bytes > 0),
  ADD COLUMN IF NOT EXISTS conversion_status TEXT NOT NULL DEFAULT 'none'
      CHECK (conversion_status IN ('none', 'pending', 'ready', 'failed'));

CREATE UNIQUE INDEX IF NOT EXISTS idx_files_viewer_object_key
  ON files(viewer_object_key) WHERE viewer_object_key IS NOT NULL;

-- Metadata del archivo compartido (incluye preview). SECURITY DEFINER:
-- valida que el link exista, esté activo y no expirado; no requiere RLS del receptor.
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

-- Listado de archivos recibidos por el usuario autenticado,
-- ahora con columnas de preview Office.
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
    viewer_object_key UUID,
    viewer_file_size_bytes INTEGER,
    conversion_status TEXT,
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

-- Incrementa el contador de accesos de un share_link.
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

-- Incrementa el contador de descargas de un archivo.
DROP FUNCTION IF EXISTS increment_file_download_count(p_file_id UUID);
CREATE OR REPLACE FUNCTION increment_file_download_count(p_file_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE files
    SET downloads_count = downloads_count + 1
    WHERE id = p_file_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
