\set ON_ERROR_STOP on

SELECT has_schema_privilege('authenticated','auth','USAGE') AS qa_auth_usage_before,
       has_function_privilege('authenticated','auth.uid()','EXECUTE') AS qa_auth_uid_before
\gset

CREATE TEMP TABLE qa_p1_scope_fixture AS
SELECT owner_profile.id AS owner_id,
       reader_profile.id AS reader_id,
       reader_profile.area AS reader_original_area,
       reader_permission.view_all_tasks AS original_view_all,
       reader_permission.view_area_tasks AS original_view_area,
       reader_permission.reassign_tasks AS original_reassign,
       reader_permission.delete_tasks AS original_delete,
       owner_profile.area AS owner_area,
       sample_task.task_type,
       sample_ticket.id AS ticket_id
FROM public.profiles owner_profile
JOIN public.user_permissions owner_permission ON owner_permission.user_id=owner_profile.id
JOIN public.profiles reader_profile ON reader_profile.id<>owner_profile.id AND reader_profile.active IS TRUE
JOIN public.user_permissions reader_permission ON reader_permission.user_id=reader_profile.id
JOIN LATERAL (SELECT task_type FROM public.tasks ORDER BY id LIMIT 1) sample_task ON true
JOIN LATERAL (SELECT id FROM public.tickets ORDER BY created_at,id LIMIT 1) sample_ticket ON true
WHERE owner_profile.active IS TRUE
  AND owner_profile.area IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM public.client_portal_users p WHERE p.user_id=owner_profile.id AND p.active IS TRUE)
  AND NOT EXISTS (SELECT 1 FROM public.client_portal_users p WHERE p.user_id=reader_profile.id AND p.active IS TRUE)
ORDER BY owner_profile.id,reader_profile.id
LIMIT 1;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM qa_p1_scope_fixture) THEN
    RAISE EXCEPTION 'BLOCKED: baseline lacks two active internal identities, permissions, task metadata, or ticket';
  END IF;
END
$$;

BEGIN;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;

INSERT INTO public.tasks(id,title,area,task_type,created_by,assignee_id,ticket_id)
SELECT 'd0c0a000-0000-4000-8000-0000000000e1'::uuid,
       'QA-READ-SCOPE-WRITE-DENIAL',owner_area,task_type,reader_id,owner_id,ticket_id
FROM qa_p1_scope_fixture;
INSERT INTO public.task_status_history(task_id,from_status,to_status,actor_id,reason,metadata)
VALUES('d0c0a000-0000-4000-8000-0000000000e1','pending','in_progress',
       (SELECT owner_id FROM qa_p1_scope_fixture),'temporary scope fixture','{}'::jsonb);

UPDATE public.profiles SET area=(SELECT owner_area FROM qa_p1_scope_fixture)
WHERE id=(SELECT reader_id FROM qa_p1_scope_fixture);
UPDATE public.user_permissions SET view_all_tasks=true,view_area_tasks=false,reassign_tasks=false,delete_tasks=false
WHERE user_id=(SELECT reader_id FROM qa_p1_scope_fixture);

SET LOCAL ROLE authenticated;
DO $$
DECLARE v_reader uuid; v_count integer;
BEGIN
  SELECT reader_id INTO v_reader FROM qa_p1_scope_fixture;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_reader,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_reader::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  SELECT count(*) INTO v_count FROM public.tasks WHERE id='d0c0a000-0000-4000-8000-0000000000e1';
  IF v_count<>1 THEN RAISE EXCEPTION 'FAIL: view_all_tasks no longer permits reading'; END IF;
  SELECT count(*) INTO v_count FROM public.task_status_history
  WHERE task_id='d0c0a000-0000-4000-8000-0000000000e1';
  IF v_count<>1 THEN RAISE EXCEPTION 'FAIL: view_all_tasks no longer permits scoped history read'; END IF;
  BEGIN
    PERFORM public.archive_task('d0c0a000-0000-4000-8000-0000000000e1','read-only actor');
    RAISE EXCEPTION 'FAIL: view_all_tasks authorized archival';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_ARCHIVE_UNAUTHORIZED%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id=>'d0c0a000-0000-4000-8000-0000000000e1',p_status=>'blocked',p_expected_status=>'pending',
      p_blocked_reason=>'read-only view_all scope'
    );
    RAISE EXCEPTION 'FAIL: view_all_tasks authorized a transition';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_NOT_FOUND_OR_FORBIDDEN%' THEN RAISE; END IF;
  END;
  UPDATE public.tasks SET title='QA-UNAUTHORIZED-EDIT' WHERE id='d0c0a000-0000-4000-8000-0000000000e1';
  GET DIAGNOSTICS v_count=ROW_COUNT;
  IF v_count<>0 THEN RAISE EXCEPTION 'FAIL: view_all_tasks authorized raw UPDATE'; END IF;
  UPDATE public.tasks SET assignee_id=v_reader WHERE id='d0c0a000-0000-4000-8000-0000000000e1';
  GET DIAGNOSTICS v_count=ROW_COUNT;
  IF v_count<>0 THEN RAISE EXCEPTION 'FAIL: view_all_tasks authorized reassignment'; END IF;
  RAISE NOTICE 'PASS: view_all_tasks reads task/history but cannot transition or update';
END
$$;
RESET ROLE;

