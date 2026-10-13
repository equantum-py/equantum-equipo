BEGIN;

-- Conceder solo lectura para la vista inicial de Ventas.
-- Las políticas RLS existentes siguen definiendo qué filas puede leer el usuario.
DO $$
BEGIN
  IF to_regclass('public.clients') IS NULL
     OR NOT (SELECT c.relrowsecurity FROM pg_class c WHERE c.oid='public.clients'::regclass) THEN
    RAISE EXCEPTION 'public.clients debe existir con RLS habilitado';
  END IF;
  IF to_regclass('public.prospects') IS NULL
     OR NOT (SELECT c.relrowsecurity FROM pg_class c WHERE c.oid='public.prospects'::regclass) THEN
    RAISE EXCEPTION 'public.prospects debe existir con RLS habilitado';
  END IF;
  IF to_regclass('public.commercial_entities') IS NULL
     OR NOT (SELECT c.relrowsecurity FROM pg_class c WHERE c.oid='public.commercial_entities'::regclass) THEN
    RAISE EXCEPTION 'public.commercial_entities debe existir con RLS habilitado';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.schemaname='public' AND p.tablename='clients'
      AND p.policyname='clients internal read' AND p.cmd='SELECT'
      AND 'authenticated'::name=ANY(p.roles) AND p.qual ILIKE '%is_internal_user%'
  ) THEN
    RAISE EXCEPTION 'falta la política RLS de lectura interna para Clientes';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.schemaname='public' AND p.tablename='prospects'
      AND p.policyname='prospects internal read' AND p.cmd='SELECT'
      AND 'authenticated'::name=ANY(p.roles) AND p.qual ILIKE '%is_internal_user%'
  ) THEN
    RAISE EXCEPTION 'falta la política RLS de lectura interna para Prospectos';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.schemaname='public' AND p.tablename='commercial_entities'
      AND p.policyname='commercial entities internal read' AND p.cmd='SELECT'
      AND 'authenticated'::name=ANY(p.roles) AND p.qual ILIKE '%is_internal_user%'
  ) THEN
    RAISE EXCEPTION 'falta la política RLS de lectura interna para datos comerciales';
  END IF;
  IF NOT has_table_privilege('authenticated','public.commercial_entities','SELECT') THEN
    RAISE EXCEPTION 'falta el privilegio SELECT previamente definido para commercial_entities';
  END IF;
END;
$$;

GRANT SELECT ON TABLE public.clients, public.prospects TO authenticated;

COMMIT;
