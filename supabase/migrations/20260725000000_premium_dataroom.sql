-- =============================================================================
-- KRIPTONSHARE DDL: EXTENSIÓN PREMIUM, CARPETAS (DATA ROOMS) Y JOURNEY TELEMETRY
-- Fecha: 2026-07-25
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. ACTUALIZACIÓN DE TABLA DE USUARIOS PARA ALMACENAMIENTO DINÁMICO
-- -----------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS total_storage_used_bytes BIGINT DEFAULT 0
    CHECK (total_storage_used_bytes >= 0),
  ADD COLUMN IF NOT EXISTS max_storage_bytes BIGINT DEFAULT 1073741824
    CHECK (max_storage_bytes >= 0);

-- Alias de compatibilidad: si existe la columna legacy max_storage_premium_bytes,
-- sincronizarla con max_storage_bytes para usuarios premium.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users'
      AND column_name = 'max_storage_premium_bytes'
  ) THEN
    UPDATE public.users
    SET max_storage_bytes = COALESCE(max_storage_premium_bytes, max_storage_bytes)
    WHERE subscription_tier IN ('premium', 'enterprise');
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 2. TABLA DE CARPETAS VIRTUALES (DATA ROOMS)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.folders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(trim(name)) > 0),
  description TEXT,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_folders_owner
  ON public.folders(owner_id) WHERE is_deleted = FALSE;

-- -----------------------------------------------------------------------------
-- 3. ACTUALIZACIÓN DE LA TABLA FILES PARA VINCULACIÓN A CARPETAS
-- -----------------------------------------------------------------------------
ALTER TABLE public.files
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS folder_id UUID REFERENCES public.folders(id)
    ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_files_folder
  ON public.files(folder_id) WHERE is_deleted = FALSE;

-- -----------------------------------------------------------------------------
-- 4. ACTUALIZACIÓN DE SHARE_LINKS PARA SOPORTAR CARPETAS COMPLETAS
-- -----------------------------------------------------------------------------
ALTER TABLE public.share_links
  ADD COLUMN IF NOT EXISTS folder_id UUID REFERENCES public.folders(id)
    ON DELETE CASCADE;

-- Hacer file_id nullable solo si aún es NOT NULL.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'share_links'
      AND column_name = 'file_id' AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE public.share_links ALTER COLUMN file_id DROP NOT NULL;
  END IF;
END $$;

