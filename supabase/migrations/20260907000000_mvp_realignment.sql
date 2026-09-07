-- =============================================================================
-- KRIPTONSHARE: MVP REALIGNMENT — Consolidated Migration
-- Fecha: 2026-09-07
-- Cubre: §5.3 (nuevos límites), §6.5 (business tier), §7.1 (trial 14 días),
--        §8 (eliminación preview/carpetas), §11.1 (funnel_events)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. USERS: nuevo CHECK subscription_tier + trial + max_file_size_bytes default
-- -----------------------------------------------------------------------------
ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_subscription_tier_check;

ALTER TABLE public.users
  ADD CONSTRAINT users_subscription_tier_check
    CHECK (subscription_tier IN ('free', 'premium', 'business', 'enterprise'));

ALTER TABLE public.users
  ALTER COLUMN max_file_size_bytes SET DEFAULT 20971520; -- 20 MB

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ;

-- Columna max_storage_bytes ya existe (1 GB default). Eliminar columna legacy.
ALTER TABLE public.users
  DROP COLUMN IF EXISTS max_storage_premium_bytes;

-- Trigger: todo usuario nuevo recibe 14 días de trial Premium.
CREATE OR REPLACE FUNCTION public.set_trial_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.trial_ends_at IS NULL THEN
    NEW.trial_ends_at := NOW() + INTERVAL '14 days';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_trial ON public.users;
CREATE TRIGGER trg_users_trial
  BEFORE INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_trial_on_signup();

-- -----------------------------------------------------------------------------
-- 2. Migración de datos: actualizar usuarios free a 20 MB
-- -----------------------------------------------------------------------------
UPDATE public.users SET max_file_size_bytes = 20971520 WHERE subscription_tier = 'free';

-- -----------------------------------------------------------------------------
-- 3. FILES: eliminar columnas de preview Office → PDF
-- -----------------------------------------------------------------------------
ALTER TABLE public.files
  DROP COLUMN IF EXISTS viewer_object_key,
  DROP COLUMN IF EXISTS viewer_file_size_bytes,
  DROP COLUMN IF EXISTS conversion_status;

DROP INDEX IF EXISTS idx_files_viewer_object_key;

-- Eliminar políticas que dependen de folder_id ANTES de dropear la columna
-- (files_public_read_active_folder_link referenciaba files.folder_id)
DROP POLICY IF EXISTS files_public_read_active_folder_link ON public.files;

-- Eliminar columna folder_id si existe
ALTER TABLE public.files
  DROP COLUMN IF EXISTS folder_id;

-- -----------------------------------------------------------------------------
-- 4. VDR por carpetas: eliminar folders, share_links.folder_id, link_type
-- -----------------------------------------------------------------------------
-- Las políticas de folders se eliminan con el DROP ... CASCADE. Solo se
-- dropea explícitamente la política de files que dependía de files.folder_id
-- (ya eliminada en la sección 3 si folders aún existía).
DROP POLICY IF EXISTS files_public_read_active_folder_link ON public.files;

DROP TABLE IF EXISTS public.folders CASCADE;

ALTER TABLE public.share_links
  DROP CONSTRAINT IF EXISTS chk_share_link_type_coherence;

ALTER TABLE public.share_links
  DROP COLUMN IF EXISTS folder_id,
  DROP COLUMN IF EXISTS link_type;

DROP INDEX IF EXISTS idx_share_links_folder;

ALTER TABLE public.share_links
  ALTER COLUMN file_id SET NOT NULL;

