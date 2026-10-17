-- Behavioral regression for explicit follow-up decisions after result verification.
-- Apply only after independent review and approval, against the isolated P1 lab.
-- This SQL harness assumes existing synthetic Supabase Auth profiles. It uses SET ROLE
-- plus JWT claims for SQL-level RLS assertions; it does not replace browser/token tests.
\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE qa_outcome_ids (
  actor uuid NOT NULL,
  denied_actor uuid,
  portal_actor uuid,
  source_task uuid NOT NULL,
  verification_close uuid NOT NULL,
  verification_review uuid NOT NULL,
  verification_corrective uuid NOT NULL,
  followup_close uuid NOT NULL,
  followup_review uuid NOT NULL,
  followup_corrective uuid NOT NULL
) ON COMMIT DROP;
GRANT SELECT ON qa_outcome_ids TO authenticated;

DO $$
DECLARE
  v_actor uuid;
  v_denied uuid;
  v_portal uuid;
  v_area text;
  v_type text;
  v_task constant uuid := 'd0c0a000-0000-4000-8000-0000000000b1';
  v_action_close constant uuid := 'd0c0a000-0000-4000-8000-0000000000b2';
  v_action_review constant uuid := 'd0c0a000-0000-4000-8000-0000000000b3';
  v_action_corrective constant uuid := 'd0c0a000-0000-4000-8000-0000000000b4';
  v_followup_close constant uuid := 'd0c0a000-0000-4000-8000-0000000000b5';
  v_followup_review constant uuid := 'd0c0a000-0000-4000-8000-0000000000b6';
  v_followup_corrective constant uuid := 'd0c0a000-0000-4000-8000-0000000000b7';
BEGIN
  SELECT p.id INTO v_actor
  FROM public.profiles p
  JOIN public.user_permissions up ON up.user_id = p.id
  WHERE p.active IS TRUE AND up.create_tasks IS TRUE
    AND NOT EXISTS (SELECT 1 FROM public.client_portal_users cpu WHERE cpu.user_id=p.id AND cpu.active IS TRUE)
  ORDER BY p.id LIMIT 1;
  SELECT p.id INTO v_denied
  FROM public.profiles p
  WHERE p.active IS TRUE AND p.id <> v_actor AND NOT coalesce(p.is_master,false)
    AND NOT EXISTS (SELECT 1 FROM public.client_portal_users cpu WHERE cpu.user_id=p.id AND cpu.active IS TRUE)
  ORDER BY p.id LIMIT 1;
  SELECT cpu.user_id INTO v_portal
  FROM public.client_portal_users cpu WHERE cpu.active IS TRUE ORDER BY cpu.user_id LIMIT 1;
  SELECT area,task_type INTO v_area,v_type FROM public.tasks ORDER BY id LIMIT 1;
  IF v_actor IS NULL OR v_area IS NULL OR v_type IS NULL OR v_portal IS NULL THEN
    RAISE EXCEPTION 'BLOCKED: synthetic internal owner, active Portal profile and task metadata are required';
  END IF;
  IF EXISTS (SELECT 1 FROM public.tasks WHERE id=v_task)
     OR EXISTS (SELECT 1 FROM public.followups WHERE id IN (v_followup_close,v_followup_review,v_followup_corrective)) THEN
    RAISE EXCEPTION 'BLOCKED: deterministic QA fixture IDs already exist';
  END IF;
  INSERT INTO public.tasks(id,title,area,task_type,created_by,assignee_id)
  VALUES(v_task,'QA-OUTCOME-FOLLOWUP-DECISIONS',v_area,v_type,v_actor,v_actor);
  INSERT INTO qa_outcome_ids VALUES(
    v_actor,v_denied,v_portal,v_task,
    'd0c0a000-0000-4000-8000-0000000000c1',
    'd0c0a000-0000-4000-8000-0000000000c2',
    'd0c0a000-0000-4000-8000-0000000000c3',
    v_followup_close,v_followup_review,v_followup_corrective
  );
END
$$;

