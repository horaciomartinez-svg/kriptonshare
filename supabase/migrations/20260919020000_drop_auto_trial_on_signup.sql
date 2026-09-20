-- =============================================================================
-- KRIPTONSHARE: Eliminar auto-trial en el registro (usuario nuevo = Free)
-- Fecha: 2026-09-19
--
-- CAUSA RAÍZ:
--   El trigger trg_users_trial (BEFORE INSERT en public.users) invocaba a
--   public.set_trial_on_signup(), que rellenaba trial_ends_at = NOW() + 14d
--   si venía NULL. Como el tier efectivo trata cualquier trial activo como
--   Premium, TODO usuario recién registrado aparecía como Premium.
--
--   Esto además hacía inutilizable la RPC start_premium_trial() de la
--   migración 20260916000000, que exige trial_ends_at IS NULL para activar
--   ("defensa contra reactivación"): el trigger ya lo había rellenado, así
--   que el trial manual desde el Profile nunca podía concederse.
--
-- DECISIÓN DE PRODUCTO:
--   El trial de 14 días NO se auto-concede en el registro. Solo se activa
--   manualmente desde el Profile vía start_premium_trial(). Un usuario nuevo
--   sin trial activado = Free (20 MB, 3 links activos, 7 días).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Eliminar el auto-trial de la creación de usuarios.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_users_trial ON public.users;
DROP FUNCTION IF EXISTS public.set_trial_on_signup();

-- -----------------------------------------------------------------------------
-- 2. Limpiar los trials auto-otorgados históricos.
--
--    Al exigir start_premium_trial() que trial_ends_at IS NULL, ningún trial
--    pudo activarse manualmente: todo trial no nulo en un usuario free es
--    auto-otorgado por el trigger. Se identifican por la firma exacta del
--    trigger (mismo now() transaccional que created_at), de modo que un trial
--    manual futuro (now() + 14d en una fecha posterior) nunca se vería afectado.
-- -----------------------------------------------------------------------------
UPDATE public.users
SET trial_ends_at = NULL
WHERE subscription_tier = 'free'
  AND trial_ends_at IS NOT NULL
  AND trial_ends_at = created_at + INTERVAL '14 days';
