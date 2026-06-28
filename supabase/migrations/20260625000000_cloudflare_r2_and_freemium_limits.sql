-- =============================================================================
-- KRIPTONSHARE MIGRATION: FREEMIUM LIMITS & CLOUDFLARE R2 ADAPTATION
-- =============================================================================

-- 1. Actualizar valores restrictivos por defecto para nuevos usuarios registrados
ALTER TABLE public.users ALTER COLUMN max_links_monthly SET DEFAULT 20;
ALTER TABLE public.users ALTER COLUMN max_file_size_bytes SET DEFAULT 10485760; -- 10 MB estrictos

-- 2. Sobrescribir check_upload_limits con reglas de negocio institucionales
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
    file_size_max BIGINT;
    active_links_count INTEGER;
BEGIN
    SELECT subscription_tier, monthly_links_generated, max_links_monthly, max_file_size_bytes
    INTO user_tier, links_used, links_max, file_size_max
    FROM public.users
    WHERE id = p_user_id;

    -- Bypass automático para suscriptores institucionales (Premium / Enterprise)
    IF user_tier IN ('premium', 'enterprise') THEN
        RETURN QUERY SELECT TRUE, 'Bypass Premium: Sin restricciones operativas'::TEXT;
        RETURN;
    END IF;

    -- REGLA 1: Validación estricta del tamaño físico del payload (Máximo 10 MB)
    IF p_file_size > file_size_max THEN
        RETURN QUERY SELECT FALSE, 
            ('El archivo excede el límite de 10 MB establecido para el plan gratuito')::TEXT;
        RETURN;
    END IF;

    -- REGLA 2: Validación de la cuota de generación mensual (Máximo 20 enlaces)
    IF links_used >= links_max THEN
        RETURN QUERY SELECT FALSE, 
            ('Límite de ' || links_max || ' enlaces mensuales alcanzado')::TEXT;
        RETURN;
    END IF;

    -- REGLA 3: Validación de concurrencia simultánea (Máximo 3 enlaces activos vivos)
    SELECT COUNT(*)::INTEGER INTO active_links_count
    FROM public.share_links
    WHERE created_by = p_user_id 
      AND is_active = TRUE 
      AND expires_at > NOW();

    IF active_links_count >= 3 THEN
        RETURN QUERY SELECT FALSE, 
            'Límite de 3 enlaces activos simultáneos alcanzado. Revoca un Data Room anterior para continuar.'::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Validación de cuotas aprobada de forma exitosa'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
