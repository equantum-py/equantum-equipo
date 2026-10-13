\set ON_ERROR_STOP on

DO $$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY['clients','prospects','commercial_entities'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='public' AND c.relname=v_table AND c.relrowsecurity
    ) THEN
      RAISE EXCEPTION 'FAIL: RLS no está habilitado en public.%', v_table;
    END IF;
  END LOOP;

  IF NOT has_table_privilege('authenticated','public.clients','SELECT')
     OR NOT has_table_privilege('authenticated','public.prospects','SELECT')
     OR NOT has_table_privilege('authenticated','public.commercial_entities','SELECT') THEN
    RAISE EXCEPTION 'FAIL: falta SELECT requerido para la vista de Clientes/Prospectos';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.schemaname='public' AND p.tablename='clients'
      AND p.policyname='clients internal read' AND p.cmd='SELECT'
      AND 'authenticated'::name=ANY(p.roles) AND p.qual ILIKE '%is_internal_user%'
  ) THEN
    RAISE EXCEPTION 'FAIL: falta la política RLS interna de Clientes';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.schemaname='public' AND p.tablename='prospects'
      AND p.policyname='prospects internal read' AND p.cmd='SELECT'
      AND 'authenticated'::name=ANY(p.roles) AND p.qual ILIKE '%is_internal_user%'
  ) THEN
    RAISE EXCEPTION 'FAIL: falta la política RLS interna de Prospectos';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.schemaname='public' AND p.tablename='commercial_entities'
      AND p.policyname='commercial entities internal read' AND p.cmd='SELECT'
      AND 'authenticated'::name=ANY(p.roles) AND p.qual ILIKE '%is_internal_user%'
  ) THEN
    RAISE EXCEPTION 'FAIL: falta la política RLS interna de datos comerciales';
  END IF;

  IF has_table_privilege('authenticated','public.prospects','INSERT')
     OR has_table_privilege('authenticated','public.prospects','UPDATE')
     OR has_table_privilege('authenticated','public.prospects','DELETE') THEN
    RAISE EXCEPTION 'FAIL: Prospectos recibió permisos de escritura en esta entrega';
  END IF;

  RAISE NOTICE 'PASS: SELECT está limitado por RLS para usuarios internos; Prospectos sigue de solo lectura';
END;
$$;
