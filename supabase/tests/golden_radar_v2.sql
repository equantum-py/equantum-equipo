\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_task_id uuid;
  v_user_id uuid;
  v_followup_id uuid;
  v_radar_id uuid;

  v_radar_state text;
  v_operational_status text;
  v_is_overdue boolean;

  v_count integer;
BEGIN

  RAISE NOTICE '1/7 Seleccionar Task y usuario';

  SELECT
    t.id,
    coalesce(t.assignee_id, t.created_by)
  INTO
    v_task_id,
    v_user_id
  FROM public.tasks t
  ORDER BY t.created_at
  LIMIT 1;

  IF v_task_id IS NULL THEN
    RAISE EXCEPTION 'FAIL: no existe Task para Golden Radar';
  END IF;

  IF v_user_id IS NULL THEN
    SELECT id
    INTO v_user_id
    FROM public.profiles
    WHERE active = true
    ORDER BY is_master DESC NULLS LAST
    LIMIT 1;
  END IF;


  RAISE NOTICE '2/7 Crear Followup pendiente';

  INSERT INTO public.followups(
    task_id,
    responsible_id,
    status,
    next_action,
    next_followup_at,
    cadence,
    last_movement_at,
    notes
  )
  VALUES(
    v_task_id,
    v_user_id,
    'pending',
    'Golden Radar Test',
    now() - interval '1 hour',
    'once',
    now(),
    'GOLDEN-RADAR-V2'
  )
  RETURNING id INTO v_followup_id;


  RAISE NOTICE '3/7 Verificar Followup -> Radar';

  SELECT
    id,
    state
  INTO
    v_radar_id,
    v_radar_state
  FROM public.radar_items
  WHERE legacy_followup_id = v_followup_id;

  IF v_radar_id IS NULL THEN
    RAISE EXCEPTION
      'FAIL: Followup no genero Radar';
  END IF;

  IF v_radar_state <> 'active' THEN
    RAISE EXCEPTION
      'FAIL: Radar no quedo active: %',
      v_radar_state;
  END IF;


  RAISE NOTICE '4/7 Verificar Radar overdue sin cron';

  SELECT
    operational_status,
    is_overdue
  INTO
    v_operational_status,
    v_is_overdue
  FROM public.radar_operational_v2
  WHERE id = v_radar_id;

  IF v_operational_status <> 'overdue' THEN
    RAISE EXCEPTION
      'FAIL: Radar deberia estar overdue, quedo: %',
      v_operational_status;
  END IF;

  IF v_is_overdue IS DISTINCT FROM true THEN
    RAISE EXCEPTION
      'FAIL: is_overdue no es true';
  END IF;


  RAISE NOTICE '5/7 Cerrar Followup';

  UPDATE public.followups
  SET
    status = 'done',
    last_movement_at = now(),
    updated_at = now()
  WHERE id = v_followup_id;


  RAISE NOTICE '6/7 Verificar cierre automatico Radar';

  SELECT state
  INTO v_radar_state
  FROM public.radar_items
  WHERE id = v_radar_id;

  IF v_radar_state <> 'closed' THEN
    RAISE EXCEPTION
      'FAIL: Radar no se cerro con Followup: %',
      v_radar_state;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM public.radar_operational_v2
  WHERE id = v_radar_id
    AND operational_status = 'closed';

  IF v_count <> 1 THEN
    RAISE EXCEPTION
      'FAIL: Radar operacional no figura closed';
  END IF;


  RAISE NOTICE '7/7 GOLDEN RADAR V2 PASS';

END
$$;

ROLLBACK;
