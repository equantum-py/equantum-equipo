-- Security RLS V3.1
-- Frontera explícita entre usuario interno y Portal.
-- SOLO staging.

BEGIN;

CREATE OR REPLACE FUNCTION public.is_internal_user()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.active = true
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.client_portal_users cpu
      WHERE cpu.user_id = auth.uid()
        AND cpu.active = true
    );
$$;

REVOKE ALL ON FUNCTION public.is_internal_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_internal_user() FROM anon;
GRANT EXECUTE ON FUNCTION public.is_internal_user() TO authenticated;

-- CLIENTES
DROP POLICY IF EXISTS "clients internal read" ON public.clients;

CREATE POLICY "clients internal read"
ON public.clients
FOR SELECT TO authenticated
USING (public.is_internal_user());

-- PROYECTOS
DROP POLICY IF EXISTS "projects internal read" ON public.projects;

CREATE POLICY "projects internal read"
ON public.projects
FOR SELECT TO authenticated
USING (public.is_internal_user());

-- MEJORAS INTERNAS
DROP POLICY IF EXISTS "internal read improvements"
ON public.improvement_suggestions;

CREATE POLICY "internal read improvements"
ON public.improvement_suggestions
FOR SELECT TO authenticated
USING (public.is_internal_user());

DROP POLICY IF EXISTS "internal create improvements"
ON public.improvement_suggestions;

CREATE POLICY "internal create improvements"
ON public.improvement_suggestions
FOR INSERT TO authenticated
WITH CHECK (
  public.is_internal_user()
  AND created_by = auth.uid()
);


-- TICKETS INTERNOS
DROP POLICY IF EXISTS "active users create tickets" ON public.tickets;
DROP POLICY IF EXISTS "active users read tickets" ON public.tickets;
DROP POLICY IF EXISTS "active users update tickets" ON public.tickets;

CREATE POLICY "internal users create tickets"
ON public.tickets
FOR INSERT TO authenticated
WITH CHECK (
  public.is_internal_user()
  AND opened_by = auth.uid()
);

CREATE POLICY "internal users read tickets"
ON public.tickets
FOR SELECT TO authenticated
USING (public.is_internal_user());

CREATE POLICY "internal users update tickets"
ON public.tickets
FOR UPDATE TO authenticated
USING (public.is_internal_user())
WITH CHECK (public.is_internal_user());

-- MENSAJES INTERNOS
DROP POLICY IF EXISTS "active users create ticket messages"
ON public.ticket_messages;

DROP POLICY IF EXISTS "active users read ticket messages"
ON public.ticket_messages;

CREATE POLICY "internal users create ticket messages"
ON public.ticket_messages
FOR INSERT TO authenticated
WITH CHECK (
  public.is_internal_user()
  AND author_id = auth.uid()
);

CREATE POLICY "internal users read ticket messages"
ON public.ticket_messages
FOR SELECT TO authenticated
USING (public.is_internal_user());

-- EVENTOS INTERNOS
DROP POLICY IF EXISTS "active users create ticket events"
ON public.ticket_events;

DROP POLICY IF EXISTS "active users read ticket events"
ON public.ticket_events;

CREATE POLICY "internal users create ticket events"
ON public.ticket_events
FOR INSERT TO authenticated
WITH CHECK (
  public.is_internal_user()
  AND actor_id = auth.uid()
);

CREATE POLICY "internal users read ticket events"
ON public.ticket_events
FOR SELECT TO authenticated
USING (public.is_internal_user());

COMMIT;
