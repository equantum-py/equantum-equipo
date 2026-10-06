-- Seguridad y Permisos V2 - Fase de preparacion
-- IMPORTANTE: este archivo se disena en relanzamiento-2026.
-- No aplicar a produccion hasta ejecutar pruebas negativas del Documento 12.
--
-- Objetivo:
-- 1) separar colaborador interno de usuario del Portal;
-- 2) evitar que un usuario autenticado del Portal herede lecturas internas;
-- 3) conservar el acceso del Portal exclusivamente a su propia empresa/tickets;
-- 4) mantener el control administrativo existente.

begin;

-- CLIENTES
-- La politica antigua "clients authenticated read" usa USING (true).
-- Como las politicas RLS permisivas se combinan con OR, esa regla anula
-- el aislamiento de "portal user reads own client".
drop policy if exists "clients authenticated read" on public.clients;

drop policy if exists "clients internal read" on public.clients;
create policy "clients internal read"
on public.clients
for select
to authenticated
using (public.is_active_user());

-- Se conserva:
-- "portal user reads own client" -> id = portal_client_id()
-- "clients admin write"          -> is_admin()

-- PROYECTOS
-- Un login de Portal tambien pertenece al rol authenticated, por lo que
-- USING (true) no es aceptable para datos internos.
drop policy if exists "projects authenticated read" on public.projects;

drop policy if exists "projects internal read" on public.projects;
create policy "projects internal read"
on public.projects
for select
to authenticated
using (public.is_active_user());

-- MEJORAS / IA
-- Deben ser informacion interna; no deben quedar visibles a cualquier
-- cuenta autenticada del Portal.
drop policy if exists "authenticated read improvements" on public.improvement_suggestions;

drop policy if exists "internal read improvements" on public.improvement_suggestions;
create policy "internal read improvements"
on public.improvement_suggestions
for select
to authenticated
using (public.is_active_user());

-- La insercion tambien queda limitada a usuarios internos activos.
drop policy if exists "authenticated create improvements" on public.improvement_suggestions;

drop policy if exists "internal create improvements" on public.improvement_suggestions;
create policy "internal create improvements"
on public.improvement_suggestions
for insert
to authenticated
with check (
  public.is_active_user()
  and created_by = auth.uid()
);

commit;

-- PRUEBAS OBLIGATORIAS ANTES DE PRODUCCION
-- A. Usuario interno activo:
--    - puede leer clients y projects segun alcance interno actual.
--    - puede leer improvement_suggestions.
-- B. Usuario Portal de Cliente A:
--    - puede leer solamente su fila de clients.
--    - NO puede leer Cliente B.
--    - NO puede leer projects internos.
--    - NO puede leer improvement_suggestions.
--    - puede leer solamente tickets de Cliente A.
--    - puede leer ticket_messages de sus tickets solo cuando is_internal=false.
-- C. Usuario suspendido:
--    - no obtiene acceso interno por estas politicas.
-- D. anon:
--    - no obtiene filas de estas tablas.