-- Use the real task-transition RPC under the authorized fixture's identity.
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_actor uuid; v_task uuid;
BEGIN
  SELECT actor,source_task INTO v_actor,v_task FROM qa_outcome_ids;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_actor,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_actor::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM public.transition_task_operational_status(
    p_task_id=>v_task,p_status=>'in_progress',p_expected_status=>'pending'
  );
  PERFORM public.transition_task_operational_status(
    p_task_id=>v_task,p_status=>'completed',p_expected_status=>'in_progress'
  );
END
$$;
RESET ROLE;

-- Prepare three distinct B followups against the same completed task.
DO $$
DECLARE v_actor uuid; v_task uuid; v_a uuid; v_b uuid; v_c uuid;
BEGIN
  SELECT actor,source_task,verification_close,verification_review,verification_corrective
    INTO v_actor,v_task,v_a,v_b,v_c FROM qa_outcome_ids;
  INSERT INTO public.followups(id,task_id,responsible_id,status,next_action,next_followup_at,last_movement_at,notes)
  SELECT followup_id,v_task,v_actor,'pending',action,now(),now(),'Keep this evidence'
  FROM (VALUES
    ((SELECT followup_close FROM qa_outcome_ids),'Verify achieved'),
    ((SELECT followup_review FROM qa_outcome_ids),'Verify not achieved'),
    ((SELECT followup_corrective FROM qa_outcome_ids),'Verify inconclusive')
  ) AS x(followup_id,action);
  INSERT INTO public.task_continuity_actions(id,source_task_id,option_code,actor_id,request_id,request_payload,followup_id)
  VALUES
    (v_a,v_task,'B',v_actor,gen_random_uuid(),jsonb_build_object('fixture','close'),(SELECT followup_close FROM qa_outcome_ids)),
    (v_b,v_task,'B',v_actor,gen_random_uuid(),jsonb_build_object('fixture','review'),(SELECT followup_review FROM qa_outcome_ids)),
    (v_c,v_task,'B',v_actor,gen_random_uuid(),jsonb_build_object('fixture','corrective'),(SELECT followup_corrective FROM qa_outcome_ids));
  INSERT INTO public.task_outcome_verifications(
    id,continuity_action_id,source_task_id,followup_id,expected_result,observation_method,expected_source
  ) VALUES
    (v_a,v_a,v_task,(SELECT followup_close FROM qa_outcome_ids),'Mejora observada','Comparación antes/después','Fuente QA'),
    (v_b,v_b,v_task,(SELECT followup_review FROM qa_outcome_ids),'Respuesta recibida','Consulta registrada','Fuente QA'),
    (v_c,v_c,v_task,(SELECT followup_corrective FROM qa_outcome_ids),'Servicio operativo','Prueba funcional','Fuente QA');
END
$$;

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  v_actor uuid; v_task uuid;
  v_close uuid := 'd0c0a000-0000-4000-8000-0000000000c1';
  v_review uuid := 'd0c0a000-0000-4000-8000-0000000000c2';
  v_corrective uuid := 'd0c0a000-0000-4000-8000-0000000000c3';
  v_request uuid := 'd0c0a000-0000-4000-8000-0000000000d1';
  v_result record; v_pending integer; v_status text;
