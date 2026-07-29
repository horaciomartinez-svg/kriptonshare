-- =============================================================================
-- KRIPTONSHARE: ACTUALIZACIÓN ARQUITECTURA VIRTUAL DATA ROOM (VDR)
-- Fecha: 2026-07-29 — Aditiva e idempotente. NO destructiva.
-- Cubre brechas G-04, G-08: link_type, flags Data Room, límite 30 días,
-- preferred_language, updated_at y expiración máxima por tier.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. USERS: idioma preferido (internacionalización 5 idiomas) y updated_at
-- -----------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(5) DEFAULT 'en'
    CHECK (preferred_language IN ('es', 'en', 'fr', 'de', 'pt')),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- -----------------------------------------------------------------------------
-- 2. FOLDERS: updated_at para ordenamiento Drive-like ("Última modificación")
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 3. SHARE_LINKS: tipo de enlace, funciones Data Room y tope de 30 días
-- -----------------------------------------------------------------------------
ALTER TABLE public.share_links
  ADD COLUMN IF NOT EXISTS link_type TEXT NOT NULL DEFAULT 'single_file'
    CHECK (link_type IN ('single_file', 'full_folder')),
  ADD COLUMN IF NOT EXISTS require_recipient_email BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS enable_watermark BOOLEAN DEFAULT TRUE;

-- Coherencia link_type <-> destino (refuerza el XOR existente chk_share_link_target)
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

-- -----------------------------------------------------------------------------
-- 4. FUNCIÓN: validación de expiración de enlaces por tier (30 días Premium)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 5. TRIGGER: actualización automática de cuota de almacenamiento del usuario
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 6. RLS: acceso de LECTURA pública controlada a metadatos de un enlace activo
--    (el receptor anónimo del lobby solo ve metadatos, nunca las claves KEK)
-- -----------------------------------------------------------------------------
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

-- Nota de seguridad: los campos criptográficos (salt, nonce, mac_tag,
-- aes_key_encrypted) de public.files NO se exponen al rol anon; el receptor
-- los obtiene únicamente vía Edge Function con validación de enlace activo.


-- -----------------------------------------------------------------------------
-- 7. RLS: lectura pública de carpetas y archivos a través de enlaces activos
-- -----------------------------------------------------------------------------
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
