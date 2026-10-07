-- financial_ai_boundary_v2.sql
-- Verifica la frontera DB utilizada por /api/ai/assistant.
-- La API debe consultar has_financial_info() antes de exponer contexto sensible.

BEGIN;

DO $$
DECLARE
  fn regprocedure;
BEGIN
  fn := to_regprocedure('public.has_financial_info()');

  IF fn IS NULL THEN
    RAISE EXCEPTION 'FAIL: falta public.has_financial_info()';
  END IF;

  RAISE NOTICE 'PASS 1/4: has_financial_info existe';
END $$;

DO $$
DECLARE
  is_definer boolean;
BEGIN
  SELECT p.prosecdef
    INTO is_definer
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'has_financial_info'
    AND p.pronargs = 0;

  IF is_definer IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'FAIL: has_financial_info debe ser SECURITY DEFINER';
  END IF;

  RAISE NOTICE 'PASS 2/4: función usa SECURITY DEFINER';
END $$;

DO $$
DECLARE
  public_exec boolean;
  anon_exec boolean;
BEGIN
  SELECT has_function_privilege(
    'public',
    'public.has_financial_info()',
    'EXECUTE'
  ) INTO public_exec;

  SELECT has_function_privilege(
    'anon',
    'public.has_financial_info()',
    'EXECUTE'
  ) INTO anon_exec;

  IF public_exec THEN
    RAISE EXCEPTION 'FAIL: PUBLIC conserva EXECUTE';
  END IF;

  IF anon_exec THEN
    RAISE EXCEPTION 'FAIL: anon conserva EXECUTE';
  END IF;

  RAISE NOTICE 'PASS 3/4: PUBLIC y anon no pueden ejecutar';
END $$;

DO $$
DECLARE
  authenticated_exec boolean;
BEGIN
  SELECT has_function_privilege(
    'authenticated',
    'public.has_financial_info()',
    'EXECUTE'
  ) INTO authenticated_exec;

  IF NOT authenticated_exec THEN
    RAISE EXCEPTION 'FAIL: authenticated no puede ejecutar has_financial_info';
  END IF;

  RAISE NOTICE 'PASS 4/4: authenticated puede ejecutar';
END $$;

ROLLBACK;
