-- Structural regression for the Auth -> profile bootstrap hook.
-- The actual trigger firing is verified separately through Supabase Auth API.
DO $test$
BEGIN
  IF to_regprocedure('public.handle_new_user()') IS NULL THEN
    RAISE EXCEPTION 'FAIL: public.handle_new_user() is missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger t
    WHERE t.tgrelid = 'auth.users'::regclass
      AND t.tgname = 'on_auth_user_created'
      AND t.tgfoid = 'public.handle_new_user()'::regprocedure
      AND t.tgenabled = 'O'
      AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'FAIL: on_auth_user_created is missing, disabled, or points elsewhere';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    WHERE c.oid = 'public.client_legacy_services'::regclass
      AND c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'FAIL: client_legacy_services RLS is not enabled';
  END IF;

  IF has_table_privilege('anon', 'public.client_legacy_services', 'TRUNCATE')
     OR has_table_privilege('authenticated', 'public.client_legacy_services', 'TRUNCATE') THEN
    RAISE EXCEPTION 'FAIL: anon/authenticated can TRUNCATE client_legacy_services';
  END IF;

  RAISE NOTICE 'PASS: Auth trigger target/enabled state and legacy TRUNCATE denial';
END
$test$;
