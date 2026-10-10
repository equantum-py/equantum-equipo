-- P1-ANON-ROLE-AUTH. Exercises PostgreSQL's actual anon role in a transaction.
-- No fixture rows are created; all role/session state is reverted at ROLLBACK.
BEGIN;
SET LOCAL ROLE anon;

DO $test$
DECLARE
  v_denied boolean := false;
BEGIN
  BEGIN
    EXECUTE 'SELECT public.transition_task_operational_status(NULL::uuid,NULL::text,NULL::text,NULL::text,NULL::text,NULL::timestamptz,NULL::text,NULL::text,NULL::text,NULL::boolean,NULL::text)';
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'FAIL P1-ANON-ROLE-AUTH: anon executed the task transition RPC';
  END IF;

  v_denied := false;
  BEGIN
    EXECUTE 'SELECT id FROM public.tasks LIMIT 1';
  EXCEPTION WHEN insufficient_privilege THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'FAIL P1-ANON-ROLE-AUTH: anon read tasks';
  END IF;

  RAISE NOTICE 'PASS P1-ANON-ROLE-AUTH: anon denied the task RPC and direct task read';
END
$test$;

ROLLBACK;
