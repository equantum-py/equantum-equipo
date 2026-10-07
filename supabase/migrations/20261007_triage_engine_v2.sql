BEGIN;

-- ============================================================
-- eQuantum Triage V2
-- Una sola fuente de verdad para score, prioridad y razones.
-- Determinístico. No depende de frontend ni IA.
-- ============================================================

CREATE OR REPLACE FUNCTION public.calculate_task_triage(
  p_client_urgency integer DEFAULT 1,
  p_client_waiting_days integer DEFAULT 0,
  p_affects_sales boolean DEFAULT false,
  p_blocks_others boolean DEFAULT false,
  p_strategic boolean DEFAULT false
)
RETURNS TABLE (
  triage_score integer,
  priority text,
  triage_reasons text[]
)
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_urgency integer;
  v_waiting integer;
  v_score integer;
BEGIN
  v_urgency := greatest(1, least(coalesce(p_client_urgency,1),5));
  v_waiting := greatest(0, coalesce(p_client_waiting_days,0));

  v_score :=
    15
    + (v_urgency * 8)
    + (least(v_waiting,10) * 2)
    + CASE WHEN coalesce(p_affects_sales,false) THEN 15 ELSE 0 END
    + CASE WHEN coalesce(p_blocks_others,false) THEN 15 ELSE 0 END
    + CASE WHEN coalesce(p_strategic,false) THEN 10 ELSE 0 END;

  v_score := least(100, greatest(0,v_score));

  triage_score := v_score;

  priority :=
    CASE
      WHEN v_score >= 90 THEN 'critical'
      WHEN v_score >= 75 THEN 'high'
      WHEN v_score >= 50 THEN 'medium'
      WHEN v_score >= 25 THEN 'normal'
      ELSE 'low'
    END;

  triage_reasons := array_remove(ARRAY[
    CASE WHEN coalesce(p_affects_sales,false)
      THEN 'Afecta ventas' END,
    CASE WHEN coalesce(p_blocks_others,false)
      THEN 'Bloquea a otros' END,
    CASE WHEN coalesce(p_strategic,false)
      THEN 'Estratégica' END,
    CASE WHEN v_waiting > 0
      THEN 'Cliente esperando ' || v_waiting || ' días' END
  ]::text[],NULL);

  RETURN NEXT;
END;
$$;


CREATE OR REPLACE FUNCTION public.apply_task_triage_v2()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_result record;
BEGIN
  SELECT *
  INTO v_result
  FROM public.calculate_task_triage(
    NEW.client_urgency,
    NEW.client_waiting_days,
    NEW.affects_sales,
    NEW.blocks_others,
    NEW.strategic
  );

  NEW.triage_score := v_result.triage_score;
  NEW.priority := v_result.priority;
  NEW.triage_reasons := v_result.triage_reasons;

  RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_apply_task_triage_v2
ON public.tasks;

CREATE TRIGGER trg_apply_task_triage_v2
BEFORE INSERT OR UPDATE OF
  client_urgency,
  client_waiting_days,
  affects_sales,
  blocks_others,
  strategic
ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION public.apply_task_triage_v2();


-- Reconciliar Tasks existentes usando la misma regla.
UPDATE public.tasks
SET
  client_urgency = client_urgency,
  client_waiting_days = client_waiting_days,
  affects_sales = affects_sales,
  blocks_others = blocks_others,
  strategic = strategic;


REVOKE ALL
ON FUNCTION public.calculate_task_triage(integer,integer,boolean,boolean,boolean)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.calculate_task_triage(integer,integer,boolean,boolean,boolean)
TO authenticated;


COMMENT ON FUNCTION public.calculate_task_triage(integer,integer,boolean,boolean,boolean)
IS 'Triage V2 determinístico. Fuente única para score, prioridad y razones de Task.';

COMMENT ON FUNCTION public.apply_task_triage_v2()
IS 'Aplica Triage V2 automáticamente al insertar o modificar factores de priorización.';

COMMIT;