UPDATE public.user_permissions SET view_all_tasks=false,view_area_tasks=true,reassign_tasks=false,delete_tasks=false
WHERE user_id=(SELECT reader_id FROM qa_p1_scope_fixture);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_reader uuid; v_count integer;
BEGIN
  SELECT reader_id INTO v_reader FROM qa_p1_scope_fixture;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_reader,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_reader::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  SELECT count(*) INTO v_count FROM public.tasks WHERE id='d0c0a000-0000-4000-8000-0000000000e1';
  IF v_count<>1 THEN RAISE EXCEPTION 'FAIL: view_area_tasks no longer permits in-area reading'; END IF;
  BEGIN
    PERFORM public.archive_task('d0c0a000-0000-4000-8000-0000000000e1','read-only actor');
    RAISE EXCEPTION 'FAIL: view_area_tasks authorized archival';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_ARCHIVE_UNAUTHORIZED%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id=>'d0c0a000-0000-4000-8000-0000000000e1',p_status=>'blocked',p_expected_status=>'pending',
      p_blocked_reason=>'read-only view_area scope'
    );
    RAISE EXCEPTION 'FAIL: view_area_tasks authorized a transition';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_NOT_FOUND_OR_FORBIDDEN%' THEN RAISE; END IF;
  END;
  UPDATE public.tasks SET title='QA-UNAUTHORIZED-EDIT' WHERE id='d0c0a000-0000-4000-8000-0000000000e1';
  GET DIAGNOSTICS v_count=ROW_COUNT;
  IF v_count<>0 THEN RAISE EXCEPTION 'FAIL: view_area_tasks authorized raw UPDATE'; END IF;
  UPDATE public.tasks SET assignee_id=v_reader WHERE id='d0c0a000-0000-4000-8000-0000000000e1';
  GET DIAGNOSTICS v_count=ROW_COUNT;
  IF v_count<>0 THEN RAISE EXCEPTION 'FAIL: view_area_tasks authorized reassignment'; END IF;
  RAISE NOTICE 'PASS: view_area_tasks reads in-area task but cannot transition or update';
END
$$;
RESET ROLE;

-- A mutation grant is not a blanket row-edit grant for a task outside the
-- actor's assignment. The explicit reassign permission can change assignment
-- only; content changes remain blocked by the database trigger.
UPDATE public.user_permissions SET view_all_tasks=true,view_area_tasks=false,reassign_tasks=true,delete_tasks=false
WHERE user_id=(SELECT reader_id FROM qa_p1_scope_fixture);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_reader uuid;
BEGIN
  SELECT reader_id INTO v_reader FROM qa_p1_scope_fixture;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_reader,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_reader::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  BEGIN
    UPDATE public.tasks SET title='QA-UNAUTHORIZED-DELEGATED-EDIT'
    WHERE id='d0c0a000-0000-4000-8000-0000000000e1';
    RAISE EXCEPTION 'FAIL: reassign_tasks authorized changing task content';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_REASSIGNMENT_ONLY%' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'PASS: reassign_tasks does not authorize foreign-task content edits';
END
$$;
RESET ROLE;

-- Creator identity alone is not a permanent access grant after assignment is
-- held by someone else and the creator has no explicit view scope.
UPDATE public.user_permissions
SET view_all_tasks=false,view_area_tasks=false,reassign_tasks=false,delete_tasks=false
WHERE user_id=(SELECT reader_id FROM qa_p1_scope_fixture);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_creator uuid; v_count integer;
BEGIN
  SELECT reader_id INTO v_creator FROM qa_p1_scope_fixture;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_creator,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_creator::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  SELECT count(*) INTO v_count FROM public.tasks WHERE id='d0c0a000-0000-4000-8000-0000000000e1';
  IF v_count<>0 THEN RAISE EXCEPTION 'FAIL: creator retained task visibility without assignment or scope'; END IF;
  SELECT count(*) INTO v_count FROM public.task_status_history
  WHERE task_id='d0c0a000-0000-4000-8000-0000000000e1';
  IF v_count<>0 THEN RAISE EXCEPTION 'FAIL: creator retained history visibility without task scope'; END IF;
  RAISE NOTICE 'PASS: creator alone does not retain task or history visibility';
END
$$;
RESET ROLE;

ROLLBACK;

SELECT 1 / CASE WHEN
  has_schema_privilege('authenticated','auth','USAGE') IS NOT DISTINCT FROM :'qa_auth_usage_before'::boolean
  AND has_function_privilege('authenticated','auth.uid()','EXECUTE') IS NOT DISTINCT FROM :'qa_auth_uid_before'::boolean
  THEN 1 ELSE 0 END AS temporary_auth_grants_restored;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.tasks WHERE id='d0c0a000-0000-4000-8000-0000000000e1')
     OR EXISTS (SELECT 1 FROM public.task_status_history WHERE task_id='d0c0a000-0000-4000-8000-0000000000e1') THEN
    RAISE EXCEPTION 'FAIL: read-scope fixtures remained after ROLLBACK';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM qa_p1_scope_fixture f
    JOIN public.profiles p ON p.id=f.reader_id AND p.area IS NOT DISTINCT FROM f.reader_original_area
    JOIN public.user_permissions up ON up.user_id=f.reader_id
      AND up.view_all_tasks IS NOT DISTINCT FROM f.original_view_all
      AND up.view_area_tasks IS NOT DISTINCT FROM f.original_view_area
      AND up.reassign_tasks IS NOT DISTINCT FROM f.original_reassign
      AND up.delete_tasks IS NOT DISTINCT FROM f.original_delete
  ) THEN RAISE EXCEPTION 'FAIL: read-scope actor configuration was not restored'; END IF;
  RAISE NOTICE 'PASS: fixtures, profile area, permissions, and temporary grants restored';
END
$$;
