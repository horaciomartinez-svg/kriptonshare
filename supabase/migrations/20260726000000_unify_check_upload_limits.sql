-- =============================================================================
-- KRIPTONSHARE MIGRATION: Unificar check_upload_limits
-- Fecha: 2026-07-26
-- Objetivo: Eliminar overload conflictivo (3 parámetros) y dejar una única
--           función con 2 parámetros (UUID, INTEGER) usada por el cliente.
-- =============================================================================

-- 1. Asegurar columnas de almacenamiento en users (idempotente).
ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS total_storage_used_bytes BIGINT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS max_storage_premium_bytes BIGINT DEFAULT 2147483648,
    ADD COLUMN IF NOT EXISTS max_storage_bytes BIGINT DEFAULT 1073741824;

-- Alinear el límite mensual de enlaces con el valor actual del producto.
ALTER TABLE public.users ALTER COLUMN max_links_monthly SET DEFAULT 20;

-- 2. Eliminar el overload con 3 parámetros que causaba PGRST203 en PostgREST.
DROP FUNCTION IF EXISTS public.check_upload_limits(UUID, INTEGER, BOOLEAN);

-- 3. Recrear la función canónica con 2 parámetros. Compatible con la columna
--    legacy max_storage_premium_bytes y la columna actual max_storage_bytes.
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

    -- Premium / Enterprise: validar tamaño por archivo y bóveda acumulada.
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

    -- Free: validar tamaño, cuota mensual y concurrencia de 3 links activos.
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
