BEGIN;

-- M03: persist the context needed to distinguish a normal wait from a real
-- blocker, and keep internal targets separate from external commitments.
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS waiting_on text,
  ADD COLUMN IF NOT EXISTS waiting_condition text,
  ADD COLUMN IF NOT EXISTS waiting_review_at timestamptz,
  ADD COLUMN IF NOT EXISTS blocked_reason text,
  ADD COLUMN IF NOT EXISTS blocked_unblocker text,
  ADD COLUMN IF NOT EXISTS internal_target_date date;

-- Every state transition is recorded in the same transaction as its task and
-- continuity changes. Context is supplied only by the controlled RPC below.
CREATE OR REPLACE FUNCTION public.record_task_status_history()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reason text;
  v_context jsonb;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    v_reason := nullif(current_setting('app.task_transition_reason', true), '');
    v_context := coalesce(
      nullif(current_setting('app.task_transition_context', true), '')::jsonb,
      '{}'::jsonb
    );
    INSERT INTO public.task_status_history(
      task_id, from_status, to_status, actor_id, occurred_at, reason, metadata
    ) VALUES (
      NEW.id, OLD.status::text, NEW.status::text, auth.uid(), now(), v_reason,
      jsonb_build_object(
        'source', 'transition_task_operational_status',
        'waiting_on', OLD.waiting_on,
        'waiting_condition', OLD.waiting_condition,
        'waiting_review_at', OLD.waiting_review_at,
        'blocked_reason', OLD.blocked_reason,
        'blocked_unblocker', OLD.blocked_unblocker
      ) || v_context
    );
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.record_task_status_history()
FROM PUBLIC, anon, authenticated;

-- Prevent direct PostgREST UPDATEs from bypassing the state machine. Custom
-- GUC markers are client-settable, so they are accepted only while executing
-- as the owner of the authenticated, scope-checked SECURITY DEFINER RPC.
CREATE OR REPLACE FUNCTION public.guard_task_status_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND (
    current_user IS DISTINCT FROM (
      SELECT pg_get_userbyid(p.proowner)
      FROM pg_proc p
      WHERE p.oid = to_regprocedure(
        'public.transition_task_operational_status(uuid,text,text,text,text,timestamptz,text,text,text,boolean,text)'
      )
    )
    OR
    current_setting('app.task_transition_task_id', true) IS DISTINCT FROM NEW.id::text
    OR current_setting('app.task_transition_actor', true) IS DISTINCT FROM auth.uid()::text
  ) THEN
    RAISE EXCEPTION 'TASK_STATUS_RPC_REQUIRED' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.guard_task_status_transition()
FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_guard_task_status_transition ON public.tasks;
CREATE TRIGGER trg_guard_task_status_transition
BEFORE UPDATE OF status ON public.tasks
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.guard_task_status_transition();

-- One active Radar item represents the earliest pending continuity for a
-- Task. Closing one Followup selects the next still-open commitment instead
-- of closing the Task's Radar loop while another commitment remains.
CREATE OR REPLACE FUNCTION public.sync_followup_to_radar()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_followup public.followups%ROWTYPE;
  v_radar_id uuid;
  v_mapped_radar_id uuid;
