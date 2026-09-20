-- ==========================================================
-- KRIPTONSHARE — Política RLS de INSERT en public.users
-- ==========================================================
-- Contexto: el trigger on_auth_user_created (service role) crea la fila con
-- bypass de RLS, pero el upsert del cliente (`auth_provider.dart`) llega como
-- rol `authenticated`. PostgREST implementa upsert como
-- `INSERT ... ON CONFLICT DO UPDATE`, por lo que exige permiso de INSERT
-- aunque la fila ya exista → PostgREST 42501.
--
-- Estado previo verificado (pg_policies, public.users):
--   - "Users can read own data"   SELECT  USING (auth.uid() = id)
--   - "Users can update own data" UPDATE  USING (auth.uid() = id)
--   → no existía política de INSERT.
-- ==========================================================

drop policy if exists "users_insert_own" on public.users;

create policy "users_insert_own" on public.users
for insert
to authenticated
with check (auth.uid() = id);
