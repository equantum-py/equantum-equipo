-- Security / Portal RLS V3
-- SOLO staging hasta superar pruebas negativas.
-- Consolida políticas duplicadas sin mezclar Portal con usuarios internos.

BEGIN;

-- =========================================================
-- TICKETS
-- =========================================================

DROP POLICY IF EXISTS "authenticated create tickets" ON public.tickets;
DROP POLICY IF EXISTS "authenticated read tickets" ON public.tickets;
DROP POLICY IF EXISTS "authenticated update tickets" ON public.tickets;

-- Se conservan:
-- active users create/read/update tickets
-- portal user creates own tickets
-- portal user reads own tickets


-- =========================================================
-- TICKET MESSAGES
-- =========================================================

DROP POLICY IF EXISTS "authenticated create ticket messages"
ON public.ticket_messages;

DROP POLICY IF EXISTS "authenticated read ticket messages"
ON public.ticket_messages;

-- Se conservan:
-- active users create ticket messages
-- active users read ticket messages
-- portal user reads own ticket messages
-- portal user replies own tickets


-- =========================================================
-- TICKET EVENTS
-- =========================================================

-- Ticket events son exclusivamente internos.
-- Las políticas existentes ya exigen is_active_user().
-- No se crea acceso Portal.


-- =========================================================
-- STORAGE: TICKET ATTACHMENTS
-- =========================================================

-- Esta política permitía leer cualquier archivo del bucket
-- simplemente por pertenecer al rol authenticated.
DROP POLICY IF EXISTS "ticket attachments authenticated read"
ON storage.objects;

-- Lectura del propio espacio.
-- El esquema actual guarda archivos bajo:
-- <auth.uid()>/...
CREATE POLICY "ticket attachments read authorized"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'ticket-attachments'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR public.is_internal_user()
  )
);

-- INSERT y DELETE existentes ya verifican la misma carpeta UID.


-- =========================================================
-- FUNCIÓN OPERATIVA SENSIBLE
-- =========================================================

-- No debe poder ejecutarse desde anon/public.
REVOKE EXECUTE ON FUNCTION public.detect_operational_improvements()
FROM PUBLIC;

REVOKE EXECUTE ON FUNCTION public.detect_operational_improvements()
FROM anon;

-- Temporalmente solo authenticated.
-- La propia lógica/RLS interna seguirá determinando acceso.
GRANT EXECUTE ON FUNCTION public.detect_operational_improvements()
TO authenticated;

COMMIT;