-- -----------------------------------------------------------------------------
-- 5. RPCs: get_shared_file_metadata y get_received_files (sin preview columns)
-- -----------------------------------------------------------------------------
-- Retorno distinto al de la fase Office: hay que DROP antes de CREATE.
DROP FUNCTION IF EXISTS public.get_shared_file_metadata(p_link_id UUID);
CREATE OR REPLACE FUNCTION public.get_shared_file_metadata(p_link_id UUID)
RETURNS TABLE (
    id UUID, owner_id UUID, original_filename TEXT,
    file_size_bytes INTEGER, mime_type TEXT,
    storage_provider TEXT, bucket_name TEXT, storage_object_key UUID,
    created_at TIMESTAMPTZ, expires_at TIMESTAMPTZ,
    max_downloads INTEGER, downloads_count INTEGER, status TEXT,
    link_id UUID, link_expires_at TIMESTAMPTZ,
    recipient_email TEXT, is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT f.id, f.owner_id, f.original_filename, f.file_size_bytes, f.mime_type,
           f.storage_provider, f.bucket_name, f.storage_object_key,
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

DROP FUNCTION IF EXISTS public.get_received_files();
CREATE OR REPLACE FUNCTION public.get_received_files()
RETURNS TABLE (
    id UUID, owner_id UUID, original_filename TEXT,
    file_size_bytes INTEGER, mime_type TEXT,
    storage_provider TEXT, bucket_name TEXT, storage_object_key UUID,
    created_at TIMESTAMPTZ, expires_at TIMESTAMPTZ,
    max_downloads INTEGER, downloads_count INTEGER, status TEXT,
    link_id UUID, link_expires_at TIMESTAMPTZ,
    recipient_email TEXT, is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id, f.owner_id, f.original_filename, f.file_size_bytes, f.mime_type,
        f.storage_provider, f.bucket_name, f.storage_object_key,
        f.created_at, f.expires_at, f.max_downloads, f.downloads_count, f.status,
        sl.id AS link_id, sl.expires_at AS link_expires_at,
        sl.recipient_email, sl.is_active
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

-- -----------------------------------------------------------------------------
-- 6. RPCs: check_upload_limits y validate_share_link_expiration con tier efectivo
-- -----------------------------------------------------------------------------
-- Firma previa usaba p_file_size INTEGER: dropear para no dejar dos overloads.
DROP FUNCTION IF EXISTS public.check_upload_limits(p_user_id UUID, p_file_size INTEGER);
DROP FUNCTION IF EXISTS public.check_upload_limits(p_user_id UUID, p_file_size BIGINT);
CREATE OR REPLACE FUNCTION public.check_upload_limits(
    p_user_id UUID,
    p_file_size BIGINT
)
RETURNS TABLE (
    can_upload BOOLEAN,
    message TEXT,
    reason_code TEXT
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
    -- Tier efectivo: trial = premium
    SELECT CASE
             WHEN subscription_tier IN ('business', 'enterprise') THEN 'business'
             WHEN subscription_tier = 'premium' THEN 'premium'
             WHEN trial_ends_at IS NOT NULL AND trial_ends_at > NOW() THEN 'premium'
             ELSE 'free'
           END
    INTO v_tier
    FROM public.users WHERE id = p_user_id;

    SELECT COALESCE(monthly_links_generated, 0),
           COALESCE(max_links_monthly, 20),
           COALESCE(max_file_size_bytes, 20971520),
           COALESCE(total_storage_used_bytes, 0),
           COALESCE(max_storage_bytes, 1073741824)
    INTO v_links_used, v_links_max, v_file_size_max, v_storage_used, v_storage_max
    FROM public.users WHERE id = p_user_id;

    IF p_file_size > v_file_size_max THEN
        RETURN QUERY SELECT FALSE,
            ('El archivo excede el límite de ' || (v_file_size_max / 1048576) || ' MB.')::TEXT,
            'file_size'::TEXT;
        RETURN;
    END IF;

    -- Free: validar cuotas mensuales y concurrencia de 3 links activos
    IF v_tier = 'free' THEN
        IF v_links_used >= v_links_max THEN
            RETURN QUERY SELECT FALSE,
                ('Límite de ' || v_links_max || ' enlaces mensuales alcanzado.')::TEXT,
                'monthly_quota'::TEXT;
            RETURN;
        END IF;

        SELECT COUNT(*)::INTEGER INTO v_active_links_count
        FROM public.share_links
        WHERE created_by = p_user_id
          AND is_active = TRUE
          AND expires_at > NOW();

        IF v_active_links_count >= 3 THEN
            RETURN QUERY SELECT FALSE,
                'Límite de 3 enlaces activos simultáneos alcanzado.'::TEXT,
                'active_links'::TEXT;
            RETURN;
        END IF;

        -- Verificar almacenamiento (free: sin cuota adicional, pero validamos que no supere el máximo)
        IF (v_storage_used + p_file_size) > v_storage_max THEN
            RETURN QUERY SELECT FALSE,
                'Capacidad de almacenamiento alcanzada.'::TEXT,
                'storage'::TEXT;
            RETURN;
        END IF;

        RETURN QUERY SELECT TRUE, 'Validación exitosa'::TEXT, NULL::TEXT;
        RETURN;
    END IF;

    -- Premium / Business: validar almacenamiento
    IF (v_storage_used + p_file_size) > v_storage_max THEN
        RETURN QUERY SELECT FALSE,
            ('Capacidad de almacenamiento alcanzada. Límite de ' || (v_storage_max / 1073741824) || ' GB.')::TEXT,
            'storage'::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Validación exitosa'::TEXT, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP FUNCTION IF EXISTS public.validate_share_link_expiration(p_user_id UUID, p_expires_at TIMESTAMPTZ);
CREATE OR REPLACE FUNCTION public.validate_share_link_expiration(
    p_user_id UUID,
    p_expires_at TIMESTAMPTZ
)
RETURNS TABLE (is_valid BOOLEAN, message TEXT) AS $$
DECLARE
    v_tier TEXT;
    v_max_freemium TIMESTAMPTZ := NOW() + INTERVAL '168 hours';
    v_max_premium  TIMESTAMPTZ := NOW() + INTERVAL '30 days';
    v_max_business TIMESTAMPTZ := NOW() + INTERVAL '60 days';
BEGIN
    -- Tier efectivo
    SELECT CASE
             WHEN subscription_tier IN ('business', 'enterprise') THEN 'business'
             WHEN subscription_tier = 'premium' THEN 'premium'
             WHEN trial_ends_at IS NOT NULL AND trial_ends_at > NOW() THEN 'premium'
             ELSE 'free'
           END
    INTO v_tier
    FROM public.users WHERE id = p_user_id;

    IF p_expires_at <= NOW() THEN
        RETURN QUERY SELECT FALSE, 'La fecha de expiración debe ser futura.'::TEXT;
        RETURN;
    END IF;

    IF v_tier = 'business' THEN
        IF p_expires_at > v_max_business THEN
            RETURN QUERY SELECT FALSE,
                'Business: La expiración máxima de un enlace es de 60 días.'::TEXT;
            RETURN;
        END IF;
        RETURN QUERY SELECT TRUE, 'Expiración Business válida (<= 60 días).'::TEXT;
        RETURN;
    END IF;

    IF v_tier = 'premium' THEN
        IF p_expires_at > v_max_premium THEN
            RETURN QUERY SELECT FALSE,
                'Premium: La expiración máxima de un enlace es de 30 días.'::TEXT;
            RETURN;
        END IF;
        RETURN QUERY SELECT TRUE, 'Expiración Premium válida (<= 30 días).'::TEXT;
        RETURN;
    END IF;

    -- Free
    IF p_expires_at > v_max_freemium THEN
        RETURN QUERY SELECT FALSE,
            'Plan Gratis: La expiración máxima de un enlace es de 7 días.'::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Expiración Freemium válida (<= 7 días).'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- 7. funnel_events: tabla de métricas de conversión
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.funnel_events (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'signup_completed',
        'first_link_created',
        'first_recipient_view',
        'paywall_shown',
        'paywall_cta_clicked',
        'paywall_dismissed',
        'checkout_started',
        'purchase_completed',
        'trial_started',
        'trial_expired'
    )),
    trigger TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.funnel_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS funnel_events_insert_own ON public.funnel_events;
CREATE POLICY funnel_events_insert_own ON public.funnel_events
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS funnel_events_select_own ON public.funnel_events;
CREATE POLICY funnel_events_select_own ON public.funnel_events
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() IS NULL);

CREATE INDEX IF NOT EXISTS idx_funnel_events_type_time
  ON public.funnel_events(event_type, created_at);

-- RPC: log_first_recipient_view (SECURITY DEFINER — inserta en nombre del owner)
DROP FUNCTION IF EXISTS public.log_first_recipient_view(p_link_id UUID);
CREATE OR REPLACE FUNCTION public.log_first_recipient_view(p_link_id UUID)
RETURNS VOID AS $$
DECLARE
    v_owner_id UUID;
BEGIN
    SELECT f.owner_id
    INTO v_owner_id
    FROM share_links sl
    JOIN files f ON f.id = sl.file_id
    WHERE sl.id = p_link_id
      AND sl.is_active = TRUE
      AND sl.expires_at > NOW();

    IF v_owner_id IS NOT NULL THEN
        INSERT INTO public.funnel_events (user_id, event_type)
        SELECT v_owner_id, 'first_recipient_view'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.funnel_events
            WHERE user_id = v_owner_id AND event_type = 'first_recipient_view'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
