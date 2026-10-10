\set ON_ERROR_STOP on

SELECT has_schema_privilege('authenticated', 'auth', 'USAGE') AS qa_auth_usage_before,
       has_function_privilege('authenticated', 'auth.uid()', 'EXECUTE') AS qa_auth_uid_before
\gset

BEGIN;

-- Supabase Auth ACLs may not be present in a plain PostgreSQL restore. These
-- grants exist only for this transaction and are removed by the final ROLLBACK.
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;

CREATE TEMP TABLE qa_p1_ids (
  actor uuid NOT NULL,
  denied_actor uuid NOT NULL,
  portal_actor uuid NOT NULL,
  task_without_other_commitment uuid NOT NULL,
  task_with_other_commitment uuid NOT NULL,
  ticket_id uuid NOT NULL,
  ticket_status text
) ON COMMIT DROP;
GRANT SELECT ON qa_p1_ids TO authenticated;

DO $$
DECLARE
  v_actor uuid;
  v_denied uuid;
  v_portal uuid;
  v_area text;
  v_type text;
  v_ticket uuid;
  v_ticket_status text;
  v_task_a uuid;
  v_task_b uuid;
  v_fixture_a constant uuid := 'd0c0a000-0000-4000-8000-0000000000a1';
  v_fixture_b constant uuid := 'd0c0a000-0000-4000-8000-0000000000a2';
