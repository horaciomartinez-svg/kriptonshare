-- ==========================================================
-- KRIPTONSHARE Freemium Limits Update
-- Fecha: 2026-06-23
-- Objetivo: Inyectar reglas B2B de monetización directamente
--           en PostgreSQL para evitar evasión por clientes
--           modificados o llamadas API directas.
-- NOTA: Mover este archivo a supabase/migrations/ antes de aplicarlo.
-- ==========================================================

-- 1. Actualizar el valor por defecto de enlaces mensuales (20 en lugar de 50)
ALTER TABLE public.users ALTER COLUMN max_links_monthly SET DEFAULT 20;

-- 2. Sobrescribir la función de validación de límites (Inyección de Reglas B2B)
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
    active_links_count INTEGER;
BEGIN
    SELECT subscription_tier, monthly_links_generated, max_links_monthly, max_file_size_bytes
    INTO user_tier, links_used, links_max, file_size_max
    FROM users
    WHERE id = p_user_id;

    -- Bypass para usuarios Enterprise/Premium
    IF user_tier IN ('premium', 'enterprise') THEN
        RETURN QUERY SELECT TRUE, 'Premium: sin límites'::TEXT;
        RETURN;
    END IF;

    -- Validar tamaño de archivo (10 MB máximo en plan gratuito)
    IF p_file_size > file_size_max THEN
        RETURN QUERY SELECT FALSE,
            ('Archivo excede ' || (file_size_max / 1024 / 1024) || 'MB límite del plan gratuito')::TEXT;
        RETURN;
    END IF;

    -- Validar cuota mensual (máximo 20 links)
    IF links_used >= links_max THEN
        RETURN QUERY SELECT FALSE,
            ('Límite de ' || links_max || ' enlaces/mes alcanzado')::TEXT;
        RETURN;
    END IF;

    -- Validar concurrencia (máximo 3 enlaces activos simultáneos)
    SELECT count(*) INTO active_links_count
    FROM share_links
    WHERE created_by = p_user_id
      AND is_active = true
      AND expires_at > NOW();

    IF active_links_count >= 3 THEN
        RETURN QUERY SELECT FALSE,
            'Límite de 3 enlaces activos simultáneos alcanzado. Revoca un enlace anterior para continuar.'::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'OK'::TEXT;
END;
$$ LANGUAGE plpgsql;
