\set ON_ERROR_STOP on
-- Lab contract test only. Supply IDs for three EXISTING synthetic Supabase Auth
-- users (manager, internal without permission, and active Portal) via psql -v.
-- This checks Postgres RLS with JWT claim simulation; it is not a browser/Auth E2E.
\if :{?manager_id}
\else
  \echo BLOCKED: pass psql -v manager_id=<synthetic UUID>
  \quit 3
\endif
\if :{?denied_id}
\else
  \echo BLOCKED: pass psql -v denied_id=<synthetic UUID>
  \quit 3
\endif
\if :{?portal_id}
\else
  \echo BLOCKED: pass psql -v portal_id=<synthetic UUID>
  \quit 3
\endif

BEGIN;
DO $$
BEGIN
  IF has_table_privilege('authenticated','public.prospects','INSERT')
     OR has_table_privilege('authenticated','public.prospects','UPDATE')
     OR has_table_privilege('authenticated','public.commercial_entities','INSERT')
     OR has_table_privilege('authenticated','public.commercial_entities','UPDATE')
     OR has_table_privilege('authenticated','public.prospect_needs','INSERT')
     OR has_table_privilege('authenticated','public.prospect_needs','UPDATE')
     OR has_table_privilege('authenticated','public.prospect_needs','DELETE') THEN
    RAISE EXCEPTION 'FAIL: direct table-write grants can bypass the validated commercial RPC';
  END IF;
  IF NOT has_function_privilege('authenticated','public.save_prospect(uuid,uuid,jsonb,jsonb,jsonb,boolean)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.convert_prospect_to_opportunity_authorized(uuid,text,uuid,boolean)','EXECUTE') THEN
    RAISE EXCEPTION 'FAIL: authenticated commercial RPC is not executable';
  END IF;
END $$;
CREATE TEMP TABLE qa_prospect_actors(manager_id uuid,denied_id uuid,portal_id uuid) ON COMMIT DROP;
INSERT INTO qa_prospect_actors VALUES (:'manager_id',:'denied_id',:'portal_id');
GRANT SELECT ON qa_prospect_actors TO authenticated;

DO $$
DECLARE a record;
BEGIN
  SELECT * INTO a FROM qa_prospect_actors;
  IF NOT EXISTS(SELECT 1 FROM auth.users u JOIN public.profiles p ON p.id=u.id
    WHERE u.id=a.manager_id AND u.email LIKE 'p1-%@example.invalid' AND p.active)
     OR NOT EXISTS(SELECT 1 FROM auth.users u JOIN public.profiles p ON p.id=u.id
    WHERE u.id=a.denied_id AND u.email LIKE 'p1-%@example.invalid' AND p.active)
     OR NOT EXISTS(SELECT 1 FROM auth.users u JOIN public.profiles p ON p.id=u.id
    WHERE u.id=a.portal_id AND u.email LIKE 'p1-%@example.invalid' AND p.active)
     OR EXISTS(SELECT 1 FROM public.client_portal_users cpu WHERE cpu.user_id=a.manager_id AND cpu.active)
     OR EXISTS(SELECT 1 FROM public.client_portal_users cpu WHERE cpu.user_id=a.denied_id AND cpu.active)
     OR NOT EXISTS(SELECT 1 FROM public.client_portal_users cpu WHERE cpu.user_id=a.portal_id AND cpu.active) THEN
    RAISE EXCEPTION 'BLOCKED: the supplied identities are not the expected active synthetic actors';
  END IF;
END $$;

-- Temporary lab permission, rolled back with every fixture below.
INSERT INTO public.commercial_user_permissions(user_id,manage_prospects,granted_by,granted_at)
SELECT manager_id,true,manager_id,now() FROM qa_prospect_actors;

SET LOCAL ROLE authenticated;
DO $$
DECLARE a record; v_entity uuid; v_prospect uuid; v_opp1 uuid; v_opp2 uuid;
  v_entity2 uuid; v_prospect2 uuid; v_radar_id uuid; v_radar_after uuid;
