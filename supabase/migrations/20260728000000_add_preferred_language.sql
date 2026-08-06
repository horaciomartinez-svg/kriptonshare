-- 2026-07-28 — Add preferred_language to users (i18n/l10n v2.1)
-- Idempotente: no falla si la columna ya existe (por ejemplo, aplicada
-- previamente por la migración 20260729000000_vdr_architecture_update.sql).

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(5) DEFAULT 'en'
    CHECK (preferred_language IN ('es', 'en', 'fr', 'de', 'pt'));

COMMENT ON COLUMN public.users.preferred_language IS
  'Idioma preferido del usuario para localización (es/en/fr/de/pt).';