BEGIN
  SELECT p.id INTO v_actor
  FROM public.profiles p
  WHERE p.active IS TRUE
    AND EXISTS (SELECT 1 FROM public.user_permissions up WHERE up.user_id=p.id)
    AND NOT EXISTS (
      SELECT 1 FROM public.client_portal_users cpu
      WHERE cpu.user_id = p.id AND cpu.active IS TRUE
    )
  ORDER BY p.id LIMIT 1;

  SELECT p.id INTO v_denied
  FROM public.profiles p
  LEFT JOIN public.user_permissions up ON up.user_id = p.id
  WHERE p.active IS TRUE
    AND p.id <> v_actor
    AND coalesce(p.is_master, false) IS FALSE
    AND up.user_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM public.client_portal_users cpu
      WHERE cpu.user_id = p.id AND cpu.active IS TRUE
    )
    AND coalesce(up.view_all_tasks, false) IS FALSE
    AND coalesce(up.view_area_tasks, false) IS FALSE
  ORDER BY p.id LIMIT 1;

  SELECT cpu.user_id INTO v_portal
  FROM public.client_portal_users cpu
  WHERE cpu.active IS TRUE
  ORDER BY cpu.user_id LIMIT 1;

  SELECT area, task_type INTO v_area, v_type
  FROM public.tasks ORDER BY id LIMIT 1;
  SELECT id, status::text INTO v_ticket, v_ticket_status
  FROM public.tickets ORDER BY created_at, id LIMIT 1;

  IF v_actor IS NULL OR v_denied IS NULL OR v_portal IS NULL
     OR v_area IS NULL OR v_type IS NULL OR v_ticket IS NULL THEN
    RAISE EXCEPTION 'FAIL: baseline lacks active owner, denied internal actor, Portal actor, task metadata or Ticket fixture';
  END IF;

  IF EXISTS (SELECT 1 FROM public.tasks WHERE id IN (v_fixture_a, v_fixture_b)) THEN
    RAISE EXCEPTION 'FAIL: deterministic QA fixture IDs already exist';
  END IF;
  INSERT INTO public.tasks(id, title, area, task_type, created_by, assignee_id, ticket_id)
  VALUES (v_fixture_a, 'QA-P1-TASK-RADAR-A', v_area, v_type, v_actor, v_actor, v_ticket)
  RETURNING id INTO v_task_a;
  INSERT INTO public.tasks(id, title, area, task_type, created_by, assignee_id, ticket_id)
  VALUES (v_fixture_b, 'QA-P1-TASK-RADAR-B', v_area, v_type, v_actor, v_actor, v_ticket)
  RETURNING id INTO v_task_b;

  -- A separate future commitment must survive completion of the waiting
  -- dependency and remain represented by the Task's single active Radar item.
  INSERT INTO public.followups(
    task_id, responsible_id, status, next_action, next_followup_at,
    last_movement_at, notes
  ) VALUES (
    v_task_b, v_actor, 'pending', 'Compromiso futuro independiente',
    now() + interval '5 days', now(), 'Revisar entrega posterior'
  );

  INSERT INTO qa_p1_ids VALUES (
    v_actor, v_denied, v_portal, v_task_a, v_task_b, v_ticket, v_ticket_status
  );

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object('sub', v_actor, 'role', 'authenticated')::text,
    true
  );
  PERFORM set_config('request.jwt.claim.sub', v_actor::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
END
$$;

SET LOCAL ROLE authenticated;

DO $$
DECLARE
  v_actor uuid := auth.uid();
  v_task_a uuid;
  v_task_b uuid;
  v_ticket uuid;
  v_ticket_status text;
  v_status text;
  v_reason text;
  v_history_count bigint;
  v_followup_id uuid;
  v_followup_after uuid;
  v_radar_count integer;
  v_pending_count integer;
  v_radar_state text;
  v_radar_followup uuid;
  v_metadata jsonb;
BEGIN
  SELECT task_without_other_commitment, task_with_other_commitment, ticket_id, ticket_status
  INTO v_task_a, v_task_b, v_ticket, v_ticket_status FROM qa_p1_ids;

  IF v_actor IS NULL THEN RAISE EXCEPTION 'FAIL: auth.uid() is null'; END IF;

  -- D1: invalid wait context is rejected without a state or history write.
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_a, p_status => 'waiting', p_expected_status => 'pending'
    );
    RAISE EXCEPTION 'FAIL: waiting without dependency was accepted';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'TASK_WAITING_CONTEXT_REQUIRED%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_a, p_status => 'waiting', p_waiting_on => 'Aprobación',
      p_expected_status => 'pending'
    );
    RAISE EXCEPTION 'FAIL: waiting without review date or condition was accepted';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'TASK_WAITING_REVIEW_OR_CONDITION_REQUIRED%' THEN RAISE; END IF;
  END;

  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'waiting', p_waiting_on => 'Aprobación externa',
    p_waiting_condition => 'Confirmar recepción de aprobación',
    p_waiting_review_at => now() + interval '1 day', p_expected_status => 'pending'
  );
  SELECT id INTO v_followup_id FROM public.followups
  WHERE task_id = v_task_a AND status::text = 'pending'
    AND next_action = 'Revisar dependencia: Aprobación externa';
  SELECT count(*) INTO v_radar_count FROM public.radar_items
  WHERE source_type = 'task' AND source_id = v_task_a AND state = 'active'
    AND legacy_followup_id = v_followup_id;
  IF v_followup_id IS NULL OR v_radar_count <> 1 THEN
    RAISE EXCEPTION 'FAIL: waiting did not create exactly one linked Followup/Radar';
  END IF;
  RAISE NOTICE 'PASS: waiting context creates one linked continuity';

  -- Leaving ESPERANDO without verified evidence does not close the loop.
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'in_progress', p_expected_status => 'waiting'
  );
  SELECT count(*) INTO v_pending_count FROM public.followups
  WHERE task_id = v_task_a AND status::text = 'pending';
  SELECT count(*) INTO v_radar_count FROM public.radar_items
  WHERE source_type = 'task' AND source_id = v_task_a AND state = 'active';
  IF v_pending_count <> 1 OR v_radar_count <> 1 THEN
    RAISE EXCEPTION 'FAIL: state change closed an unverified waiting loop';
  END IF;
  RAISE NOTICE 'PASS: state change alone does not close the waiting loop';

  -- Re-entering the same wait reuses the wait Followup; the manual/other
  -- commitment is not overwritten.
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'waiting', p_waiting_on => 'Aprobación externa',
    p_waiting_condition => 'Respuesta recibida por correo',
    p_waiting_review_at => now() + interval '2 days', p_expected_status => 'in_progress'
  );
  SELECT id INTO v_followup_after FROM public.followups
  WHERE task_id = v_task_a AND status::text = 'pending'
    AND next_action = 'Revisar dependencia: Aprobación externa';
  SELECT count(*) INTO v_pending_count FROM public.followups
  WHERE task_id = v_task_a AND status::text = 'pending';
  IF v_followup_after IS DISTINCT FROM v_followup_id OR v_pending_count <> 1 THEN
    RAISE EXCEPTION 'FAIL: wait re-entry duplicated or replaced its own loop';
  END IF;
  RAISE NOTICE 'PASS: wait re-entry updates the same Followup';

  -- D1: only an explicit verification with evidence closes the wait. With no
  -- other obligation, Radar closes and history keeps the proof.
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'in_progress', p_expected_status => 'waiting',
    p_waiting_condition_satisfied => true,
    p_waiting_resolution_evidence => 'Aprobación recibida y comprobada en el correo del proyecto'
  );
  SELECT status::text INTO v_status FROM public.tasks WHERE id = v_task_a;
  SELECT status::text INTO v_status FROM public.followups
  WHERE id = v_followup_id;
  IF v_status <> 'done' THEN RAISE EXCEPTION 'FAIL: verified waiting Followup stayed open'; END IF;
  SELECT count(*) INTO v_radar_count FROM public.radar_items
  WHERE source_type = 'task' AND source_id = v_task_a AND state = 'active';
  IF v_radar_count <> 0 THEN RAISE EXCEPTION 'FAIL: Radar remains active after the only verified loop closed'; END IF;
  SELECT metadata INTO v_metadata FROM public.task_status_history
  WHERE task_id = v_task_a AND to_status = 'in_progress'
  ORDER BY occurred_at DESC, id DESC LIMIT 1;
  IF v_metadata->>'waiting_resolution_evidence' IS DISTINCT FROM
     'Aprobación recibida y comprobada en el correo del proyecto' THEN
    RAISE EXCEPTION 'FAIL: verified wait evidence missing from history';
  END IF;
  RAISE NOTICE 'PASS: verified wait closure is traced and closes the only Radar loop';

  -- D6: a same-destination retry is successful and writes no duplicate history.
  SELECT count(*) INTO v_history_count FROM public.task_status_history WHERE task_id = v_task_a;
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'in_progress', p_expected_status => 'waiting'
  );
  IF (SELECT count(*) FROM public.task_status_history WHERE task_id = v_task_a) <> v_history_count THEN
    RAISE EXCEPTION 'FAIL: same-destination retry duplicated history';
  END IF;
  RAISE NOTICE 'PASS: repeated destination is idempotent with no extra history';

  -- Leaving ESPERANDO for BLOQUEADA keeps the still-valid external continuity;
  -- returning to ESPERANDO reuses it rather than creating another loop.
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'waiting', p_waiting_on => 'Aprobación externa',
    p_waiting_condition => 'Esperar evidencia',
    p_waiting_review_at => now() + interval '1 day', p_expected_status => 'in_progress'
  );
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'blocked', p_expected_status => 'waiting',
    p_blocked_reason => 'El acceso entregado no permite avanzar'
  );
  IF NOT EXISTS (SELECT 1 FROM public.tasks WHERE id = v_task_a
                 AND status::text = 'blocked'
                 AND blocked_reason = 'El acceso entregado no permite avanzar'
                 AND waiting_on IS NULL)
     OR (SELECT count(*) FROM public.followups WHERE task_id = v_task_a AND status::text='pending') <> 1
     OR (SELECT count(*) FROM public.radar_items WHERE source_type='task' AND source_id=v_task_a AND state='active') <> 1 THEN
    RAISE EXCEPTION 'FAIL: wait-to-block lost context or left no valid continuity';
  END IF;
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'waiting', p_waiting_on => 'Aprobación externa',
    p_waiting_condition => 'Validar evidencia de acceso',
    p_waiting_review_at => now() + interval '2 days', p_expected_status => 'blocked'
  );
  IF (SELECT count(*) FROM public.followups WHERE task_id = v_task_a
      AND status::text='pending' AND next_action='Revisar dependencia: Aprobación externa') <> 1 THEN
    RAISE EXCEPTION 'FAIL: return from blocker duplicated the wait loop';
  END IF;
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_a, p_status => 'in_progress', p_expected_status => 'waiting',
    p_waiting_condition_satisfied => true,
    p_waiting_resolution_evidence => 'Acceso comprobado y habilitado'
  );
  IF (SELECT count(*) FROM public.radar_items WHERE source_type='task' AND source_id=v_task_a AND state='active') <> 0 THEN
    RAISE EXCEPTION 'FAIL: resolved wait did not close its only continuity';
  END IF;
  RAISE NOTICE 'PASS: wait-to-block preserves valid Radar and verified resolution closes it';

  -- D1/D2: a second pending commitment remains active when the wait is resolved.
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_b, p_status => 'waiting', p_waiting_on => 'Respuesta del cliente',
    p_waiting_condition => 'Confirmar recepción de respuesta',
    p_waiting_review_at => now() + interval '1 day', p_expected_status => 'pending'
  );
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_b, p_status => 'in_progress', p_expected_status => 'waiting',
    p_waiting_condition_satisfied => true,
    p_waiting_resolution_evidence => 'Respuesta del cliente recibida y revisada'
  );
  SELECT count(*) INTO v_pending_count FROM public.followups
  WHERE task_id = v_task_b AND status::text = 'pending';
  SELECT count(*) INTO v_radar_count
  FROM public.radar_items
  WHERE source_type = 'task' AND source_id = v_task_b AND state = 'active';
  SELECT legacy_followup_id INTO v_radar_followup
  FROM public.radar_items
  WHERE source_type = 'task' AND source_id = v_task_b AND state = 'active'
  ORDER BY id LIMIT 1;
  SELECT id INTO v_followup_after FROM public.followups
  WHERE task_id = v_task_b AND status::text = 'pending'
    AND next_action = 'Compromiso futuro independiente';
  IF v_pending_count <> 1 OR v_radar_count <> 1
     OR v_radar_followup IS DISTINCT FROM v_followup_after THEN
    RAISE EXCEPTION 'FAIL: unrelated future commitment was lost or not represented in Radar';
  END IF;
  RAISE NOTICE 'PASS: Radar promotes the remaining independent commitment';

  -- D5 / ACC-TASK-005: completing a Task does not change its linked Ticket or
  -- close the separate future commitment.
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_b, p_status => 'completed', p_expected_status => 'in_progress'
  );
  IF (SELECT status::text FROM public.tickets WHERE id = v_ticket) <> v_ticket_status THEN
    RAISE EXCEPTION 'FAIL: completing Task changed the Ticket state';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.followups WHERE id = v_followup_after AND status::text = 'pending')
     OR NOT EXISTS (SELECT 1 FROM public.radar_items WHERE source_type='task' AND source_id=v_task_b AND state='active') THEN
    RAISE EXCEPTION 'FAIL: completing Task closed a still-valid future commitment';
  END IF;
  RAISE NOTICE 'PASS: Task completion preserves Ticket status and future Radar commitment';

  -- D2: COMPLETADA and CANCELADA remain different results; cancellation of a
  -- completed Task is rejected, but completed Tasks may reopen with a reason.
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_b, p_status => 'cancelled', p_expected_status => 'completed',
      p_reason => 'No corresponde'
    );
    RAISE EXCEPTION 'FAIL: completed Task transitioned directly to cancelled';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'TASK_TRANSITION_NOT_ALLOWED%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_b, p_status => 'pending', p_expected_status => 'completed'
    );
    RAISE EXCEPTION 'FAIL: completed Task reopened without reason';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'TASK_REOPEN_REASON_REQUIRED%' THEN RAISE; END IF;
  END;
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_b, p_status => 'pending', p_expected_status => 'completed',
    p_reason => 'Se recibió nueva información para retomar la acción'
  );
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_b, p_status => 'cancelled', p_expected_status => 'pending',
    p_reason => 'La solicitud dejó de ser necesaria'
  );
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_b, p_status => 'in_progress', p_expected_status => 'cancelled',
      p_reason => 'Recuperación directa no permitida'
    );
    RAISE EXCEPTION 'FAIL: cancelled Task reopened directly to in_progress';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'TASK_TRANSITION_NOT_ALLOWED%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_b, p_status => 'pending', p_expected_status => 'cancelled'
    );
    RAISE EXCEPTION 'FAIL: cancelled Task reopened without reason';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'TASK_REOPEN_REASON_REQUIRED%' THEN RAISE; END IF;
  END;
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task_b, p_status => 'pending', p_expected_status => 'cancelled',
    p_reason => 'La solicitud volvió a ser válida y fue autorizada'
  );
  SELECT reason INTO v_reason FROM public.task_status_history
  WHERE task_id = v_task_b AND from_status = 'cancelled' AND to_status = 'pending'
  ORDER BY occurred_at DESC, id DESC LIMIT 1;
  IF v_reason IS DISTINCT FROM 'La solicitud volvió a ser válida y fue autorizada' THEN
    RAISE EXCEPTION 'FAIL: cancelled-task reopening reason missing from history';
  END IF;
  RAISE NOTICE 'PASS: completed/cancelled distinction and reasoned reopen history';

  -- D6: another writer's stale incompatible destination is rejected without
  -- partial state/history writes; the caller must reload before retrying.
  SELECT count(*) INTO v_history_count FROM public.task_status_history WHERE task_id = v_task_b;
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_b, p_status => 'blocked', p_expected_status => 'cancelled',
      p_blocked_reason => 'Stale operation'
    );
    RAISE EXCEPTION 'FAIL: stale incompatible destination was accepted';
  EXCEPTION WHEN SQLSTATE '40001' THEN
    IF SQLERRM NOT LIKE 'TASK_STATE_CONFLICT_REFRESH%' THEN RAISE; END IF;
  END;
  IF (SELECT status::text FROM public.tasks WHERE id = v_task_b) <> 'pending'
     OR (SELECT count(*) FROM public.task_status_history WHERE task_id = v_task_b) <> v_history_count THEN
    RAISE EXCEPTION 'FAIL: stale conflict left partial writes';
  END IF;
  RAISE NOTICE 'PASS: stale incompatible operation is a clean refresh conflict';

  -- Only the assignee or explicit view scope can read history; view scope does not write.
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', (SELECT denied_actor FROM qa_p1_ids), 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', (SELECT denied_actor::text FROM qa_p1_ids), true);
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_b, p_status => 'in_progress', p_expected_status => 'pending'
    );
    RAISE EXCEPTION 'FAIL: unassigned actor without explicit task scope transitioned a foreign task';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_NOT_FOUND_OR_FORBIDDEN%' THEN RAISE; END IF;
  END;
  IF (SELECT count(*) FROM public.task_status_history WHERE task_id = v_task_b) <> 0
     OR (SELECT count(*) FROM public.tasks WHERE id = v_task_b) <> 0 THEN
    -- The caller must not see either the task or its history.
    RAISE EXCEPTION 'FAIL: foreign task/history became visible';
  END IF;
  RAISE NOTICE 'PASS: unassigned actor without explicit scope cannot mutate/read foreign Task';

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', (SELECT portal_actor FROM qa_p1_ids), 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', (SELECT portal_actor::text FROM qa_p1_ids), true);
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task_a, p_status => 'blocked', p_expected_status => 'in_progress',
      p_blocked_reason => 'Portal no debe cambiar tareas internas'
    );
    RAISE EXCEPTION 'FAIL: Portal user transitioned an internal Task';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_TRANSITION_UNAUTHORIZED%' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'PASS: Portal identity is denied internal Task transitions';
