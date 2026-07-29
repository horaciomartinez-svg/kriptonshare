-- =============================================================================
-- KRIPTONSHARE MIGRATION: SPRINT 5 MUST HAVE & MULTI-TIER PREMIUM COMPLIANCE
-- =============================================================================

-- 1. Asegurar campos en tabla users para métricas acumuladas de bóveda Premium
ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS total_storage_used_bytes BIGINT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS max_storage_premium_bytes BIGINT DEFAULT 2147483648; -- 2 GB

-- Inicializar valores para usuarios existentes que no los tengan
UPDATE public.users
SET total_storage_used_bytes = 0
WHERE total_storage_used_bytes IS NULL;

UPDATE public.users
SET max_storage_premium_bytes = 2147483648
WHERE max_storage_premium_bytes IS NULL;

-- Alinear límite de links mensuales: default 20 y forzar a usuarios Free existentes
ALTER TABLE public.users ALTER COLUMN max_links_monthly SET DEFAULT 20;
ALTER TABLE public.users ALTER COLUMN max_file_size_bytes SET DEFAULT 10485760; -- 10 MB

UPDATE public.users
SET max_links_monthly = 20
WHERE subscription_tier = 'free' AND (max_links_monthly IS NULL OR max_links_monthly > 20);

UPDATE public.users
SET max_file_size_bytes = 10485760
WHERE subscription_tier = 'free' AND (max_file_size_bytes IS NULL OR max_file_size_bytes > 10485760);

-- Usuarios Premium/Enterprise heredan 100 MB por archivo
UPDATE public.users
SET max_file_size_bytes = 104857600
WHERE subscription_tier IN ('premium', 'enterprise')
  AND (max_file_size_bytes IS NULL OR max_file_size_bytes < 104857600);

-- 2. Función e Trigger automatizado para auditar el tamaño físico de la bóveda
CREATE OR REPLACE FUNCTION update_user_storage_metrics()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.users
        SET total_storage_used_bytes = COALESCE(total_storage_used_bytes, 0) + NEW.file_size_bytes
        WHERE id = NEW.owner_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.users
        SET total_storage_used_bytes = GREATEST(0, COALESCE(total_storage_used_bytes, 0) - OLD.file_size_bytes)
        WHERE id = OLD.owner_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_manage_file_storage_metrics ON public.files;
CREATE TRIGGER trg_manage_file_storage_metrics
AFTER INSERT OR DELETE ON public.files
FOR EACH ROW EXECUTE FUNCTION update_user_storage_metrics();

-- 3. Refactorización inmutable de check_upload_limits con soporte Multi-Tier
CREATE OR REPLACE FUNCTION check_upload_limits(
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

    -- VALIDACIÓN EXCLUSIVA PARA EL PLAN PREMIUM / ENTERPRISE
    IF v_tier IN ('premium', 'enterprise') THEN
        -- Tamaño máximo por archivo Premium: 100 MB
        IF p_file_size > v_file_size_max THEN
            RETURN QUERY SELECT FALSE,
                ('Premium: El archivo excede el límite de ' || (v_file_size_max / 1048576) || ' MB por documento.')::TEXT;
            RETURN;
        END IF;

        -- Capacidad de la bóveda acumulada Premium: 2 GB
        IF (v_storage_used + p_file_size) > v_storage_max THEN
            RETURN QUERY SELECT FALSE,
                ('Premium: Capacidad de almacenamiento saturada. Límite de ' || (v_storage_max / 1073741824) || ' GB alcanzado.')::TEXT;
            RETURN;
        END IF;

        RETURN QUERY SELECT TRUE, 'Validación Premium exitosa'::TEXT;
        RETURN;
    END IF;

    -- FALLBACK RESTRICTIVO PARA EL PLAN GRATUITO
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
