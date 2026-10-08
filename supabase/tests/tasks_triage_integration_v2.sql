\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_id uuid;
  v_actor uuid;
  v_area text;
  v_type text;
  v_task public.tasks%ROWTYPE;
  v_case record;
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.tasks
    WHERE title = 'QA-TRIAGE-INTEGRATION-V2'
  ) THEN
    RAISE EXCEPTION 'FAIL: existe fixture QA previo';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'public.tasks'::regclass
      AND tgname = 'trg_apply_task_triage_v2'
      AND tgenabled IN ('O', 'A')
  ) THEN
    RAISE EXCEPTION 'FAIL: trigger Triage ausente o deshabilitado';
  END IF;

  SELECT area, task_type INTO v_area, v_type
  FROM public.tasks ORDER BY id LIMIT 1;

  SELECT id INTO v_actor
  FROM public.profiles
  WHERE active = true
  ORDER BY id LIMIT 1;

  IF v_area IS NULL OR v_type IS NULL OR v_actor IS NULL THEN
    RAISE EXCEPTION 'FAIL: falta baseline para fixture';
  END IF;

  -- Los valores derivados enviados deben ser reemplazados por el trigger.
  INSERT INTO public.tasks (
    title, area, task_type, created_by,
    client_urgency, client_waiting_days,
    affects_sales, blocks_others, strategic,
    triage_score, priority, triage_reasons
  ) VALUES (
    'QA-TRIAGE-INTEGRATION-V2', v_area, v_type, v_actor,
    1, 0, false, false, false,
    100, 'critical', ARRAY['Valor enviado por cliente']
  )
  RETURNING * INTO v_task;

  v_id := v_task.id;

  IF v_task.triage_score IS DISTINCT FROM 23
     OR v_task.priority::text IS DISTINCT FROM 'low'
     OR v_task.triage_reasons IS DISTINCT FROM ARRAY[]::text[] THEN
    RAISE EXCEPTION 'FAIL: INSERT no calculo Triage correcto';
  END IF;

  RAISE NOTICE 'PASS: INSERT calcula y reemplaza valores derivados';

  FOR v_case IN
    SELECT * FROM (VALUES
      (1, 5, 0, false, false, false, 55, 'medium', ARRAY[]::text[]),
      (2, 5, 10, false, false, false, 75, 'high',
        ARRAY['Cliente esperando 10 días']),
      (3, 5, 10, true, false, false, 90, 'critical',
        ARRAY['Afecta ventas', 'Cliente esperando 10 días']),
      (4, 5, 10, true, true, false, 100, 'critical',
        ARRAY['Afecta ventas', 'Bloquea a otros', 'Cliente esperando 10 días']),
      (5, 5, 10, true, true, true, 100, 'critical',
        ARRAY['Afecta ventas', 'Bloquea a otros', 'Estratégica',
              'Cliente esperando 10 días']),
      (6, 1, 0, false, false, false, 23, 'low', ARRAY[]::text[])
    ) AS cases (
      step, urgency, waiting, sales, blocks, strategic,
      expected_score, expected_priority, expected_reasons
    )
  LOOP
    -- Solo se incluye el factor que cambia en cada paso.
    CASE v_case.step
      WHEN 1 THEN
        UPDATE public.tasks SET client_urgency = v_case.urgency WHERE id = v_id;
      WHEN 2 THEN
        UPDATE public.tasks SET client_waiting_days = v_case.waiting WHERE id = v_id;
      WHEN 3 THEN
        UPDATE public.tasks SET affects_sales = v_case.sales WHERE id = v_id;
      WHEN 4 THEN
        UPDATE public.tasks SET blocks_others = v_case.blocks WHERE id = v_id;
      WHEN 5 THEN
        UPDATE public.tasks SET strategic = v_case.strategic WHERE id = v_id;
      WHEN 6 THEN
        UPDATE public.tasks
        SET client_urgency = 1, client_waiting_days = 0,
            affects_sales = false, blocks_others = false, strategic = false
        WHERE id = v_id;
    END CASE;

    SELECT * INTO STRICT v_task FROM public.tasks WHERE id = v_id;

    IF v_task.triage_score IS DISTINCT FROM v_case.expected_score
       OR v_task.priority::text IS DISTINCT FROM v_case.expected_priority
       OR v_task.triage_reasons IS DISTINCT FROM v_case.expected_reasons THEN
      RAISE EXCEPTION
        'FAIL paso %: score=%, prioridad=%, razones=%',
        v_case.step, v_task.triage_score,
        v_task.priority, v_task.triage_reasons;
    END IF;

    RAISE NOTICE 'PASS: UPDATE paso %', v_case.step;
  END LOOP;

  UPDATE public.tasks SET description = 'Edicion sin cambio de factores'
  WHERE id = v_id;

  SELECT * INTO STRICT v_task FROM public.tasks WHERE id = v_id;

  IF v_task.triage_score IS DISTINCT FROM 23
     OR v_task.priority::text IS DISTINCT FROM 'low'
     OR v_task.triage_reasons IS DISTINCT FROM ARRAY[]::text[] THEN
    RAISE EXCEPTION 'FAIL: edicion ajena cambio Triage';
  END IF;

  RAISE NOTICE 'PASS: edicion ajena conserva Triage';

  PERFORM set_config('request.jwt.claim.sub',v_actor::text,true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_actor,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  EXECUTE 'GRANT USAGE ON SCHEMA auth, public TO authenticated';
  EXECUTE 'GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated';
  EXECUTE 'GRANT SELECT, UPDATE ON public.tasks TO authenticated';
  EXECUTE 'SET LOCAL ROLE authenticated';
  UPDATE public.tasks SET triage_score=100,priority='critical',triage_reasons=ARRAY['Manipulado']
  WHERE id=v_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'FAIL: test actor could not update own fixture'; END IF;
  SELECT * INTO STRICT v_task FROM public.tasks WHERE id=v_id;
  IF v_task.triage_score IS DISTINCT FROM 23
     OR v_task.priority::text IS DISTINCT FROM 'low'
     OR v_task.triage_reasons IS DISTINCT FROM ARRAY[]::text[] THEN
    RAISE EXCEPTION 'FAIL: authenticated changed derived Triage';
  END IF;
  EXECUTE 'RESET ROLE';
  RAISE NOTICE 'PASS: authenticated cannot forge derived Triage';

END $$;

ROLLBACK;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.tasks
    WHERE title = 'QA-TRIAGE-INTEGRATION-V2'
  ) THEN
    RAISE EXCEPTION 'FAIL: fixture residual';
  END IF;
  RAISE NOTICE 'PASS: cero Tasks QA residuales';
END $$;
