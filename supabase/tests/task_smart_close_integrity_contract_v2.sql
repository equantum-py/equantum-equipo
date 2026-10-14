-- Structural guardrails for P1 Smart Close Continuity v2.
-- Run after the migration has passed independent review and is applied to the test project.
-- This file checks grants/RLS/function hardening only. It is NOT evidence of real Auth sessions.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_fn regprocedure;
  v_cfg text[];
  v_name text;
BEGIN
  FOREACH v_name IN ARRAY ARRAY[
    'public.task_continuity_actions',
    'public.task_outcome_verifications',
    'public.task_outcome_verification_events'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c
      WHERE c.oid = to_regclass(v_name) AND c.relrowsecurity
    ) THEN
      RAISE EXCEPTION 'FAIL: RLS missing on %', v_name;
    END IF;
    IF has_table_privilege('authenticated', v_name, 'INSERT')
       OR has_table_privilege('authenticated', v_name, 'UPDATE')
       OR has_table_privilege('authenticated', v_name, 'DELETE')
       OR has_table_privilege('anon', v_name, 'SELECT')
       OR has_table_privilege('anon', v_name, 'INSERT') THEN
      RAISE EXCEPTION 'FAIL: excessive table privileges on %', v_name;
    END IF;
    IF NOT has_table_privilege('authenticated', v_name, 'SELECT') THEN
      RAISE EXCEPTION 'FAIL: authenticated read privilege missing on %', v_name;
    END IF;
  END LOOP;

  v_fn := to_regprocedure(
    'public.create_task_continuity(uuid,text,uuid,text,text,timestamp with time zone,text,text,text,text,text,date)'
  );
  IF v_fn IS NULL THEN RAISE EXCEPTION 'FAIL: create_task_continuity missing'; END IF;
  SELECT p.proconfig INTO v_cfg FROM pg_proc p WHERE p.oid = v_fn;
  IF NOT (coalesce(v_cfg, ARRAY[]::text[]) @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'FAIL: create_task_continuity search_path is not empty';
  END IF;
  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = v_fn) THEN
    RAISE EXCEPTION 'FAIL: create_task_continuity SECURITY DEFINER contract changed';
  END IF;
  IF has_function_privilege('anon', v_fn, 'EXECUTE')
     OR NOT has_function_privilege('authenticated', v_fn, 'EXECUTE') THEN
    RAISE EXCEPTION 'FAIL: create_task_continuity execute ACL is too broad or missing';
  END IF;

  v_fn := to_regprocedure(
    'public.record_task_outcome_verification(uuid,uuid,text,text,text)'
  );
  IF v_fn IS NULL THEN RAISE EXCEPTION 'FAIL: record_task_outcome_verification missing'; END IF;
  SELECT p.proconfig INTO v_cfg FROM pg_proc p WHERE p.oid = v_fn;
  IF NOT (coalesce(v_cfg, ARRAY[]::text[]) @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'FAIL: record_task_outcome_verification search_path is not empty';
  END IF;
  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = v_fn) THEN
    RAISE EXCEPTION 'FAIL: record_task_outcome_verification SECURITY DEFINER contract changed';
  END IF;
  IF has_function_privilege('anon', v_fn, 'EXECUTE')
     OR has_function_privilege('PUBLIC', v_fn, 'EXECUTE')
     OR NOT has_function_privilege('authenticated', v_fn, 'EXECUTE') THEN
    RAISE EXCEPTION 'FAIL: record_task_outcome_verification execute ACL is too broad or missing';
  END IF;
END
$$;

\echo PASS: new Smart Close tables use RLS and deny direct DML; RPC ACLs are scoped.
-- Separate authenticated-token tests are required for internal owner, peer, Portal and anon.
-- Separate two-session tests are required to demonstrate concurrent identical and distinct requests.
