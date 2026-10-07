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

-- Evalúa un permiso operativo del usuario autenticado sin exponer
-- directamente public.user_permissions al cliente.
CREATE OR REPLACE FUNCTION public.has_task_permission(
  p_permission text
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_allowed boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN false;
  END IF;

  SELECT CASE p_permission
    WHEN 'view_all_tasks' THEN up.view_all_tasks
    WHEN 'view_area_tasks' THEN up.view_area_tasks
    WHEN 'reassign_tasks' THEN up.reassign_tasks
    WHEN 'delete_tasks' THEN up.delete_tasks
    ELSE false
  END
  INTO v_allowed
  FROM public.user_permissions up
  WHERE up.user_id = auth.uid();

  RETURN coalesce(v_allowed, false);
END;
$$;

REVOKE ALL
ON FUNCTION public.has_task_permission(text)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.has_task_permission(text)
TO authenticated;



-- Comprueba si el assignee pertenece al área del usuario autenticado
-- sin exponer public.profiles directamente.
CREATE OR REPLACE FUNCTION public.task_assignee_in_my_area(
  p_assignee_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles me
    JOIN public.profiles assignee
      ON assignee.id = p_assignee_id
    WHERE me.id = auth.uid()
      AND me.active = true
      AND me.area IS NOT NULL
      AND assignee.area = me.area
  );
$$;

REVOKE ALL
ON FUNCTION public.task_assignee_in_my_area(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.task_assignee_in_my_area(uuid)
TO authenticated;


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

    OR public.has_task_permission('view_all_tasks')

    OR (
      public.has_task_permission('view_area_tasks')
      AND public.task_assignee_in_my_area(tasks.assignee_id)
    )
  )
);


-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- 2B. UPDATE TASKS DENTRO DEL ALCANCE VISIBLE
-- La policy habilita la fila para UPDATE.
-- La reasignación de assignee_id se controla además por
-- trg_guard_task_reassignment.
-- ------------------------------------------------------------

DROP POLICY IF EXISTS "tasks update"
ON public.tasks;

CREATE POLICY "tasks update"
ON public.tasks
FOR UPDATE
TO authenticated
USING (
  public.is_active_user()
  AND (
    public.is_admin()
    OR assignee_id = auth.uid()
    OR created_by = auth.uid()
    OR public.has_task_permission('view_all_tasks')
    OR (
      public.has_task_permission('view_area_tasks')
      AND public.task_assignee_in_my_area(tasks.assignee_id)
    )
  )
)
WITH CHECK (
  public.is_active_user()
);


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

      OR public.has_task_permission('reassign_tasks')
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

DROP POLICY IF EXISTS "tasks controlled delete"
ON public.tasks;

CREATE POLICY "tasks controlled delete"
ON public.tasks
FOR DELETE
TO authenticated
USING (
  public.is_admin()

  OR public.has_task_permission('delete_tasks')
);



-- Privilegios de tabla necesarios para que RLS pueda evaluar
-- el acceso de usuarios authenticated.
GRANT SELECT, INSERT, UPDATE, DELETE
ON public.tasks
TO authenticated;

GRANT SELECT
ON public.task_status_history
TO authenticated;

COMMIT;