END
$$;

RESET ROLE;

-- Inactive-user rejection is checked using an existing internal identity; all
-- changes are rolled back with the fixture transaction.
DO $$
DECLARE v_actor uuid;
BEGIN
  SELECT actor INTO v_actor FROM qa_p1_ids;
  UPDATE public.profiles SET active = false WHERE id = v_actor;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor, 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', v_actor::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
END
$$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_actor uuid; v_task uuid;
BEGIN
  SELECT actor, task_without_other_commitment INTO v_actor, v_task FROM qa_p1_ids;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor, 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', v_actor::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task, p_status => 'blocked', p_expected_status => 'in_progress',
      p_blocked_reason => 'No debe ejecutarse'
    );
    RAISE EXCEPTION 'FAIL: inactive user transitioned a Task';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_TRANSITION_UNAUTHORIZED%' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'PASS: inactive internal profile is denied';
END
$$;
RESET ROLE;
UPDATE public.profiles SET active = true WHERE id = (SELECT actor FROM qa_p1_ids);

-- Force a failure after the Task/history write but before successful
-- Followup/Radar resolution. The statement savepoint must roll all of it back.
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_actor uuid; v_task uuid;
BEGIN
  SELECT actor, task_without_other_commitment INTO v_actor, v_task FROM qa_p1_ids;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor, 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', v_actor::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  PERFORM public.transition_task_operational_status(
    p_task_id => v_task, p_status => 'waiting', p_expected_status => 'in_progress',
    p_waiting_on => 'Confirmación pendiente',
    p_waiting_condition => 'Validar recepción',
    p_waiting_review_at => now() + interval '1 day'
  );