BEGIN
  SELECT * INTO v_followup
  FROM public.followups f
  WHERE f.task_id = NEW.task_id
    AND f.status::text = 'pending'
  ORDER BY f.next_followup_at NULLS LAST, f.created_at, f.id
  LIMIT 1
  FOR UPDATE;

  SELECT r.id INTO v_radar_id
  FROM public.radar_items r
  WHERE r.source_type = 'task'
    AND r.source_id = NEW.task_id
    AND r.state = 'active'
  ORDER BY r.updated_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_followup.id IS NULL THEN
    UPDATE public.radar_items
    SET state = 'closed',
        closed_at = coalesce(closed_at, now()),
        last_movement_at = coalesce(NEW.last_movement_at, now()),
        updated_at = now()
    WHERE source_type = 'task'
      AND source_id = NEW.task_id
      AND state = 'active';
    RETURN NEW;
  END IF;

  SELECT r.id INTO v_mapped_radar_id
  FROM public.radar_items r
  WHERE r.legacy_followup_id = v_followup.id
  LIMIT 1
  FOR UPDATE;

  IF v_mapped_radar_id IS NOT NULL AND v_radar_id IS NOT NULL
     AND v_mapped_radar_id <> v_radar_id THEN
    UPDATE public.radar_items
    SET state = 'closed', closed_at = coalesce(closed_at, now()), updated_at = now()
    WHERE id = v_radar_id;
    UPDATE public.radar_items
    SET responsible_id = v_followup.responsible_id,
        state = 'active',
        next_action = v_followup.next_action,
        next_review_at = v_followup.next_followup_at,
        condition_text = coalesce(nullif(v_followup.notes, ''), 'Seguimiento operativo'),
        last_movement_at = coalesce(v_followup.last_movement_at, now()),
        closed_at = NULL,
        updated_at = now()
    WHERE id = v_mapped_radar_id;
  ELSIF v_radar_id IS NOT NULL THEN
    UPDATE public.radar_items
    SET responsible_id = v_followup.responsible_id,
        state = 'active',
        next_action = v_followup.next_action,
        next_review_at = v_followup.next_followup_at,
        condition_text = coalesce(nullif(v_followup.notes, ''), 'Seguimiento operativo'),
        last_movement_at = coalesce(v_followup.last_movement_at, now()),
        legacy_followup_id = v_followup.id,
        closed_at = NULL,
        updated_at = now()
    WHERE id = v_radar_id;
  ELSIF v_mapped_radar_id IS NOT NULL THEN
    UPDATE public.radar_items
    SET responsible_id = v_followup.responsible_id,
        state = 'active',
        next_action = v_followup.next_action,
        next_review_at = v_followup.next_followup_at,
        condition_text = coalesce(nullif(v_followup.notes, ''), 'Seguimiento operativo'),
        last_movement_at = coalesce(v_followup.last_movement_at, now()),
        closed_at = NULL,
        updated_at = now()
    WHERE id = v_mapped_radar_id;
  ELSE
    INSERT INTO public.radar_items(
      source_type, source_id, responsible_id, state, next_action,
      next_review_at, condition_text, last_movement_at, legacy_followup_id
    ) VALUES (
      'task', NEW.task_id, v_followup.responsible_id, 'active', v_followup.next_action,
      v_followup.next_followup_at,
      coalesce(nullif(v_followup.notes, ''), 'Seguimiento operativo'),
      coalesce(v_followup.last_movement_at, now()), v_followup.id
    )
    ON CONFLICT (source_type, source_id) WHERE state = 'active'
    DO UPDATE SET
      responsible_id = EXCLUDED.responsible_id,
      next_action = EXCLUDED.next_action,
      next_review_at = EXCLUDED.next_review_at,
      condition_text = EXCLUDED.condition_text,
      last_movement_at = EXCLUDED.last_movement_at,
      legacy_followup_id = EXCLUDED.legacy_followup_id,
      closed_at = NULL,
      updated_at = now();
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_followup_to_radar()
FROM PUBLIC, anon, authenticated;

-- Replace the legacy 8-argument RPC so concurrent callers must provide the
-- state they observed. Repeating the same destination is a successful no-op;
-- an incompatible stale destination returns a retryable conflict.
DROP FUNCTION IF EXISTS public.transition_task_operational_status(
  uuid, text, text, text, text, timestamptz, text, text
);

