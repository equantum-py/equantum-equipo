-- Install the profile bootstrap hook expected by the P1 test baseline.
-- Existing correct trigger: no-op. Existing homonymous trigger pointing
-- elsewhere or disabled: fail closed instead of replacing it silently.
DO $migration$
DECLARE
  v_function oid := to_regprocedure('public.handle_new_user()')::oid;
  v_trigger_function oid;
  v_trigger_enabled "char";
BEGIN
  IF v_function IS NULL THEN
    RAISE EXCEPTION 'Required function public.handle_new_user() is missing';
  END IF;

  SELECT t.tgfoid, t.tgenabled
    INTO v_trigger_function, v_trigger_enabled
  FROM pg_trigger AS t
  WHERE t.tgrelid = 'auth.users'::regclass
    AND t.tgname = 'on_auth_user_created'
    AND NOT t.tgisinternal;

  IF FOUND THEN
    IF v_trigger_function <> v_function THEN
      RAISE EXCEPTION
        'Refusing to replace on_auth_user_created: it targets a different function';
    END IF;
    IF v_trigger_enabled = 'D' THEN
      RAISE EXCEPTION
        'Refusing to silently enable disabled trigger on_auth_user_created';
    END IF;
    RETURN;
  END IF;

  EXECUTE $ddl$
    CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user()
  $ddl$;
END
$migration$;