BEGIN
  SELECT * INTO a FROM qa_prospect_actors;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',a.manager_id,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',a.manager_id::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  IF public.has_prospect_management() IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: authorized internal actor denied'; END IF;
  IF has_function_privilege('authenticated','public.convert_prospect_to_opportunity(uuid,text,uuid,text,numeric)','EXECUTE') THEN
    RAISE EXCEPTION 'FAIL: legacy conversion endpoint remains callable without explicit human-confirmation wrapper';
  END IF;

  BEGIN
    PERFORM public.save_prospect(null,null,
      '{"entity_type":"person","display_name":"QA no continuity"}'::jsonb,
      '{"status":"new","source":"web"}'::jsonb,'[]'::jsonb);
    RAISE EXCEPTION 'FAIL: prospect without next step was accepted';
  EXCEPTION WHEN SQLSTATE '22023' THEN
    IF SQLERRM NOT LIKE 'PROSPECT_CONTINUITY_ACTION_REQUIRED%' THEN RAISE; END IF;
  END;

  v_prospect:=public.save_prospect(null,null,
    '{"entity_type":"company","display_name":"QA DOC08 Synthetic Company","legal_name":"QA DOC08 Synthetic Company","tax_id":"QA-PROSPECT-20261013","email":"qa-prospect-20261013@example.invalid","phone":"59500000001"}'::jsonb,
    '{"status":"new","source":"referral","referrer_id":null,"owner_id":null,"next_action":"Confirmar la necesidad","next_review_at":"2026-10-15T14:00:00Z","next_condition":"Cuando el contacto confirme","customer_statement":"Solicita evaluar dos servicios","commercial_perception":"Interés inicial; calificación pendiente"}'::jsonb,
    '[{"category":"Consultoría","service_description":"Evaluación de proceso"},{"category":"Tecnología","service_description":"Integración de sistema"}]'::jsonb);

  SELECT commercial_entity_id INTO v_entity FROM public.prospects WHERE id=v_prospect;
  IF v_entity IS NULL OR (SELECT count(*) FROM public.prospect_needs WHERE prospect_id=v_prospect)<>2
     OR (SELECT count(*) FROM public.prospect_events WHERE prospect_id=v_prospect AND event_type='created')<>1
     OR NOT EXISTS(SELECT 1 FROM public.radar_items WHERE source_type='prospect' AND source_id=v_prospect AND state='active') THEN
    RAISE EXCEPTION 'FAIL: create did not retain canonical identity, two needs, history and Radar';
  END IF;

  v_prospect2:=public.save_prospect(null,null,
    '{"entity_type":"person","display_name":"QA DOC08 Pause/Resume Contact","email":"qa-pause-20261013@example.invalid"}'::jsonb,
    '{"status":"new","source":"web","next_action":"Contactar la persona","next_review_at":"2026-10-15T14:00:00Z","next_condition":"Si responde al correo"}'::jsonb,
    '[]'::jsonb);
  SELECT id INTO v_entity2 FROM public.commercial_entities WHERE display_name='QA DOC08 Pause/Resume Contact';
  SELECT id INTO v_radar_id FROM public.radar_items WHERE source_type='prospect' AND source_id=v_prospect2 AND state='active';
  PERFORM public.save_prospect(v_prospect2,v_entity2,
    '{"entity_type":"person","display_name":"QA DOC08 Pause/Resume Contact","email":"qa-pause-20261013@example.invalid"}'::jsonb,
    '{"status":"paused","source":"web","pause_reason":"La persona pidió retomarlo más adelante","pause_until":"2026-10-20T14:00:00Z","next_action":"Retomar contacto","next_review_at":"2026-10-20T14:00:00Z"}'::jsonb,
    '[]'::jsonb);
  SELECT id INTO v_radar_after FROM public.radar_items WHERE source_type='prospect' AND source_id=v_prospect2 AND state='active';
  IF v_radar_after IS DISTINCT FROM v_radar_id OR (SELECT count(*) FROM public.radar_items WHERE source_type='prospect' AND source_id=v_prospect2 AND state='active')<>1 THEN
    RAISE EXCEPTION 'FAIL: pausing duplicated or replaced its Radar continuation';
  END IF;
  PERFORM public.save_prospect(v_prospect2,v_entity2,
    '{"entity_type":"person","display_name":"QA DOC08 Pause/Resume Contact","email":"qa-pause-20261013@example.invalid"}'::jsonb,
    '{"status":"contacted","source":"web","next_action":"Confirmar nueva fecha","next_review_at":"2026-10-22T14:00:00Z","next_condition":"Cuando confirme disponibilidad"}'::jsonb,
    '[]'::jsonb);
  PERFORM public.save_prospect(v_prospect2,v_entity2,
    '{"entity_type":"person","display_name":"QA DOC08 Pause/Resume Contact","email":"qa-pause-20261013@example.invalid"}'::jsonb,
    '{"status":"disqualified","source":"web","closed_reason":"No existe necesidad activa"}'::jsonb,
    '[]'::jsonb);
  IF EXISTS(SELECT 1 FROM public.radar_items WHERE id=v_radar_id AND state='active') THEN
    RAISE EXCEPTION 'FAIL: disqualified prospect left an active Radar continuation';
  END IF;

  PERFORM public.save_prospect(v_prospect,v_entity,
    '{"entity_type":"company","display_name":"QA DOC08 Synthetic Company","legal_name":"QA DOC08 Synthetic Company","tax_id":"QA-PROSPECT-20261013","email":"qa-prospect-20261013@example.invalid","phone":"59500000001"}'::jsonb,
    '{"status":"qualifying","source":"referral","owner_id":null,"next_action":"Presentar solución","next_review_at":"2026-10-16T14:00:00Z","customer_statement":"Confirma que evaluará la solución","commercial_perception":"Necesidad concreta e intención de avanzar"}'::jsonb,
    '[{"category":"Consultoría","service_description":"Evaluación de proceso"}]'::jsonb);
  v_opp1:=public.convert_prospect_to_opportunity_authorized(v_prospect,'QA oportunidad DOC08',null,true);
  v_opp2:=public.convert_prospect_to_opportunity_authorized(v_prospect,'QA retry DOC08',null,true);
  IF v_opp1 IS DISTINCT FROM v_opp2 THEN RAISE EXCEPTION 'FAIL: conversion retry created a different Opportunity'; END IF;
  RAISE NOTICE 'PASS: authorized actor created/edited prospects, paused/reactivated/closed Radar safely, recorded needs/history, and converted idempotently';
