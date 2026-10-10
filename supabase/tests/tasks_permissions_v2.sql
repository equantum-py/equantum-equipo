\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_user uuid := '8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b';
  v_marketing_task uuid := '31d015d5-5891-4a8b-96a4-032b5119f9f9';
  v_support_task uuid := '94f9cab5-7b39-4fbb-9306-c52a2ae8a68f';
  v_master uuid := '9ab6ef4a-71e2-462b-a6cd-395baabccdb3';
  v_count integer;
BEGIN

  RAISE NOTICE '1/7 Configurar sesion Alejandra';

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user,
      'role', 'authenticated'
    )::text,
    true
  );

  SET LOCAL ROLE authenticated;


  RAISE NOTICE '2/7 view_area_tasks permite Marketing';

  SELECT count(*)
  INTO v_count
  FROM public.tasks
  WHERE id = v_marketing_task;

  IF v_count <> 1 THEN
    RAISE EXCEPTION
      'FAIL: Alejandra no puede ver Task de Marketing';
  END IF;


  RAISE NOTICE '3/7 Sin view_all_tasks no ve Soporte';

  SELECT count(*)
  INTO v_count
  FROM public.tasks
  WHERE id = v_support_task;

  IF v_count <> 0 THEN
    RAISE EXCEPTION
      'FAIL: Alejandra puede ver Task de Soporte fuera de alcance';
  END IF;


  RAISE NOTICE '4/7 Sin reassign_tasks no puede reasignar';

  UPDATE public.tasks
  SET assignee_id = v_master
  WHERE id = v_marketing_task;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL: read scope without reassign_tasks changed assignee';
  END IF;


  RAISE NOTICE '5/7 Sin delete_tasks no puede borrar';

  BEGIN
    DELETE FROM public.tasks WHERE id = v_marketing_task;
    RAISE EXCEPTION 'FAIL: user without delete_tasks executed hard delete';
  EXCEPTION WHEN SQLSTATE '42501' THEN
    NULL;
  END;


  RAISE NOTICE '6/7 Master conserva control total';

  RESET ROLE;

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_master,
      'role', 'authenticated'
    )::text,
    true
  );

  SET LOCAL ROLE authenticated;

  SELECT count(*)
  INTO v_count
  FROM public.tasks
  WHERE id IN (v_marketing_task, v_support_task);

  IF v_count <> 2 THEN
    RAISE EXCEPTION
      'FAIL: Master no puede ver todas las Tasks';
  END IF;


  RAISE NOTICE '7/7 TASK PERMISSIONS V2 PASS';

END
$$;

ROLLBACK;
