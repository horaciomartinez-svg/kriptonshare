-- =============================================================================
-- KRIPTONSHARE: Trial efectivo (Premium) — corrección de límites
-- Fecha: 2026-09-16
-- Cubre: §5.3, §6.3, §7.1, §7.2
--
-- CAUSA RAÍZ CORREGIDA:
--   check_upload_limits() resolvía el tier efectivo (trial = premium) pero
--   derivaba el tope de tamaño de users.max_file_size_bytes (20 MB para free),
--   por lo que un usuario en trial seguía limitado a 20 MB. Ahora los topes de
--   tamaño y storage se derivan del tier efectivo, no de la columna.
--
--   El cliente ya no escribe trial_ends_at directamente: se expone la RPC
--   SECURITY DEFINER start_premium_trial(), que solo aplica a usuarios free,
--   exige que el trial nunca se haya usado y por tanto impide reactivarlo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Activación de trial en servidor (el cliente NUNCA escribe trial_ends_at).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_premium_trial()
RETURNS TABLE (started BOOLEAN, trial_ends_at TIMESTAMPTZ, message TEXT) AS $$
DECLARE
    v_user_id  UUID := auth.uid();
    v_tier     TEXT;
    v_existing TIMESTAMPTZ;
    v_ends     TIMESTAMPTZ;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::TIMESTAMPTZ, 'Sesión no válida.'::TEXT;
        RETURN;
    END IF;

    SELECT u.subscription_tier, u.trial_ends_at
    INTO v_tier, v_existing
    FROM public.users u
    WHERE u.id = v_user_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::TIMESTAMPTZ, 'Usuario no encontrado.'::TEXT;
        RETURN;
    END IF;

    -- Solo usuarios free pueden activar la prueba.
    IF v_tier <> 'free' THEN
        RETURN QUERY SELECT FALSE, v_existing, 'Tu plan ya incluye Premium.'::TEXT;
        RETURN;
    END IF;

    -- Defensa contra reactivación: si ya hubo trial (activo o expirado), no se repite.
    IF v_existing IS NOT NULL THEN
        RETURN QUERY SELECT FALSE, v_existing,
            'La prueba gratuita ya fue utilizada.'::TEXT;
        RETURN;
    END IF;

    UPDATE public.users
    SET trial_ends_at = NOW() + INTERVAL '14 days'
    WHERE id = v_user_id
    RETURNING trial_ends_at INTO v_ends;

    RETURN QUERY SELECT TRUE, v_ends, 'Prueba Premium activada.'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.start_premium_trial() TO authenticated;

-- -----------------------------------------------------------------------------
-- 2. check_upload_limits: topes derivados del tier efectivo (trial = premium)
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
    -- Tier efectivo: business > premium > (trial activo = premium) > free
    SELECT CASE
             WHEN u.subscription_tier IN ('business', 'enterprise') THEN 'business'
             WHEN u.subscription_tier = 'premium' THEN 'premium'
             WHEN u.trial_ends_at IS NOT NULL AND u.trial_ends_at > NOW() THEN 'premium'
             ELSE 'free'
           END,
           COALESCE(u.monthly_links_generated, 0),
           COALESCE(u.max_links_monthly, 20),
           COALESCE(u.total_storage_used_bytes, 0),
           COALESCE(u.max_storage_bytes, 1073741824)
    INTO v_tier, v_links_used, v_links_max, v_storage_used, v_storage_max
    FROM public.users u
    WHERE u.id = p_user_id;

    IF v_tier IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Usuario no encontrado.'::TEXT, 'general'::TEXT;
        RETURN;
    END IF;

    -- Topes por tier efectivo (no por las columnas, que free tiene en 20 MB).
    v_file_size_max := CASE v_tier
        WHEN 'business' THEN 209715200   -- 200 MB
        WHEN 'premium'  THEN 104857600   -- 100 MB (incluye trial)
        ELSE 20971520                    -- 20 MB
    END;

    v_storage_max := CASE v_tier
        WHEN 'business' THEN 5368709120  -- 5 GB
        WHEN 'premium'  THEN 1073741824  -- 1 GB (incluye trial)
        ELSE v_storage_max               -- free: usa max_storage_bytes del usuario
    END;

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

        IF (v_storage_used + p_file_size) > v_storage_max THEN
            RETURN QUERY SELECT FALSE,
                'Capacidad de almacenamiento alcanzada.'::TEXT,
                'storage'::TEXT;
            RETURN;
        END IF;

        RETURN QUERY SELECT TRUE, 'Validación exitosa'::TEXT, NULL::TEXT;
        RETURN;
    END IF;

    -- Premium / Business: validar almacenamiento (links ilimitados)
    IF (v_storage_used + p_file_size) > v_storage_max THEN
        RETURN QUERY SELECT FALSE,
            ('Capacidad de almacenamiento alcanzada. Límite de ' || (v_storage_max / 1073741824) || ' GB.')::TEXT,
            'storage'::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Validación exitosa'::TEXT, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- -----------------------------------------------------------------------------
-- 3. validate_share_link_expiration: tier efectivo (trial = premium), por
--    consistencia contractual §7.1.
-- -----------------------------------------------------------------------------
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
    -- Tier efectivo: durante el trial, el usuario free disfruta Premium.
    SELECT CASE
             WHEN u.subscription_tier IN ('business', 'enterprise') THEN 'business'
             WHEN u.subscription_tier = 'premium' THEN 'premium'
             WHEN u.trial_ends_at IS NOT NULL AND u.trial_ends_at > NOW() THEN 'premium'
             ELSE 'free'
           END
    INTO v_tier
    FROM public.users u WHERE u.id = p_user_id;

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
