\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_task_id uuid;
  v_actor uuid;
  v_ticket_id uuid;
  v_ticket_status_before text;
  v_ticket_status_after text;
  v_from_status text;
  v_to_status text;
  v_history_actor uuid;
  v_history_count integer;
BEGIN

  RAISE NOTICE '1/6 Seleccionar Task y actor';

  SELECT t.id, t.created_by, t.ticket_id
  INTO v_task_id, v_actor, v_ticket_id
  FROM public.tasks t
  WHERE t.status IS DISTINCT FROM 'completed'
  ORDER BY t.created_at
  LIMIT 1;

  IF v_task_id IS NULL THEN
    RAISE EXCEPTION 'FAIL: no existe Task utilizable';
  END IF;

  IF v_actor IS NULL THEN
    SELECT id INTO v_actor
    FROM public.profiles
    WHERE active = true
    ORDER BY is_master DESC NULLS LAST
    LIMIT 1;
  END IF;


  RAISE NOTICE '2/6 Capturar estado del Ticket';

  IF v_ticket_id IS NOT NULL THEN
    SELECT status
    INTO v_ticket_status_before
    FROM public.tickets
    WHERE id = v_ticket_id;
  END IF;


  RAISE NOTICE '3/6 Cambiar estado de Task';

  UPDATE public.tasks
  SET status = 'completed',
      completed_at = now()
  WHERE id = v_task_id;


  RAISE NOTICE '4/6 Verificar historial automatico';

  SELECT
    from_status,
    to_status,
    actor_id
  INTO
    v_from_status,
    v_to_status,
    v_history_actor
  FROM public.task_status_history
  WHERE task_id = v_task_id
  ORDER BY occurred_at DESC, id DESC
  LIMIT 1;

  IF v_to_status IS DISTINCT FROM 'completed' THEN
    RAISE EXCEPTION
      'FAIL: historial no registro completed. Valor: %',
      v_to_status;
  END IF;

  SELECT count(*)
  INTO v_history_count
  FROM public.task_status_history
  WHERE task_id = v_task_id
    AND to_status = 'completed';

  IF v_history_count < 1 THEN
    RAISE EXCEPTION 'FAIL: no se creo historial';
  END IF;


  RAISE NOTICE '5/6 Verificar independencia del Ticket';

  IF v_ticket_id IS NOT NULL THEN

    SELECT status
    INTO v_ticket_status_after
    FROM public.tickets
    WHERE id = v_ticket_id;

    IF v_ticket_status_after IS DISTINCT FROM v_ticket_status_before THEN
      RAISE EXCEPTION
        'FAIL: Task cambio Ticket de % a %',
        v_ticket_status_before,
        v_ticket_status_after;
    END IF;

  END IF;


  RAISE NOTICE
    'Historial: % -> %, actor: %',
    v_from_status,
    v_to_status,
    COALESCE(v_history_actor::text,'NULL');


  RAISE NOTICE '6/6 TASK STATUS HISTORY PASS';

END
$$;

ROLLBACK;
