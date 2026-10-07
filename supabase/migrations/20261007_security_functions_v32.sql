BEGIN;

-- ============================================================
-- eQuantum Relanzamiento 2026
-- Security Functions V3.2
-- ============================================================

CREATE OR REPLACE FUNCTION public.has_financial_info()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    public.is_internal_user()
    AND EXISTS (
      SELECT 1
      FROM public.user_permissions up
      WHERE up.user_id = auth.uid()
        AND up.financial_info = true
    );
$$;

REVOKE ALL ON FUNCTION public.has_financial_info() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_financial_info() FROM anon;
GRANT EXECUTE ON FUNCTION public.has_financial_info() TO authenticated;


CREATE OR REPLACE FUNCTION public.detect_operational_improvements()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  n integer := 0;
BEGIN
  IF NOT public.is_internal_user() THEN
    RAISE EXCEPTION 'internal access required'
      USING ERRCODE = '42501';
  END IF;

  INSERT INTO improvement_suggestions(
    title,
    description,
    status,
    category,
    source_type,
    source_id,
    action_type,
    action_payload
  )
  SELECT
    'Crear seguimiento faltante',
    'La tarea “'||left(t.title,80)||'” está activa y no tiene próximo seguimiento registrado.',
    'pending',
    'attention',
    'task',
    t.id,
    'create_followup',
    jsonb_build_object(
      'task_id',t.id,
      'responsible_id',t.assignee_id,
      'next_action','Revisar avance de '||t.title,
      'days',2
    )
  FROM tasks t
  WHERE t.status NOT IN ('completed','cancelled')
    AND NOT EXISTS (
      SELECT 1
      FROM followups f
      WHERE f.task_id=t.id
        AND f.status='pending'
    )
    AND NOT EXISTS (
      SELECT 1
      FROM improvement_suggestions s
      WHERE s.status='pending'
        AND s.action_type='create_followup'
        AND s.source_id=t.id
    )
    AND (
      t.client_waiting_days>0
      OR t.due_date IS NOT NULL
      OR t.last_activity_at < now()-interval '3 days'
    );

  GET DIAGNOSTICS n = ROW_COUNT;

  INSERT INTO improvement_suggestions(
    title,
    description,
    status,
    category,
    source_type,
    source_id,
    action_type,
    action_payload
  )
  SELECT
    'Recuperar silencio operativo',
    'La tarea “'||left(t.title,80)||'” no registra movimiento reciente. Conviene revisar su estado.',
    'pending',
    'attention',
    'task',
    t.id,
    'create_followup',
    jsonb_build_object(
      'task_id',t.id,
      'responsible_id',t.assignee_id,
      'next_action','Retomar tarea sin movimiento: '||t.title,
      'days',1
    )
  FROM tasks t
  WHERE t.status NOT IN ('completed','cancelled')
    AND coalesce(t.last_activity_at,t.created_at) < now()-interval '5 days'
    AND NOT EXISTS (
      SELECT 1
      FROM followups f
      WHERE f.task_id=t.id
        AND f.status='pending'
    )
    AND NOT EXISTS (
      SELECT 1
      FROM improvement_suggestions s
      WHERE s.status='pending'
        AND s.action_type='create_followup'
        AND s.source_id=t.id
    );

  RETURN n;
END;
$$;

REVOKE ALL ON FUNCTION public.detect_operational_improvements() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.detect_operational_improvements() FROM anon;
GRANT EXECUTE ON FUNCTION public.detect_operational_improvements() TO authenticated;

COMMIT;
