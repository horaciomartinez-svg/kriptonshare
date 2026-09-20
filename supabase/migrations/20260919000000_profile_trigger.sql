-- ==========================================================
-- KRIPTONSHARE — Perfil automático en public.users (trigger + backfill)
-- ==========================================================
-- Motivo: la creación del perfil dependía 100% del cliente. Si el flujo
-- fallaba, el usuario quedaba autenticado pero sin fila en public.users y la
-- app lo rebotaba al login. Producción llegó a tener 4 usuarios huérfanos.
--
-- Verificado antes de escribir:
--   information_schema.columns (public.users) → solo `id` y `email` son
--   NOT NULL sin default. El resto tiene default (subscription_tier='free',
--   max_file_size_bytes=20971520, etc.), así que el trigger los cubre.
--   auth.users no tenía ningún trigger custom (solo RI_ConstraintTrigger).
-- ==========================================================

-- 1. Función: crea el perfil al crearse el usuario en auth.users.
--    SECURITY DEFINER + search_path = public para saltar RLS de users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    -- `email` es NOT NULL en public.users y puede ser NULL en auth.users
    -- (solo si se habilitara phone/anonymous auth, hoy no usado). Se usa
    -- COALESCE para que el trigger NUNCA rompa el alta del usuario.
    insert into public.users (
        id,
        email,
        subscription_tier,
        max_file_size_bytes
    )
    values (
        new.id,
        coalesce(new.email, ''),
        'free',
        20971520
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

-- 2. Trigger AFTER INSERT en auth.users. Idempotente: no falla si se
--    reaplica la migración.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();

-- 3. Backfill de huérfanos ya existentes.
insert into public.users (id, email, subscription_tier)
select au.id, au.email, 'free'
from auth.users au
left join public.users pu on pu.id = au.id
where pu.id is null
  and au.email is not null
on conflict (id) do nothing;