-- Restricción Check: un enlace comparte un archivo O una carpeta, no ambos ni ninguno.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'share_links'
      AND constraint_name = 'chk_share_link_target'
  ) THEN
    ALTER TABLE public.share_links
      ADD CONSTRAINT chk_share_link_target CHECK (
        (file_id IS NOT NULL AND folder_id IS NULL) OR
        (file_id IS NULL AND folder_id IS NOT NULL)
      );
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 5. TABLA DE TELEMETRÍA DE VIAJE (JOURNEY ANALYTICS)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.journey_telemetry (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  share_link_id UUID NOT NULL REFERENCES public.share_links(id) ON DELETE CASCADE,
  file_id UUID REFERENCES public.files(id) ON DELETE SET NULL,
  recipient_email TEXT,
  recipient_ip TEXT,
  event_type TEXT NOT NULL CHECK (event_type IN
    ('lobby_enter', 'file_open', 'page_view', 'lobby_exit')),
  page_number INTEGER CHECK (page_number > 0),
  duration_ms BIGINT DEFAULT 0 CHECK (duration_ms >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.journey_telemetry
  ALTER COLUMN recipient_email SET COMPRESSION lz4;

CREATE INDEX IF NOT EXISTS brin_journey_created_at_idx
  ON public.journey_telemetry USING BRIN (created_at) WITH (pages_per_range = 64);

-- -----------------------------------------------------------------------------
-- 6. POLÍTICAS RLS OBLIGATORIAS
-- -----------------------------------------------------------------------------
ALTER TABLE public.folders ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'folders' AND policyname = 'folders_owner_select'
  ) THEN
    CREATE POLICY folders_owner_select ON public.folders
      FOR SELECT USING (auth.uid() = owner_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'folders' AND policyname = 'folders_owner_insert'
  ) THEN
    CREATE POLICY folders_owner_insert ON public.folders
      FOR INSERT WITH CHECK (auth.uid() = owner_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'folders' AND policyname = 'folders_owner_update'
  ) THEN
    CREATE POLICY folders_owner_update ON public.folders
      FOR UPDATE USING (auth.uid() = owner_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'folders' AND policyname = 'folders_owner_delete'
  ) THEN
    CREATE POLICY folders_owner_delete ON public.folders
      FOR DELETE USING (auth.uid() = owner_id);
  END IF;
END $$;

ALTER TABLE public.journey_telemetry ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'journey_telemetry' AND policyname = 'telemetry_owner_read'
  ) THEN
    CREATE POLICY telemetry_owner_read ON public.journey_telemetry
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.share_links sl
          WHERE sl.id = journey_telemetry.share_link_id
            AND sl.created_by = auth.uid()
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'journey_telemetry' AND policyname = 'telemetry_recipient_insert'
  ) THEN
    CREATE POLICY telemetry_recipient_insert ON public.journey_telemetry
      FOR INSERT WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.share_links sl
          WHERE sl.id = journey_telemetry.share_link_id
            AND sl.is_active = TRUE
            AND sl.expires_at > NOW()
        )
      );
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 7. FUNCIÓN DE VALIDACIÓN MULTI-TIER (REFACTORIZADA)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_upload_limits(
  p_user_id UUID,
  p_file_size INTEGER,
  p_is_folder_upload BOOLEAN DEFAULT FALSE
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
  SELECT subscription_tier, monthly_links_generated, max_links_monthly,
         max_file_size_bytes, total_storage_used_bytes, max_storage_bytes
    INTO v_tier, v_links_used, v_links_max, v_file_size_max,
         v_storage_used, v_storage_max
    FROM public.users
   WHERE id = p_user_id;

  -- Tiers Premium & Enterprise
  IF v_tier IN ('premium', 'enterprise') THEN
    -- Límite individual por archivo (100 MB)
    IF p_file_size > 104857600 THEN
      RETURN QUERY SELECT FALSE,
        'Premium: El archivo excede el límite de 100 MB por documento.'::TEXT;
      RETURN;
    END IF;

    -- Capacidad global acumulada (1 GB base o más con Add-ons)
    IF (v_storage_used + p_file_size) > v_storage_max THEN
      RETURN QUERY SELECT FALSE,
        ('Premium: Capacidad de Bóveda saturada (' ||
         round((v_storage_used::numeric / 1073741824::numeric), 2) || ' GB / ' ||
         round((v_storage_max::numeric / 1073741824::numeric), 2) ||
         ' GB). Adquiere más espacio para continuar.')::TEXT;
      RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Validación Premium exitosa'::TEXT;
    RETURN;
  END IF;

  -- Tier Freemium
  IF p_is_folder_upload THEN
    RETURN QUERY SELECT FALSE,
      'Plan Gratis: La creación de Carpetas Virtuales (Data Rooms) es una función exclusiva Premium.'::TEXT;
    RETURN;
  END IF;

  IF p_file_size > 10485760 THEN -- 10 MB
    RETURN QUERY SELECT FALSE,
      'Plan Gratis: El archivo excede el límite de 10 MB.'::TEXT;
    RETURN;
  END IF;

  IF v_links_used >= 20 THEN
    RETURN QUERY SELECT FALSE,
      'Plan Gratis: Límite de 20 enlaces mensuales alcanzado.'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*)::INTEGER INTO v_active_links_count
    FROM public.share_links
   WHERE created_by = p_user_id
     AND is_active = TRUE
     AND expires_at > NOW();

  IF v_active_links_count >= 3 THEN
    RETURN QUERY SELECT FALSE,
      'Plan Gratis: Límite de 3 enlaces activos simultáneos alcanzado.'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Validación Freemium exitosa'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
