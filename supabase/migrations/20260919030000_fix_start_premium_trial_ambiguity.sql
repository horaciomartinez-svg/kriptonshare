-- =============================================================================
-- KRIPTONSHARE: Fix start_premium_trial() — columna ambigua (42702)
-- Fecha: 2026-09-19
--
-- CAUSA RAÍZ:
--   El `UPDATE ... RETURNING trial_ends_at` era ambiguo: en PL/pgSQL el
--   parámetro OUT `trial_ends_at` (de RETURNS TABLE) colisiona con la columna
--   homónima de public.users. PostgreSQL abortaba con:
--     ERROR 42702: column reference "trial_ends_at" is ambiguous
--   Por eso la RPC SIEMPRE fallaba y el trial nunca se activaba (el cliente
--   capturaba la excepción y devolvía false -> "no pasa nada").
--
-- FIX:
--   `#variable_conflict use_column` al inicio del cuerpo: en caso de colisión,
--   PL/pgSQL resuelve los nombres no calificados a favor de la columna.
--
--   Además se añade la columna `code` (estable, en inglés) para que el cliente
--   pueda localizar el feedback (started/already_used/not_eligible/not_found/
--   no_session). `message` se mantiene como texto humano de respaldo.
-- =============================================================================

-- El tipo de retorno cambia (nueva columna `code`), así que hay que recrear.
DROP FUNCTION IF EXISTS public.start_premium_trial();

CREATE FUNCTION public.start_premium_trial()
RETURNS TABLE (started BOOLEAN, trial_ends_at TIMESTAMPTZ, code TEXT, message TEXT) AS $$
#variable_conflict use_column
DECLARE
    v_user_id  UUID := auth.uid();
    v_tier     TEXT;
    v_existing TIMESTAMPTZ;
    v_ends     TIMESTAMPTZ;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::TIMESTAMPTZ, 'no_session'::TEXT,
            'Sesión no válida.'::TEXT;
        RETURN;
    END IF;

    SELECT u.subscription_tier, u.trial_ends_at
    INTO v_tier, v_existing
    FROM public.users u
    WHERE u.id = v_user_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::TIMESTAMPTZ, 'not_found'::TEXT,
            'Usuario no encontrado.'::TEXT;
        RETURN;
    END IF;

    -- Solo usuarios free pueden activar la prueba.
    IF v_tier <> 'free' THEN
        RETURN QUERY SELECT FALSE, v_existing, 'not_eligible'::TEXT,
            'Tu plan ya incluye Premium.'::TEXT;
        RETURN;
    END IF;

    -- Defensa contra reactivación: si ya hubo trial (activo o expirado), no se repite.
    IF v_existing IS NOT NULL THEN
        RETURN QUERY SELECT FALSE, v_existing, 'already_used'::TEXT,
            'La prueba gratuita ya fue utilizada.'::TEXT;
        RETURN;
    END IF;

    UPDATE public.users
    SET trial_ends_at = NOW() + INTERVAL '14 days'
    WHERE id = v_user_id
    RETURNING trial_ends_at INTO v_ends;

    RETURN QUERY SELECT TRUE, v_ends, 'started'::TEXT,
        'Prueba Premium activada.'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.start_premium_trial() TO authenticated;
