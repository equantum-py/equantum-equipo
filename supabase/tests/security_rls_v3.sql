\set ON_ERROR_STOP on

DO $$
DECLARE
  n integer;
BEGIN
  -- Las 12 tablas V2 deben tener RLS activo.
  SELECT count(*)
  INTO n
  FROM pg_class c
  JOIN pg_namespace ns ON ns.oid=c.relnamespace
  WHERE ns.nspname='public'
    AND c.relname IN (
      'commercial_entities','catalog_items','prospects','opportunities',
      'proposals','proposal_items','sales','sale_items',
      'active_services','active_service_events',
      'radar_items','task_status_history'
    )
    AND c.relrowsecurity=true;

  IF n <> 12 THEN
    RAISE EXCEPTION 'FAIL: solo %/12 tablas V2 tienen RLS', n;
  END IF;

  -- Las 12 deben tener al menos una política.
  SELECT count(DISTINCT tablename)
  INTO n
  FROM pg_policies
  WHERE schemaname='public'
    AND tablename IN (
      'commercial_entities','catalog_items','prospects','opportunities',
      'proposals','proposal_items','sales','sale_items',
      'active_services','active_service_events',
      'radar_items','task_status_history'
    );

  IF n <> 12 THEN
    RAISE EXCEPTION 'FAIL: solo %/12 tablas V2 tienen políticas', n;
  END IF;

  -- No debe sobrevivir la lectura amplia anterior de Storage.
  IF EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname='storage'
      AND tablename='objects'
      AND policyname='ticket attachments authenticated read'
  ) THEN
    RAISE EXCEPTION 'FAIL: política amplia de Storage todavía existe';
  END IF;

  -- Funciones de seguridad obligatorias.
  IF to_regprocedure('public.is_internal_user()') IS NULL THEN
    RAISE EXCEPTION 'FAIL: falta is_internal_user()';
  END IF;

  IF to_regprocedure('public.has_financial_info()') IS NULL THEN
    RAISE EXCEPTION 'FAIL: falta has_financial_info()';
  END IF;

  IF to_regprocedure('public.detect_operational_improvements()') IS NULL THEN
    RAISE EXCEPTION 'FAIL: falta detect_operational_improvements()';
  END IF;

  RAISE NOTICE 'PASS: SECURITY RLS V3';
END
$$;