END
$$;
RESET ROLE;
ALTER TABLE public.followups
  ADD CONSTRAINT qa_p1_force_followup_failure
  CHECK (status::text <> 'done') NOT VALID;
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_actor uuid; v_task uuid; v_history bigint; v_status text; v_pending bigint; v_active bigint;
BEGIN
  SELECT actor, task_without_other_commitment INTO v_actor, v_task FROM qa_p1_ids;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor, 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', v_actor::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  SELECT count(*) INTO v_history FROM public.task_status_history WHERE task_id = v_task;
  BEGIN
    PERFORM public.transition_task_operational_status(
      p_task_id => v_task, p_status => 'in_progress', p_expected_status => 'waiting',
      p_waiting_condition_satisfied => true,
      p_waiting_resolution_evidence => 'Atomicity proof'
    );
    RAISE EXCEPTION 'FAIL: forced followup failure did not occur';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
  SELECT status::text INTO v_status FROM public.tasks WHERE id = v_task;
  SELECT count(*) INTO v_pending FROM public.followups
  WHERE task_id = v_task AND status::text = 'pending';
  SELECT count(*) INTO v_active FROM public.radar_items
  WHERE source_type = 'task' AND source_id = v_task AND state = 'active';
  IF v_status NOT IN ('waiting', 'waiting_client')
     OR (SELECT count(*) FROM public.task_status_history WHERE task_id = v_task) <> v_history
     OR v_pending <> 1 OR v_active <> 1 THEN
    RAISE EXCEPTION 'FAIL: forced failure left partial Task/history/Followup/Radar writes';
  END IF;
  RAISE NOTICE 'PASS: later Followup failure rolls Task/history/Radar back atomically';
