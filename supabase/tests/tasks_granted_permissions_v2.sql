\set ON_ERROR_STOP on

BEGIN;

-- Dar temporalmente los permisos a Alejandra.
UPDATE public.user_permissions
SET reassign_tasks = true,
    view_all_tasks = true,
    delete_tasks = true
WHERE user_id = '8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b';

DO $$
DECLARE
  v_user uuid := '8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b';
  v_master uuid := '9ab6ef4a-71e2-462b-a6cd-395baabccdb3';
  v_task uuid := '31d015d5-5891-4a8b-96a4-032b5119f9f9';
  v_archive_task uuid := 'd0c0a000-0000-4000-8000-0000000000d1';
  v_count integer;
  v_area text;
  v_type text;
BEGIN

  RAISE NOTICE '1/4 Configurar colaborador con permisos temporales';

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user,
      'role', 'authenticated'
    )::text,
    true
  );

  SET LOCAL ROLE authenticated;


  RAISE NOTICE '2/4 reassign_tasks permite reasignar';

  UPDATE public.tasks
  SET assignee_id = v_master
  WHERE id = v_task;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  IF v_count <> 1 THEN
    RAISE EXCEPTION
      'FAIL: reassign_tasks=true no permitio reasignar';
  END IF;


  -- Volver a dejar la tarea visible para Alejandra durante el test.
  RESET ROLE;

  UPDATE public.tasks
  SET assignee_id = v_user
  WHERE id = v_task;

  SET LOCAL ROLE authenticated;


  RAISE NOTICE '3/4 delete_tasks permite archivar con trazabilidad';
  RESET ROLE;
  SELECT area,task_type INTO v_area,v_type FROM public.tasks WHERE id=v_task;
  INSERT INTO public.tasks(id,title,area,task_type,created_by,assignee_id)
  VALUES(v_archive_task,'QA-TASK-ARCHIVE-PERMISSION',v_area,v_type,v_user,v_master);
  SET LOCAL ROLE authenticated;
  PERFORM public.archive_task(v_archive_task,'Prueba temporal de permiso explícito');
  SELECT count(*) INTO v_count FROM public.task_archive_history
  WHERE task_id=v_archive_task AND actor_id=v_user
    AND reason='Prueba temporal de permiso explícito';
  IF v_count <> 1 OR NOT EXISTS (
    SELECT 1 FROM public.tasks WHERE id=v_archive_task AND archived_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'FAIL: delete_tasks no registró archivo auditable';
  END IF;
  BEGIN
    DELETE FROM public.tasks WHERE id=v_archive_task;
    RAISE EXCEPTION 'FAIL: delete_tasks autorizó eliminación definitiva';
  EXCEPTION WHEN SQLSTATE '42501' THEN NULL;
  END;
  IF NOT EXISTS (SELECT 1 FROM public.tasks WHERE id=v_archive_task AND archived_at IS NOT NULL)
     OR NOT EXISTS (SELECT 1 FROM public.task_archive_history WHERE task_id=v_archive_task) THEN
    RAISE EXCEPTION 'FAIL: hard delete eliminó el registro de archivo';
  END IF;


  RAISE NOTICE '4/4 GRANTED TASK PERMISSIONS PASS';

END
$$;

ROLLBACK;
