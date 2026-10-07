BEGIN;

-- ============================================================
-- TASKS V2
-- Historial estructural + permisos por area + reasignacion
-- ============================================================


-- ------------------------------------------------------------
-- 1. HISTORIAL AUTOMATICO DE ESTADOS
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.record_task_status_history()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor uuid;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN

    v_actor := auth.uid();

    INSERT INTO public.task_status_history(
      task_id,
      from_status,
      to_status,
      actor_id,
      occurred_at,
      reason,
      metadata
    )
    VALUES(
      NEW.id,
      OLD.status,
      NEW.status,
      v_actor,
      now(),
      NULL,
      jsonb_build_object(
        'source', 'task_status_trigger'
      )
    );

  END IF;

  RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_task_status_history
ON public.tasks;

CREATE TRIGGER trg_task_status_history
AFTER UPDATE OF status
ON public.tasks
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.record_task_status_history();


REVOKE ALL
ON FUNCTION public.record_task_status_history()
FROM PUBLIC, anon, authenticated;


-- ------------------------------------------------------------
-- 2. VIEW_AREA_TASKS
-- ------------------------------------------------------------

DROP POLICY IF EXISTS "tasks read"
ON public.tasks;

CREATE POLICY "tasks read"
ON public.tasks
FOR SELECT
TO authenticated
USING (
  public.is_active_user()
  AND (
    public.is_admin()

    OR assignee_id = auth.uid()

    OR created_by = auth.uid()

    OR EXISTS (
      SELECT 1
      FROM public.user_permissions p
      WHERE p.user_id = auth.uid()
        AND p.view_all_tasks = true
    )

    OR EXISTS (
      SELECT 1
      FROM public.user_permissions p
      JOIN public.profiles me
        ON me.id = auth.uid()
      JOIN public.profiles assignee
        ON assignee.id = tasks.assignee_id
      WHERE p.user_id = auth.uid()
        AND p.view_area_tasks = true
        AND me.active = true
        AND me.area IS NOT NULL
        AND assignee.area = me.area
    )
  )
);


-- ------------------------------------------------------------
-- 3. PROTEGER REASIGNACION
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.guard_task_reassignment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN

  IF NEW.assignee_id IS DISTINCT FROM OLD.assignee_id THEN

    IF NOT (
      public.is_admin()

      OR EXISTS (
        SELECT 1
        FROM public.user_permissions p
        WHERE p.user_id = auth.uid()
          AND p.reassign_tasks = true
      )
    ) THEN
      RAISE EXCEPTION
        'No tiene permiso para reasignar tareas';
    END IF;

  END IF;

  RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_guard_task_reassignment
ON public.tasks;

CREATE TRIGGER trg_guard_task_reassignment
BEFORE UPDATE OF assignee_id
ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION public.guard_task_reassignment();


REVOKE ALL
ON FUNCTION public.guard_task_reassignment()
FROM PUBLIC, anon, authenticated;


-- ------------------------------------------------------------
-- 4. DELETE RESPETA delete_tasks
-- ------------------------------------------------------------

DROP POLICY IF EXISTS "tasks admin delete"
ON public.tasks;

CREATE POLICY "tasks controlled delete"
ON public.tasks
FOR DELETE
TO authenticated
USING (
  public.is_admin()

  OR EXISTS (
    SELECT 1
    FROM public.user_permissions p
    WHERE p.user_id = auth.uid()
      AND p.delete_tasks = true
  )
);


COMMIT;