END
$$;
RESET ROLE;
ALTER TABLE public.followups DROP CONSTRAINT qa_p1_force_followup_failure;

-- Raw UPDATE cannot bypass the RPC state machine even for the current assignee.
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_actor uuid; v_task uuid;
BEGIN
  SELECT actor, task_without_other_commitment INTO v_actor, v_task FROM qa_p1_ids;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor, 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', v_actor::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  -- Custom GUCs are client-settable, so spoofing the transition markers must
  -- not let an authenticated assignee bypass the RPC/history/Radar transaction.
  PERFORM set_config('app.task_transition_task_id', v_task::text, true);
  PERFORM set_config('app.task_transition_actor', v_actor::text, true);
  BEGIN
    UPDATE public.tasks SET status = 'blocked' WHERE id = v_task;
    RAISE EXCEPTION 'FAIL: forged transition markers bypassed the RPC';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    IF SQLERRM NOT LIKE 'TASK_STATUS_RPC_REQUIRED%' THEN RAISE; END IF;
  END;
  RAISE NOTICE 'PASS: forged client markers cannot bypass the RPC';
END
$$;
RESET ROLE;

-- Explicit delete_tasks permits audited archival only. The Task and its
-- history remain present, repeated archives do not duplicate audit rows, and
-- hard deletion is rejected. All permission changes and fixtures roll back.
UPDATE public.user_permissions SET delete_tasks = true
WHERE user_id = (SELECT actor FROM qa_p1_ids);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_actor uuid; v_task uuid; v_history bigint; v_archive_count bigint;
BEGIN
  SELECT actor, task_without_other_commitment INTO v_actor, v_task FROM qa_p1_ids;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_actor,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_actor::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  SELECT count(*) INTO v_history FROM public.task_status_history WHERE task_id=v_task;
  PERFORM public.archive_task(v_task,'Solicitud duplicada; archivado autorizado para QA');
  PERFORM public.archive_task(v_task,'Reintento equivalente sin duplicar auditoría');
  SELECT count(*) INTO v_archive_count FROM public.task_archive_history WHERE task_id=v_task;
  IF v_archive_count <> 1
     OR NOT EXISTS (SELECT 1 FROM public.tasks WHERE id=v_task AND archived_at IS NOT NULL AND archived_by=v_actor)
     OR (SELECT count(*) FROM public.task_status_history WHERE task_id=v_task) <> v_history THEN
    RAISE EXCEPTION 'FAIL: archive did not preserve task/history or created duplicate audit';
  END IF;
  BEGIN
    DELETE FROM public.tasks WHERE id=v_task;
    RAISE EXCEPTION 'FAIL: direct hard delete was permitted';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    NULL;
  END;
  IF NOT EXISTS (SELECT 1 FROM public.tasks WHERE id=v_task AND archived_at IS NOT NULL)
     OR (SELECT count(*) FROM public.task_status_history WHERE task_id=v_task) <> v_history THEN
    RAISE EXCEPTION 'FAIL: hard delete removed an archived Task or its history';
  END IF;
  BEGIN
    PERFORM public.archive_task(
      (SELECT task_with_other_commitment FROM qa_p1_ids),
      'No debe archivar una tarea con continuidad abierta'
    );
    RAISE EXCEPTION 'FAIL: archived a Task with active Followup/Radar';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'TASK_ARCHIVE_ACTIVE_CONTINUITY%' THEN RAISE; END IF;
  END;
  IF EXISTS (SELECT 1 FROM public.tasks WHERE id=(SELECT task_with_other_commitment FROM qa_p1_ids) AND archived_at IS NOT NULL) THEN
    RAISE EXCEPTION 'FAIL: active continuity archive rejection left partial Task writes';
  END IF;
  RAISE NOTICE 'PASS: delete_tasks archives with reason, retains history, and forbids hard delete';
