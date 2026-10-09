BEGIN;

-- Keep read scopes read-only. Mutation is limited to the assignee or a user
-- with an explicit reassign_tasks grant inside their explicit task scope.
CREATE OR REPLACE FUNCTION public.can_write_task(p_task_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public.is_active_user()
    AND EXISTS (
      SELECT 1
      FROM public.tasks t
      WHERE t.id = p_task_id
        AND (
          t.assignee_id = auth.uid()
          OR (
            public.has_task_permission('reassign_tasks')
            AND (
              public.has_task_permission('view_all_tasks')
              OR (
                public.has_task_permission('view_area_tasks')
                AND public.task_assignee_in_my_area(t.assignee_id)
              )
            )
          )
        )
    );
$$;

REVOKE ALL ON FUNCTION public.can_write_task(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_write_task(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.guard_task_reassignment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.assignee_id IS DISTINCT FROM OLD.assignee_id THEN
    IF NOT public.is_active_user()
       OR NOT public.has_task_permission('reassign_tasks')
       OR NOT (
         public.has_task_permission('view_all_tasks')
         OR (
           public.has_task_permission('view_area_tasks')
           AND public.task_assignee_in_my_area(OLD.assignee_id)
         )
       )
       OR NOT (
         public.has_task_permission('view_all_tasks')
         OR NEW.assignee_id IS NULL
         OR public.task_assignee_in_my_area(NEW.assignee_id)
       ) THEN
      RAISE EXCEPTION 'TASK_REASSIGNMENT_UNAUTHORIZED' USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.guard_task_reassignment() FROM PUBLIC, anon, authenticated;

-- Delegated reassigners may change only the assignee and the corresponding
-- activity timestamps when the task is not assigned to them. They cannot use
-- the row-level update grant to edit task content or operational state.
CREATE OR REPLACE FUNCTION public.guard_task_mutation_scope()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE v_valid_transition_rpc boolean; v_valid_archive_rpc boolean;
BEGIN
  v_valid_transition_rpc :=
    NEW.status IS DISTINCT FROM OLD.status
    AND current_user IS NOT DISTINCT FROM (
      SELECT pg_get_userbyid(p.proowner)
      FROM pg_proc p
      WHERE p.oid = to_regprocedure(
        'public.transition_task_operational_status(uuid,text,text,text,text,timestamptz,text,text,text,boolean,text)'
      )
    )
    AND current_setting('app.task_transition_task_id',true) IS NOT DISTINCT FROM NEW.id::text
    AND current_setting('app.task_transition_actor',true) IS NOT DISTINCT FROM auth.uid()::text;
  v_valid_archive_rpc :=
    current_user IS NOT DISTINCT FROM (
      SELECT pg_get_userbyid(p.proowner) FROM pg_proc p
      WHERE p.oid=to_regprocedure('public.archive_task(uuid,text)')
    )
    AND current_setting('app.task_archive_task_id',true) IS NOT DISTINCT FROM NEW.id::text
    AND current_setting('app.task_archive_actor',true) IS NOT DISTINCT FROM auth.uid()::text;
  IF OLD.assignee_id IS DISTINCT FROM auth.uid()
     AND NOT v_valid_transition_rpc
     AND NOT v_valid_archive_rpc
     AND (
       to_jsonb(NEW) - ARRAY['assignee_id','updated_at','last_activity_at']::text[]
     ) IS DISTINCT FROM (
       to_jsonb(OLD) - ARRAY['assignee_id','updated_at','last_activity_at']::text[]
     ) THEN
    RAISE EXCEPTION 'TASK_REASSIGNMENT_ONLY' USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_task_mutation_scope() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_guard_task_mutation_scope ON public.tasks;
CREATE TRIGGER trg_guard_task_mutation_scope
BEFORE UPDATE ON public.tasks
FOR EACH ROW EXECUTE FUNCTION public.guard_task_mutation_scope();

-- Keep the existing versioned transition RPC; its authorization check is
-- corrected in 20261008120000_tasks_radar_workflow_v3.sql.

DROP POLICY IF EXISTS "tasks update" ON public.tasks;
CREATE POLICY "tasks update"
ON public.tasks FOR UPDATE TO authenticated
USING (public.can_write_task(id))
WITH CHECK (
  public.is_active_user()
  AND (
    assignee_id = auth.uid()
    OR (
      public.has_task_permission('reassign_tasks')
      AND (
        public.has_task_permission('view_all_tasks')
        OR (public.has_task_permission('view_area_tasks') AND (assignee_id IS NULL OR public.task_assignee_in_my_area(assignee_id)))
      )
    )
  )
);

-- A task creator has no permanent read access after assignment moves away.
-- Read access comes from current assignment, explicit view scope, or another
-- separately modeled authorization; creator identity alone is insufficient.
DROP POLICY IF EXISTS "tasks read" ON public.tasks;
CREATE POLICY "tasks read"
ON public.tasks FOR SELECT TO authenticated
USING (
  public.is_active_user()
  AND (
    assignee_id = auth.uid()
    OR public.has_task_permission('view_all_tasks')
    OR (
      public.has_task_permission('view_area_tasks')
      AND public.task_assignee_in_my_area(tasks.assignee_id)
    )
  )
);

-- A delete permission is an audited archival action, not permission to erase
-- the task and its cascading status history.
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS archived_at timestamptz,
  ADD COLUMN IF NOT EXISTS archived_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.task_archive_history (
  id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  task_id uuid NOT NULL UNIQUE REFERENCES public.tasks(id) ON DELETE RESTRICT,
  actor_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  reason text NOT NULL CHECK (length(btrim(reason)) > 0)
);
ALTER TABLE public.task_archive_history ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.task_archive_history FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.task_archive_history TO authenticated;
DROP POLICY IF EXISTS "task archive history scoped read" ON public.task_archive_history;
CREATE POLICY "task archive history scoped read"
ON public.task_archive_history FOR SELECT TO authenticated
USING (
  public.is_active_user() AND public.has_task_permission('delete_tasks')
  AND EXISTS (
    SELECT 1 FROM public.tasks t
    WHERE t.id=task_archive_history.task_id
      AND (t.assignee_id=auth.uid() OR public.has_task_permission('view_all_tasks')
        OR (public.has_task_permission('view_area_tasks') AND public.task_assignee_in_my_area(t.assignee_id)))
  )
);

CREATE OR REPLACE FUNCTION public.archive_task(p_task_id uuid, p_reason text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE v_task public.tasks%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_active_user()
     OR NOT public.has_task_permission('delete_tasks') THEN
    RAISE EXCEPTION 'TASK_ARCHIVE_UNAUTHORIZED' USING ERRCODE='42501';
  END IF;
  IF nullif(btrim(p_reason),'') IS NULL THEN
    RAISE EXCEPTION 'TASK_ARCHIVE_REASON_REQUIRED' USING ERRCODE='22023';
  END IF;
  SELECT * INTO v_task FROM public.tasks WHERE id=p_task_id FOR UPDATE;
  IF NOT FOUND OR NOT (
    v_task.assignee_id=auth.uid() OR public.has_task_permission('view_all_tasks')
    OR (public.has_task_permission('view_area_tasks') AND public.task_assignee_in_my_area(v_task.assignee_id))
  ) THEN
    RAISE EXCEPTION 'TASK_NOT_FOUND_OR_FORBIDDEN' USING ERRCODE='42501';
  END IF;
  IF v_task.archived_at IS NOT NULL THEN RETURN; END IF;
  IF EXISTS (SELECT 1 FROM public.followups f WHERE f.task_id=p_task_id AND f.status::text='pending')
     OR EXISTS (SELECT 1 FROM public.radar_items r WHERE r.source_type='task' AND r.source_id=p_task_id AND r.state='active') THEN
    RAISE EXCEPTION 'TASK_ARCHIVE_ACTIVE_CONTINUITY' USING ERRCODE='22023';
  END IF;

  INSERT INTO public.task_archive_history(task_id,actor_id,reason)
  VALUES (p_task_id,auth.uid(),btrim(p_reason))
  ON CONFLICT (task_id) DO NOTHING;
  PERFORM set_config('app.task_archive_task_id',p_task_id::text,true);
  PERFORM set_config('app.task_archive_actor',auth.uid()::text,true);
  UPDATE public.tasks SET archived_at=now(),archived_by=auth.uid(),updated_at=now()
  WHERE id=p_task_id AND archived_at IS NULL;
  PERFORM set_config('app.task_archive_task_id','',true);
  PERFORM set_config('app.task_archive_actor','',true);
END;
$$;
REVOKE ALL ON FUNCTION public.archive_task(uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.archive_task(uuid,text) TO authenticated;

DROP POLICY IF EXISTS "tasks admin delete" ON public.tasks;
DROP POLICY IF EXISTS "tasks controlled delete" ON public.tasks;
REVOKE DELETE ON public.tasks FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.reject_task_hard_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION 'TASK_HARD_DELETE_DISABLED_USE_ARCHIVE' USING ERRCODE='42501';
END;
$$;
REVOKE ALL ON FUNCTION public.reject_task_hard_delete() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_reject_task_hard_delete ON public.tasks;
CREATE TRIGGER trg_reject_task_hard_delete
BEFORE DELETE ON public.tasks
FOR EACH ROW EXECUTE FUNCTION public.reject_task_hard_delete();

COMMIT;
