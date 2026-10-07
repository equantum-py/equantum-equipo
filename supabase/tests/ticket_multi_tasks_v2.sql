\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_ticket_id uuid;
  v_ticket_status text;
  v_actor uuid;
  v_task1 uuid;
  v_task2 uuid;
  v_count integer;
  v_status_after text;
BEGIN

  RAISE NOTICE '1/5 Seleccionar Ticket de staging';

  SELECT id, status
    INTO v_ticket_id, v_ticket_status
  FROM public.tickets
  ORDER BY created_at
  LIMIT 1;

  IF v_ticket_id IS NULL THEN
    RAISE EXCEPTION 'FAIL: staging no tiene Ticket para probar';
  END IF;

  SELECT id
    INTO v_actor
  FROM public.profiles
  WHERE active = true
  ORDER BY is_master DESC NULLS LAST, created_at
  LIMIT 1;

  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'FAIL: staging no tiene usuario interno activo';
  END IF;


  RAISE NOTICE '2/5 Crear Task 1';

  INSERT INTO public.tasks(
    title,
    original_title,
    area,
    task_type,
    priority,
    status,
    estimated_minutes,
    actual_minutes,
    triage_score,
    client_urgency,
    affects_sales,
    blocks_others,
    strategic,
    created_by,
    assignee_id,
    ticket_id
  )
  VALUES(
    'GOLDEN TICKET TASK 1',
    'GOLDEN TICKET TASK 1',
    'Soporte',
    'Soporte/corrección',
    'medium',
    'pending',
    30,
    0,
    40,
    3,
    false,
    false,
    false,
    v_actor,
    v_actor,
    v_ticket_id
  )
  RETURNING id INTO v_task1;


  RAISE NOTICE '3/5 Crear Task 2 para el MISMO Ticket';

  INSERT INTO public.tasks(
    title,
    original_title,
    area,
    task_type,
    priority,
    status,
    estimated_minutes,
    actual_minutes,
    triage_score,
    client_urgency,
    affects_sales,
    blocks_others,
    strategic,
    created_by,
    assignee_id,
    ticket_id
  )
  VALUES(
    'GOLDEN TICKET TASK 2',
    'GOLDEN TICKET TASK 2',
    'Soporte',
    'Soporte/corrección',
    'medium',
    'pending',
    30,
    0,
    40,
    3,
    false,
    false,
    false,
    v_actor,
    v_actor,
    v_ticket_id
  )
  RETURNING id INTO v_task2;

  SELECT count(*)
    INTO v_count
  FROM public.tasks
  WHERE id IN (v_task1, v_task2)
    AND ticket_id = v_ticket_id;

  IF v_count <> 2 THEN
    RAISE EXCEPTION
      'FAIL: Ticket no admite 2 Tasks. Encontradas: %',
      v_count;
  END IF;


  RAISE NOTICE '4/5 Completar Task sin cerrar Ticket';

  UPDATE public.tasks
  SET status = 'completed',
      completed_at = now()
  WHERE id = v_task1;

  SELECT status
    INTO v_status_after
  FROM public.tickets
  WHERE id = v_ticket_id;

  IF v_status_after IS DISTINCT FROM v_ticket_status THEN
    RAISE EXCEPTION
      'FAIL: completar Task cambio Ticket de % a %',
      v_ticket_status,
      v_status_after;
  END IF;


  RAISE NOTICE '5/5 ACC-TICKET-004 PASS';

END
$$;

ROLLBACK;