END
$$;
RESET ROLE;

ROLLBACK;

\echo PASS: temporary Auth grants restored to their pre-test state
SELECT 1 / CASE WHEN
  has_schema_privilege('authenticated', 'auth', 'USAGE') IS NOT DISTINCT FROM :'qa_auth_usage_before'::boolean
  AND has_function_privilege('authenticated', 'auth.uid()', 'EXECUTE') IS NOT DISTINCT FROM :'qa_auth_uid_before'::boolean
  THEN 1 ELSE 0 END AS temporary_auth_grants_restored;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.tasks WHERE title IN ('QA-P1-TASK-RADAR-A','QA-P1-TASK-RADAR-B'))
     OR EXISTS (SELECT 1 FROM public.followups f JOIN public.tasks t ON t.id=f.task_id
       WHERE t.title IN ('QA-P1-TASK-RADAR-A','QA-P1-TASK-RADAR-B'))
     OR EXISTS (SELECT 1 FROM public.radar_items r
       WHERE r.source_type='task' AND r.source_id IN (
         'd0c0a000-0000-4000-8000-0000000000a1'::uuid,
         'd0c0a000-0000-4000-8000-0000000000a2'::uuid
       )) THEN
    RAISE EXCEPTION 'FAIL: residual P1 Task/Followup/Radar fixtures';
  END IF;
  IF EXISTS (SELECT 1 FROM public.task_archive_history
     WHERE task_id='d0c0a000-0000-4000-8000-0000000000a1'::uuid) THEN
    RAISE EXCEPTION 'FAIL: residual P1 archive audit fixture';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname='qa_p1_force_followup_failure') THEN
    RAISE EXCEPTION 'FAIL: temporary atomicity constraint remained';
  END IF;
  RAISE NOTICE 'PASS: zero fixtures, temporary constraint, or grants remain after ROLLBACK';
END
$$;
