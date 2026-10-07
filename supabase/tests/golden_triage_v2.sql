BEGIN;

DO $$
DECLARE
  r record;
BEGIN

  -- 1. Caso mínimo
  SELECT * INTO r
  FROM public.calculate_task_triage(1,0,false,false,false);

  IF r.triage_score <> 23 OR r.priority <> 'low' THEN
    RAISE EXCEPTION
      'TRIAGE-001 FAIL score=% priority=%',
      r.triage_score,r.priority;
  END IF;

  RAISE NOTICE 'TRIAGE-001 PASS';


  -- 2. Caso medio
  SELECT * INTO r
  FROM public.calculate_task_triage(3,5,false,false,false);

  IF r.triage_score <> 49 OR r.priority <> 'normal' THEN
    RAISE EXCEPTION
      'TRIAGE-002 FAIL score=% priority=%',
      r.triage_score,r.priority;
  END IF;

  RAISE NOTICE 'TRIAGE-002 PASS';


  -- 3. Caso alto
  SELECT * INTO r
  FROM public.calculate_task_triage(5,0,true,false,false);

  IF r.triage_score <> 70 OR r.priority <> 'medium' THEN
    RAISE EXCEPTION
      'TRIAGE-003 FAIL score=% priority=%',
      r.triage_score,r.priority;
  END IF;

  RAISE NOTICE 'TRIAGE-003 PASS';


  -- 4. Caso crítico / límite 100
  SELECT * INTO r
  FROM public.calculate_task_triage(5,10,true,true,true);

  IF r.triage_score <> 100 OR r.priority <> 'critical' THEN
    RAISE EXCEPTION
      'TRIAGE-004 FAIL score=% priority=%',
      r.triage_score,r.priority;
  END IF;

  RAISE NOTICE 'TRIAGE-004 PASS';


  -- 5. Urgencia fuera de rango debe normalizarse
  SELECT * INTO r
  FROM public.calculate_task_triage(99,0,false,false,false);

  IF r.triage_score <> 55 OR r.priority <> 'medium' THEN
    RAISE EXCEPTION
      'TRIAGE-005 FAIL score=% priority=%',
      r.triage_score,r.priority;
  END IF;

  RAISE NOTICE 'TRIAGE-005 PASS';


  -- 6. Waiting negativo no puede reducir score
  SELECT * INTO r
  FROM public.calculate_task_triage(1,-20,false,false,false);

  IF r.triage_score <> 23 THEN
    RAISE EXCEPTION
      'TRIAGE-006 FAIL score=%',
      r.triage_score;
  END IF;

  RAISE NOTICE 'TRIAGE-006 PASS';


  -- 7. Resultado determinístico
  IF (
    SELECT row(a.triage_score,a.priority,a.triage_reasons)
         = row(b.triage_score,b.priority,b.triage_reasons)
    FROM public.calculate_task_triage(4,7,true,true,false) a,
         public.calculate_task_triage(4,7,true,true,false) b
  ) IS NOT TRUE THEN
    RAISE EXCEPTION 'TRIAGE-007 FAIL';
  END IF;

  RAISE NOTICE 'TRIAGE-007 PASS';

END $$;

ROLLBACK;