BEGIN
  SELECT actor,source_task INTO v_actor,v_task FROM qa_outcome_ids;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_actor,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_actor::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  PERFORM public.record_task_outcome_verification(v_close,'d0c0a000-0000-4000-8000-0000000000e1','Resultado alcanzado','Evidencia: medición QA 91/100','Informe QA','achieved');
  PERFORM public.record_task_outcome_verification(v_review,'d0c0a000-0000-4000-8000-0000000000e2','Aún sin respuesta','Evidencia: no existe respuesta registrada','Registro QA','not_achieved');
  PERFORM public.record_task_outcome_verification(v_corrective,'d0c0a000-0000-4000-8000-0000000000e3','Evidencia insuficiente','Evidencia: muestra incompleta','Medición pendiente','inconclusive');
  SELECT * INTO v_result FROM public.record_task_outcome_verification(v_close,'d0c0a000-0000-4000-8000-0000000000e1','Resultado alcanzado','Evidencia: medición QA 91/100','Informe QA','achieved');
  IF NOT v_result.replayed THEN RAISE EXCEPTION 'FAIL: same outcome request was not idempotent'; END IF;
  BEGIN
    PERFORM public.record_task_outcome_verification(v_close,'d0c0a000-0000-4000-8000-0000000000e1','Texto cambiado','Evidencia: medición QA 91/100','Informe QA','achieved');
    RAISE EXCEPTION 'FAIL: reused outcome key with a different payload was accepted';
  EXCEPTION WHEN SQLSTATE '22023' THEN NULL;
  END;
  SELECT status::text INTO v_status FROM public.tasks WHERE id=v_task;
  SELECT count(*)::integer INTO v_pending FROM public.followups WHERE task_id=v_task AND status::text='pending';
  IF v_status<>'completed' OR v_pending<>3 THEN
    RAISE EXCEPTION 'FAIL: recording any conclusion changed Task or Followup state';
  END IF;
  RAISE NOTICE 'PASS: achieved/not-achieved/inconclusive preserve the completed Task and all pending followups';

  -- Explicit close updates only this B followup; a same-key retry is idempotent.
  SELECT * INTO v_result FROM public.decide_task_outcome_followup(v_close,v_request,'close');
  IF v_result.replayed OR v_result.remaining_pending_count<>2 THEN
    RAISE EXCEPTION 'FAIL: explicit close did not preserve the other commitments';
  END IF;
  SELECT * INTO v_result FROM public.decide_task_outcome_followup(v_close,v_request,'close');
  IF NOT v_result.replayed THEN RAISE EXCEPTION 'FAIL: close retry was not idempotent'; END IF;
  IF (SELECT status::text FROM public.followups WHERE id=(SELECT followup_close FROM qa_outcome_ids))<>'done'
     OR (SELECT count(*) FROM public.task_outcome_verification_events WHERE verification_id=v_close)<>1
     OR NOT EXISTS (SELECT 1 FROM public.radar_items WHERE source_type='task' AND source_id=v_task AND state='active') THEN
    RAISE EXCEPTION 'FAIL: close lost evidence, failed to sync Radar, or closed other pending commitments';
  END IF;
  RAISE NOTICE 'PASS: explicit close preserves evidence, syncs Radar and leaves other followups open';

  -- Replaying the original successful write remains idempotent after closure.
  SELECT * INTO v_result FROM public.record_task_outcome_verification(
    v_close,'d0c0a000-0000-4000-8000-0000000000e1',
    'Resultado alcanzado','Evidencia: medición QA 91/100','Informe QA','achieved'
  );
  IF NOT v_result.replayed THEN
    RAISE EXCEPTION 'FAIL: exact outcome retry failed after explicit close';
  END IF;

  -- A closed B commitment rejects a new result request without appending evidence.
  BEGIN
    PERFORM public.record_task_outcome_verification(
      v_close,'d0c0a000-0000-4000-8000-0000000000e4',
      'Resultado tardío','Evidencia posterior al cierre','Informe QA','achieved'
    );
    RAISE EXCEPTION 'FAIL: recorded a result against a closed followup';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'TASK_OUTCOME_FOLLOWUP_NOT_PENDING%' THEN RAISE; END IF;
  END;
  IF (SELECT count(*) FROM public.task_outcome_verification_events WHERE verification_id=v_close)<>1 THEN
    RAISE EXCEPTION 'FAIL: rejected post-close result left evidence behind';
  END IF;
  RAISE NOTICE 'PASS: closed followup rejects later result writes without changing evidence';

  v_request := 'd0c0a000-0000-4000-8000-0000000000d2';
  SELECT * INTO v_result FROM public.decide_task_outcome_followup(
    v_review,v_request,'review','Revisar respuesta','Respuesta recibida',now()+interval '3 days'
  );
  IF v_result.replayed OR v_result.remaining_pending_count<>2 THEN
    RAISE EXCEPTION 'FAIL: reschedule closed or duplicated a commitment';
  END IF;
  SELECT * INTO v_result FROM public.decide_task_outcome_followup(
    v_review,v_request,'review','Revisar respuesta','Respuesta recibida',now()+interval '3 days'
  );
  IF NOT v_result.replayed OR NOT EXISTS (
    SELECT 1 FROM public.followups WHERE id=(SELECT followup_review FROM qa_outcome_ids)
      AND status::text='pending' AND next_action='Revisar respuesta'
  ) THEN
    RAISE EXCEPTION 'FAIL: reschedule did not update the same Followup idempotently';
  END IF;
  RAISE NOTICE 'PASS: reschedule updates the same active Followup and is idempotent';

  v_request := 'd0c0a000-0000-4000-8000-0000000000d3';
  SELECT * INTO v_result FROM public.decide_task_outcome_followup(
    v_corrective,v_request,'corrective_task',
    p_corrective_title=>'Corregir hallazgo QA',
    p_corrective_context=>'Acción ficticia vinculada a la medición',
    p_corrective_due_date=>current_date+3
  );
  IF v_result.created_task_id IS NULL OR v_result.remaining_pending_count<>2
     OR (SELECT status::text FROM public.followups WHERE id=(SELECT followup_corrective FROM qa_outcome_ids))<>'pending'
     OR (SELECT status::text FROM public.tasks WHERE id=v_task)<>'completed'
     OR NOT EXISTS (SELECT 1 FROM public.task_continuity_actions
          WHERE source_task_id=v_task AND child_task_id=v_result.created_task_id AND option_code='C') THEN
    RAISE EXCEPTION 'FAIL: corrective task failed to link atomically or closed B followup';
  END IF;
  RAISE NOTICE 'PASS: corrective action is linked; its B followup and completed source remain intact';

  BEGIN
    PERFORM public.decide_task_outcome_followup(
      v_review,gen_random_uuid(),'review',p_next_action=>'Missing date and condition'
    );
    RAISE EXCEPTION 'FAIL: invalid review details were accepted';
  EXCEPTION WHEN SQLSTATE '22023' THEN NULL;
  END;
  RAISE NOTICE 'PASS: invalid review decision is rejected';

  -- After the rescheduled and corrective commitments are explicitly closed,
  -- the task-level Radar row closes; no earlier outcome recorded it implicitly.
  PERFORM public.decide_task_outcome_followup(v_review,gen_random_uuid(),'close');
  PERFORM public.decide_task_outcome_followup(v_corrective,gen_random_uuid(),'close');
  SELECT count(*)::integer INTO v_pending FROM public.followups WHERE task_id=v_task AND status::text='pending';
  IF v_pending<>0 OR EXISTS (SELECT 1 FROM public.radar_items WHERE source_type='task' AND source_id=v_task AND state='active') THEN
    RAISE EXCEPTION 'FAIL: closing the remaining commitments did not synchronize task Radar';
  END IF;
  RAISE NOTICE 'PASS: Radar closes only after the last linked Followup is explicitly closed';