END $$;
RESET ROLE;

DO $$
DECLARE a record; v_count integer; v_entity uuid; v_prospect uuid;
BEGIN
  SELECT * INTO a FROM qa_prospect_actors;
  SELECT id,commercial_entity_id INTO v_prospect,v_entity FROM public.prospects WHERE source='referral' AND commercial_entity_id IN
    (SELECT id FROM public.commercial_entities WHERE display_name='QA DOC08 Synthetic Company');
  IF v_prospect IS NULL OR (SELECT count(*) FROM public.opportunities WHERE prospect_id=v_prospect)<>1
     OR (SELECT commercial_entity_id FROM public.opportunities WHERE prospect_id=v_prospect) IS DISTINCT FROM v_entity
     OR NOT EXISTS(SELECT 1 FROM public.radar_items r JOIN public.opportunities o ON o.id=r.source_id
        WHERE o.prospect_id=v_prospect AND r.source_type='opportunity' AND r.state='active') THEN
    RAISE EXCEPTION 'FAIL: converted opportunity/identity/Radar link is inconsistent';
  END IF;
END $$;

SET LOCAL ROLE authenticated;
DO $$
DECLARE a record; v_failed boolean:=false;
BEGIN
  SELECT * INTO a FROM qa_prospect_actors;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',a.denied_id,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',a.denied_id::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  IF public.has_prospect_management() IS DISTINCT FROM false THEN RAISE EXCEPTION 'FAIL: unauthorized internal actor has write permission'; END IF;
  BEGIN
    PERFORM public.set_prospect_management(a.denied_id,true);
    RAISE EXCEPTION 'FAIL: non-master internal user granted commercial permissions';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.save_prospect(null,null,'{"entity_type":"person","display_name":"Must be denied"}'::jsonb,'{"status":"new","source":"web"}'::jsonb,'[]'::jsonb);
  EXCEPTION WHEN insufficient_privilege THEN v_failed:=true;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'FAIL: internal without commercial permission wrote prospect'; END IF;
  RAISE NOTICE 'PASS: internal user without manage_prospects was denied';
END $$;

DO $$
DECLARE a record; v_count integer;
BEGIN
  SELECT * INTO a FROM qa_prospect_actors;
  PERFORM set_config('request.jwt.claims',json_build_object('sub',a.portal_id,'role','authenticated')::text,true);
  PERFORM set_config('request.jwt.claim.sub',a.portal_id::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  SELECT count(*) INTO v_count FROM public.prospects WHERE source='referral';
  IF v_count<>0 OR public.has_prospect_management() IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'FAIL: Portal actor read Prospect or obtained commercial permission';
  END IF;
  BEGIN
    PERFORM * FROM public.find_prospect_identity_matches('company','QA DOC08 Synthetic Company',null,null,null);
    RAISE EXCEPTION 'FAIL: Portal actor queried internal commercial identities';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'PASS: Portal actor cannot read internal prospects';
END $$;
RESET ROLE;

SET LOCAL ROLE anon;
DO $$
DECLARE v_failed boolean:=false;
BEGIN
  BEGIN EXECUTE 'SELECT count(*) FROM public.prospects';
  EXCEPTION WHEN insufficient_privilege THEN v_failed:=true; END;
  IF NOT v_failed THEN RAISE EXCEPTION 'FAIL: anon could query prospects'; END IF;
  RAISE NOTICE 'PASS: anon has no Prospect table access';
END $$;
RESET ROLE;

ROLLBACK;
\echo PASS: all temporary permission and synthetic rows rolled back
