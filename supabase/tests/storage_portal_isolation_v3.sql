\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN

  -- QA: Storage requiere RLS y politica autorizada.
  IF NOT EXISTS (
    SELECT 1 FROM pg_class
    WHERE oid = to_regclass('storage.objects')
      AND relrowsecurity
  ) THEN
    RAISE EXCEPTION 'FAIL: falta Storage o su RLS';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'ticket attachments read authorized'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) THEN
    RAISE EXCEPTION 'FAIL: falta politica autorizada de Storage';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'authenticated'
  ) OR EXISTS (
    SELECT 1 FROM pg_roles
    WHERE rolname = 'authenticated'
      AND (rolsuper OR rolbypassrls)
  ) OR EXISTS (
    SELECT 1 FROM pg_class
    WHERE oid = to_regclass('storage.objects')
      AND relowner = (
        SELECT oid FROM pg_roles WHERE rolname = 'authenticated'
      )
  ) THEN
    RAISE EXCEPTION 'FAIL: authenticated podria evitar RLS';
  END IF;

END $$;


-- Adaptación exclusiva del PostgreSQL local para reproducir
-- la capa mínima de permisos administrados por Supabase.
-- Todos estos cambios desaparecen con ROLLBACK.
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT SELECT ON storage.objects TO authenticated;

INSERT INTO storage.objects (bucket_id, name, owner_id)
VALUES
(
  'ticket-attachments',
  'f9a3b4e6-071c-4162-85c0-c51d88ee4286/QA-STORAGE-A.txt',
  'f9a3b4e6-071c-4162-85c0-c51d88ee4286'
),
(
  'ticket-attachments',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/QA-STORAGE-B.txt',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
);

SET LOCAL ROLE authenticated;

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"f9a3b4e6-071c-4162-85c0-c51d88ee4286","role":"authenticated"}',
  true
);

DO $$
DECLARE
  v_own integer;
  v_other integer;
BEGIN
  SELECT COUNT(*) INTO v_own
  FROM storage.objects
  WHERE name =
    'f9a3b4e6-071c-4162-85c0-c51d88ee4286/QA-STORAGE-A.txt';

  SELECT COUNT(*) INTO v_other
  FROM storage.objects
  WHERE name =
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/QA-STORAGE-B.txt';

  IF v_own <> 1 OR v_other <> 0 THEN
    RAISE EXCEPTION
      'Storage isolation failed for user A: own=%, other=%',
      v_own, v_other;
  END IF;

  RAISE NOTICE
    'PASS user A: own=%, other=%',
    v_own, v_other;
END $$;

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb","role":"authenticated"}',
  true
);

DO $$
DECLARE
  v_own integer;
  v_other integer;
BEGIN
  SELECT COUNT(*) INTO v_own
  FROM storage.objects
  WHERE name =
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/QA-STORAGE-B.txt';

  SELECT COUNT(*) INTO v_other
  FROM storage.objects
  WHERE name =
    'f9a3b4e6-071c-4162-85c0-c51d88ee4286/QA-STORAGE-A.txt';

  IF v_own <> 1 OR v_other <> 0 THEN
    RAISE EXCEPTION
      'Storage isolation failed for user B: own=%, other=%',
      v_own, v_other;
  END IF;

  RAISE NOTICE
    'PASS user B: own=%, other=%',
    v_own, v_other;
END $$;

RESET ROLE;

ROLLBACK;