CREATE FUNCTION public.transition_task_operational_status(
  p_task_id uuid,
  p_status text,
  p_reason text DEFAULT NULL,
  p_waiting_on text DEFAULT NULL,
  p_waiting_condition text DEFAULT NULL,
  p_waiting_review_at timestamptz DEFAULT NULL,
  p_blocked_reason text DEFAULT NULL,
  p_blocked_unblocker text DEFAULT NULL,
  p_expected_status text DEFAULT NULL,
  p_waiting_condition_satisfied boolean DEFAULT false,
  p_waiting_resolution_evidence text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_task public.tasks%ROWTYPE;
  v_followup_id uuid;
  v_target public.tasks.status%TYPE;
  v_current_status text;
  v_expected_status text;
  v_storage_status text;
  v_status text := lower(btrim(coalesce(p_status, '')));
  v_context jsonb;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'TASK_TRANSITION_UNAUTHORIZED' USING ERRCODE = '42501';
  END IF;
  IF v_status NOT IN ('pending','in_progress','waiting','blocked','completed','cancelled') THEN
    RAISE EXCEPTION 'TASK_STATUS_INVALID' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_task
  FROM public.tasks
  WHERE id = p_task_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'TASK_NOT_FOUND_OR_FORBIDDEN' USING ERRCODE = '42501';
  END IF;

  v_current_status := CASE
    WHEN v_task.status::text = 'waiting_client' THEN 'waiting'
    WHEN v_task.status::text = 'paused' THEN 'in_progress'
    ELSE v_task.status::text
  END;

  -- Read scopes are not write grants. A task's assignee may work their task;
  -- another actor needs the explicit reassign_tasks mutation permission plus
  -- an explicit all-task or in-area scope. Role/title hierarchy is insufficient.
  IF v_task.assignee_id IS DISTINCT FROM auth.uid()
     AND NOT (
       public.has_task_permission('reassign_tasks')
       AND (
         public.has_task_permission('view_all_tasks')
         OR (
           public.has_task_permission('view_area_tasks')
           AND public.task_assignee_in_my_area(v_task.assignee_id)
         )
       )
     ) THEN
    RAISE EXCEPTION 'TASK_NOT_FOUND_OR_FORBIDDEN' USING ERRCODE = '42501';
  END IF;

  -- Idempotent retry: do not write a second history row or Radar/Followup.
  IF v_current_status = v_status THEN
    RETURN;
  END IF;

  IF nullif(btrim(p_expected_status), '') IS NULL THEN
    RAISE EXCEPTION 'TASK_EXPECTED_STATUS_REQUIRED' USING ERRCODE = '22023';
  END IF;
  v_expected_status := CASE lower(btrim(p_expected_status))
    WHEN 'waiting_client' THEN 'waiting'
    WHEN 'paused' THEN 'in_progress'
    ELSE lower(btrim(p_expected_status))
  END;
  IF v_expected_status IS DISTINCT FROM v_current_status THEN
    RAISE EXCEPTION 'TASK_STATE_CONFLICT_REFRESH' USING ERRCODE = '40001';
  END IF;

  v_storage_status := v_status;
  -- Keep compatibility with older Supabase enum labels while exposing the
  -- six canonical states to the application.
  IF v_status = 'waiting'
     AND EXISTS (
       SELECT 1 FROM pg_attribute a
       JOIN pg_type ty ON ty.oid = a.atttypid
       JOIN pg_enum e ON e.enumtypid = ty.oid AND e.enumlabel = 'waiting_client'
       WHERE a.attrelid = 'public.tasks'::regclass
         AND a.attname = 'status' AND ty.typtype = 'e'
     )
     AND NOT EXISTS (
       SELECT 1 FROM pg_attribute a
       JOIN pg_type ty ON ty.oid = a.atttypid
       JOIN pg_enum e ON e.enumtypid = ty.oid AND e.enumlabel = 'waiting'
       WHERE a.attrelid = 'public.tasks'::regclass
         AND a.attname = 'status' AND ty.typtype = 'e'
     ) THEN
    v_storage_status := 'waiting_client';
  END IF;
  v_target := v_storage_status;

  IF NOT (
    (v_current_status = 'pending' AND v_status IN ('in_progress','waiting','blocked','cancelled'))
    OR (v_current_status = 'in_progress' AND v_status IN ('pending','waiting','blocked','completed','cancelled'))
    OR (v_current_status = 'waiting' AND v_status IN ('pending','in_progress','blocked','cancelled'))
    OR (v_current_status = 'blocked' AND v_status IN ('pending','in_progress','waiting','cancelled'))
    OR (v_current_status = 'completed' AND v_status IN ('pending','in_progress'))
    OR (v_current_status = 'cancelled' AND v_status = 'pending')
  ) THEN
    RAISE EXCEPTION 'TASK_TRANSITION_NOT_ALLOWED' USING ERRCODE = '22023';
  END IF;

  IF v_current_status IN ('completed','cancelled')
     AND v_status IN ('pending','in_progress')
     AND nullif(btrim(p_reason), '') IS NULL THEN
    RAISE EXCEPTION 'TASK_REOPEN_REASON_REQUIRED' USING ERRCODE = '22023';
  END IF;
  IF v_status = 'cancelled' AND nullif(btrim(p_reason), '') IS NULL THEN
    RAISE EXCEPTION 'TASK_CANCEL_REASON_REQUIRED' USING ERRCODE = '22023';
  END IF;
  IF v_status = 'waiting' AND nullif(btrim(p_waiting_on), '') IS NULL THEN
    RAISE EXCEPTION 'TASK_WAITING_CONTEXT_REQUIRED' USING ERRCODE = '22023';
  END IF;
  IF v_status = 'waiting'
     AND p_waiting_review_at IS NULL
     AND nullif(btrim(p_waiting_condition), '') IS NULL THEN
    RAISE EXCEPTION 'TASK_WAITING_REVIEW_OR_CONDITION_REQUIRED' USING ERRCODE = '22023';
  END IF;
  IF v_status = 'blocked' AND nullif(btrim(p_blocked_reason), '') IS NULL THEN
    RAISE EXCEPTION 'TASK_BLOCK_REASON_REQUIRED' USING ERRCODE = '22023';
  END IF;
  IF p_waiting_condition_satisfied AND v_current_status <> 'waiting' THEN
    RAISE EXCEPTION 'TASK_WAITING_NOT_ACTIVE' USING ERRCODE = '22023';
  END IF;
  IF v_current_status = 'waiting' AND p_waiting_condition_satisfied
     AND nullif(btrim(p_waiting_resolution_evidence), '') IS NULL THEN
    RAISE EXCEPTION 'TASK_WAITING_RESOLUTION_EVIDENCE_REQUIRED' USING ERRCODE = '22023';
  END IF;
  IF NOT p_waiting_condition_satisfied
     AND nullif(btrim(p_waiting_resolution_evidence), '') IS NOT NULL THEN
    RAISE EXCEPTION 'TASK_WAITING_RESOLUTION_FLAG_REQUIRED' USING ERRCODE = '22023';
  END IF;

  v_context := jsonb_build_object(
    'expected_status', v_expected_status,
    'waiting_condition_satisfied', (v_current_status = 'waiting' AND p_waiting_condition_satisfied),
    'waiting_resolution_evidence', CASE WHEN v_current_status = 'waiting' AND p_waiting_condition_satisfied
      THEN btrim(p_waiting_resolution_evidence) ELSE NULL END
  );
  PERFORM set_config('app.task_transition_reason', coalesce(nullif(btrim(p_reason), ''), ''), true);
  PERFORM set_config('app.task_transition_context', v_context::text, true);
  PERFORM set_config('app.task_transition_task_id', p_task_id::text, true);
  PERFORM set_config('app.task_transition_actor', auth.uid()::text, true);

  UPDATE public.tasks
  SET status = v_target,
      completed_at = CASE WHEN v_status = 'completed' THEN now()
                          WHEN v_current_status = 'completed' THEN NULL
                          ELSE completed_at END,
      waiting_on = CASE WHEN v_status = 'waiting' THEN btrim(p_waiting_on) ELSE NULL END,
      waiting_condition = CASE WHEN v_status = 'waiting' THEN nullif(btrim(p_waiting_condition), '') ELSE NULL END,
      waiting_review_at = CASE WHEN v_status = 'waiting' THEN p_waiting_review_at ELSE NULL END,
      blocked_reason = CASE WHEN v_status = 'blocked' THEN btrim(p_blocked_reason) ELSE NULL END,
      blocked_unblocker = CASE WHEN v_status = 'blocked' THEN nullif(btrim(p_blocked_unblocker), '') ELSE NULL END,
      last_activity_at = now(),
      updated_at = now()
  WHERE id = p_task_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'TASK_NOT_FOUND_OR_FORBIDDEN' USING ERRCODE = '42501';
  END IF;

  IF v_status = 'waiting' THEN
    SELECT id INTO v_followup_id
    FROM public.followups
    WHERE task_id = p_task_id
      AND status::text = 'pending'
      AND left(coalesce(next_action, ''), length('Revisar dependencia: ')) = 'Revisar dependencia: '
      AND substring(next_action FROM length('Revisar dependencia: ') + 1) = btrim(p_waiting_on)
    ORDER BY created_at DESC
    LIMIT 1
    FOR UPDATE;

    IF v_followup_id IS NULL THEN
      INSERT INTO public.followups(
        task_id, responsible_id, status, next_action, next_followup_at,
        last_movement_at, notes
      ) VALUES (
        p_task_id, v_task.assignee_id, 'pending',
        'Revisar dependencia: ' || btrim(p_waiting_on),
        p_waiting_review_at, now(),
        coalesce(nullif(btrim(p_waiting_condition), ''), 'Esperando: ' || btrim(p_waiting_on))
      );
    ELSE
      UPDATE public.followups
      SET responsible_id = v_task.assignee_id,
          next_action = 'Revisar dependencia: ' || btrim(p_waiting_on),
          next_followup_at = p_waiting_review_at,
          last_movement_at = now(),
          notes = coalesce(nullif(btrim(p_waiting_condition), ''), 'Esperando: ' || btrim(p_waiting_on)),
          updated_at = now()
      WHERE id = v_followup_id;
    END IF;
  ELSIF v_current_status = 'waiting' AND p_waiting_condition_satisfied THEN
    -- Close only the verified wait loop. The trigger promotes another pending
    -- commitment for this Task or closes Radar if no obligation remains.
    UPDATE public.followups
    SET status = 'done',
        last_movement_at = now(),
        notes = concat_ws(E'\n', nullif(notes, ''),
          'Dependencia verificada por ' || auth.uid()::text || ': ' || btrim(p_waiting_resolution_evidence)),
        updated_at = now()
    WHERE task_id = p_task_id
      AND status::text = 'pending'
      AND left(coalesce(next_action, ''), length('Revisar dependencia: ')) = 'Revisar dependencia: '
      AND substring(next_action FROM length('Revisar dependencia: ') + 1) = coalesce(v_task.waiting_on, '');
  END IF;

  PERFORM set_config('app.task_transition_reason', '', true);
  PERFORM set_config('app.task_transition_context', '', true);
  PERFORM set_config('app.task_transition_task_id', '', true);
  PERFORM set_config('app.task_transition_actor', '', true);
END;
$$;

REVOKE ALL ON FUNCTION public.transition_task_operational_status(
  uuid,text,text,text,text,timestamptz,text,text,text,boolean,text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.transition_task_operational_status(
  uuid,text,text,text,text,timestamptz,text,text,text,boolean,text
) TO authenticated;

-- D4: read scopes are not write authority. Mutating a Task requires either its
-- assignee identity or the explicit reassign_tasks grant within explicit scope.
DROP POLICY IF EXISTS "tasks read" ON public.tasks;
CREATE POLICY "tasks read"
ON public.tasks
FOR SELECT TO authenticated
USING (
  public.is_active_user()
  AND (
    assignee_id = auth.uid()
    OR created_by = auth.uid()
    OR public.has_task_permission('view_all_tasks')
    OR (
      public.has_task_permission('view_area_tasks')
      AND public.task_assignee_in_my_area(tasks.assignee_id)
    )
  )
);

DROP POLICY IF EXISTS "tasks update" ON public.tasks;
CREATE POLICY "tasks update"
ON public.tasks
FOR UPDATE TO authenticated
USING (
  public.is_active_user()
  AND (
    assignee_id = auth.uid()
    OR (
      public.has_task_permission('reassign_tasks')
      AND (
        public.has_task_permission('view_all_tasks')
        OR (
          public.has_task_permission('view_area_tasks')
          AND public.task_assignee_in_my_area(tasks.assignee_id)
        )
      )
    )
  )
)
WITH CHECK (
  public.is_active_user()
  AND (
    assignee_id = auth.uid()
    OR (
      public.has_task_permission('reassign_tasks')
      AND (
        public.has_task_permission('view_all_tasks')
        OR (
          public.has_task_permission('view_area_tasks')
          AND (assignee_id IS NULL OR public.task_assignee_in_my_area(assignee_id))
        )
      )
    )
  )
);

-- History is visible only when the caller can see the same Task by assignment
-- or explicit view scope; internal status or seniority alone is insufficient.
DROP POLICY IF EXISTS "task status history internal read" ON public.task_status_history;
DROP POLICY IF EXISTS "task status history within task scope" ON public.task_status_history;
CREATE POLICY "task status history within task scope"
ON public.task_status_history
FOR SELECT TO authenticated
USING (
  public.is_active_user()
  AND EXISTS (
    SELECT 1
    FROM public.tasks t
    WHERE t.id = task_status_history.task_id
      AND (
        t.assignee_id = auth.uid()
        OR public.has_task_permission('view_all_tasks')
        OR (
          public.has_task_permission('view_area_tasks')
          AND public.task_assignee_in_my_area(t.assignee_id)
        )
      )
  )
);

COMMIT;