END
$$;
RESET ROLE;

-- An internal user outside this Task's write scope is denied.
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_actor uuid; v_task uuid; v_verification uuid;
BEGIN
  SELECT denied_actor,source_task,verification_review INTO v_actor,v_task,v_verification FROM qa_outcome_ids;
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'BLOCKED: second internal profile required for negative authorization case';
  END IF;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_actor,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_actor::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  BEGIN
    PERFORM public.decide_task_outcome_followup(v_verification,gen_random_uuid(),'close');
    RAISE EXCEPTION 'FAIL: unauthorized actor decided another internal Followup';
  EXCEPTION WHEN SQLSTATE '42501' THEN NULL;
  END;
  RAISE NOTICE 'PASS: internal user without Task write scope is denied';
END
$$;

-- Portal is denied by the RPC's internal-only guard.
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_actor uuid; v_verification uuid;
BEGIN
  SELECT portal_actor,verification_review INTO v_actor,v_verification FROM qa_outcome_ids;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_actor,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_actor::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  BEGIN
    PERFORM public.decide_task_outcome_followup(v_verification,gen_random_uuid(),'close');
    RAISE EXCEPTION 'FAIL: Portal actor decided an internal B Followup';
  EXCEPTION WHEN SQLSTATE '42501' THEN NULL;
  END;
  RAISE NOTICE 'PASS: Portal actor is denied';
END
$$;
RESET ROLE;

ROLLBACK;
\echo PASS: all outcome/follow-up fixtures and mutations rolled back.
