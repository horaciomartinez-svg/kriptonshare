-- ==========================================================
-- KRIPTONSHARE: Crear usuarios de prueba E2E
-- ==========================================================
--
-- PASO 1: Crear los usuarios en Supabase Auth
-- ----------------------------------------------------------
-- Ve a tu proyecto de Supabase → Authentication → Users.
-- Haz clic en "Add user" (o "Invitar") y crea dos usuarios:
--
--   Emisor:
--     Email:    emisor@kriptonshare.test
--     Password: KriptonTest2026!
--
--   Receptor:
--     Email:    receptor@kriptonshare.test
--     Password: KriptonTest2026!
--
-- Una vez creados, anota sus UUIDs (columna "ID" en el listado).
-- Reemplaza los placeholders <UUID_EMISOR> y <UUID_RECEPTOR>
-- en el SQL de abajo.
--
-- PASO 2: Ejecutar este SQL en SQL Editor
-- ----------------------------------------------------------
-- Asegúrate de reemplazar los UUIDs antes de ejecutar.

INSERT INTO public.users (
    id,
    email,
    subscription_tier,
    monthly_links_generated,
    monthly_links_reset_at
) VALUES
    (
        '5f6b77fb-cb06-45f5-b624-3a468eb72a17',
        'emisor@kriptonshare.test',
        'free',
        0,
        NOW()
    ),
    (
        '2dc81592-7e1c-4278-9d06-9b3cdb1f0570',
        'receptor@kriptonshare.test',
        'free',
        0,
        NOW()
    )
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    subscription_tier = EXCLUDED.subscription_tier,
    monthly_links_generated = EXCLUDED.monthly_links_generated,
    monthly_links_reset_at = EXCLUDED.monthly_links_reset_at;

-- Verificación
SELECT id, email, subscription_tier, monthly_links_generated
FROM public.users
WHERE email IN ('emisor@kriptonshare.test', 'receptor@kriptonshare.test');
