\set ON_ERROR_STOP on
BEGIN;
-- Adaptacion local de Auth. No se otorga UPDATE de propuestas en el test.
GRANT USAGE ON SCHEMA public,auth TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;
DO $$
DECLARE m uuid; d uuid; e uuid; o uuid; p uuid; a uuid; b uuid;
BEGIN
  IF EXISTS(SELECT 1 FROM public.commission_policy_versions WHERE policy_code='QA-COMMISSION-ASSIGN') THEN
    RAISE EXCEPTION 'FAIL: fixtures preexistentes'; END IF;
  SELECT id INTO m FROM public.profiles WHERE active AND is_master LIMIT 1;
  SELECT pr.id INTO d FROM public.profiles pr JOIN public.user_permissions up ON up.user_id=pr.id
  WHERE pr.active AND NOT coalesce(pr.is_master,false) AND NOT coalesce(up.financial_info,false) LIMIT 1;
  IF m IS NULL OR d IS NULL THEN RAISE EXCEPTION 'FAIL: actores faltantes'; END IF;
  INSERT INTO public.commission_policy_versions(policy_code,version,rate_percent,created_by)
  VALUES('QA-COMMISSION-ASSIGN',1,5,m) RETURNING id INTO a;
  INSERT INTO public.commission_policy_versions(policy_code,version,rate_percent,created_by)
  VALUES('QA-COMMISSION-ASSIGN',2,7,m) RETURNING id INTO b;
  INSERT INTO public.commercial_entities(entity_type,display_name)
  VALUES('company','QA-COMMISSION-ASSIGN') RETURNING id INTO e;
  INSERT INTO public.opportunities(commercial_entity_id,title,stage,currency,expected_amount)
  VALUES(e,'QA-COMMISSION-ASSIGN','open','PYG',11000000) RETURNING id INTO o;
  INSERT INTO public.proposals(opportunity_id,version,status,currency,total_amount,subtotal_amount,tax_amount)
  VALUES(o,1,'draft','PYG',11000000,10000000,1000000) RETURNING id INTO p;
  INSERT INTO public.proposal_items(proposal_id,description,quantity,unit_price,tax_treatment,tax_amount,line_subtotal,line_total)
  VALUES(p,'QA-COMMISSION-ASSIGN',1,10000000,'qa-explicit-tax',1000000,10000000,11000000);
  PERFORM set_config('qa.assign.master',m::text,true); PERFORM set_config('qa.assign.denied',d::text,true);
  PERFORM set_config('qa.assign.opp',o::text,true); PERFORM set_config('qa.assign.proposal',p::text,true);
  PERFORM set_config('qa.assign.v1',a::text,true); PERFORM set_config('qa.assign.v2',b::text,true);
  PERFORM set_config('request.jwt.claim.sub',m::text,true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',m,'role','authenticated')::text,true);
  INSERT INTO public.opportunities(commercial_entity_id,title,stage,currency,expected_amount)
  VALUES(e,'QA-COMMISSION-ASSIGN','open','PYG',11000000) RETURNING id INTO o;
  INSERT INTO public.proposals(opportunity_id,version,status,currency,total_amount)
  VALUES(o,1,'draft','PYG',0) RETURNING id INTO p;
  PERFORM public.close_opportunity_lost(o,'QA lost fixture');
  PERFORM set_config('qa.assign.lost_proposal',p::text,true);
  IF has_function_privilege('anon','public.assign_proposal_commission_v3(uuid,uuid)','EXECUTE') THEN
    RAISE EXCEPTION 'FAIL: anon ejecuta RPC'; END IF;
  IF EXISTS(SELECT 1 FROM pg_proc WHERE oid IN ('public.assign_proposal_commission_v3(uuid,uuid)'::regprocedure,
    'public.guard_proposal_commission_assignment_v3()'::regprocedure) AND prosecdef) THEN
    RAISE EXCEPTION 'FAIL: RPC debe ser invoker'; END IF;
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE p uuid:=current_setting('qa.assign.proposal')::uuid; a uuid:=current_setting('qa.assign.v1')::uuid;
        rejected boolean:=false;
BEGIN
  IF current_user<>'authenticated' OR EXISTS(SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolbypassrls)) THEN
    RAISE EXCEPTION 'FAIL: rol omite RLS'; END IF;
  IF public.assign_proposal_commission_v3(p,a) IS DISTINCT FROM p
     OR (SELECT commission_policy_id FROM public.proposals WHERE id=p) IS DISTINCT FROM a THEN
    RAISE EXCEPTION 'FAIL: Master no asigna version'; END IF;
  PERFORM public.assign_proposal_commission_v3(p,a);
  PERFORM public.assign_proposal_commission_v3(p,NULL);
  IF (SELECT commission_policy_id FROM public.proposals WHERE id=p) IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL: no se retira seleccion previa al cierre'; END IF;
  PERFORM public.assign_proposal_commission_v3(p,a);
  BEGIN PERFORM public.assign_proposal_commission_v3(p,'00000000-0000-4000-8000-000000000001');
  EXCEPTION WHEN SQLSTATE '22023' THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: politica inexistente aceptada'; END IF;
  rejected:=false;
  BEGIN PERFORM public.assign_proposal_commission_v3(current_setting('qa.assign.lost_proposal')::uuid,a);
  EXCEPTION WHEN SQLSTATE '55000' THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: propuesta de oportunidad LOST acepta asignacion'; END IF;
  RAISE NOTICE 'PASS: Master asigna, reintenta, retira y vuelve a asignar; politica inexistente rechazada';
END $$;
RESET ROLE;
DO $$
DECLARE s uuid; snapshot public.sales%ROWTYPE;
BEGIN
  s:=public.close_opportunity_won(current_setting('qa.assign.opp')::uuid,current_setting('qa.assign.proposal')::uuid);
  SELECT * INTO STRICT snapshot FROM public.sales WHERE id=s;
  IF snapshot.commission_policy_id IS DISTINCT FROM current_setting('qa.assign.v1')::uuid
     OR snapshot.commission_base_amount IS DISTINCT FROM 10000000::numeric
     OR snapshot.commission_amount IS DISTINCT FROM 500000::numeric THEN
    RAISE EXCEPTION 'FAIL: cierre no preserva seleccion/base/importe'; END IF;
  PERFORM set_config('qa.assign.sale',s::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE rejected boolean:=false; p uuid:=current_setting('qa.assign.proposal')::uuid;
BEGIN
  PERFORM public.assign_proposal_commission_v3(p,current_setting('qa.assign.v1')::uuid);
  BEGIN PERFORM public.assign_proposal_commission_v3(p,current_setting('qa.assign.v2')::uuid);
  EXCEPTION WHEN SQLSTATE '55000' THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: RPC cambia comision cerrada'; END IF;
  rejected:=false;
  BEGIN UPDATE public.proposals SET commission_policy_id=current_setting('qa.assign.v2')::uuid WHERE id=p;
  EXCEPTION WHEN SQLSTATE '55000' THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: escritura directa cambia comision cerrada'; END IF;
  RAISE NOTICE 'PASS: reintento idempotente; reasignacion cerrada rechazada por RPC y escritura directa';
END $$;
RESET ROLE;
DO $$ BEGIN
  PERFORM set_config('request.jwt.claim.sub',current_setting('qa.assign.denied'),true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',current_setting('qa.assign.denied'),'role','authenticated')::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE rejected boolean:=false; affected integer;
BEGIN
  BEGIN PERFORM public.assign_proposal_commission_v3(current_setting('qa.assign.proposal')::uuid,current_setting('qa.assign.v2')::uuid);
  EXCEPTION WHEN insufficient_privilege THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: usuario restringido ejecuta RPC'; END IF;
  UPDATE public.proposals SET commission_policy_id=current_setting('qa.assign.v2')::uuid
  WHERE id=current_setting('qa.assign.proposal')::uuid;
  GET DIAGNOSTICS affected=ROW_COUNT;
  IF affected<>0 OR EXISTS(SELECT 1 FROM public.proposals WHERE id=current_setting('qa.assign.proposal')::uuid) THEN
    RAISE EXCEPTION 'FAIL: usuario restringido lee/modifica propuesta'; END IF;
  RAISE NOTICE 'PASS: usuario restringido no lee ni asigna';
END $$;
RESET ROLE;
DO $$ BEGIN
  IF (SELECT commission_policy_id FROM public.sales WHERE id=current_setting('qa.assign.sale')::uuid)
     IS DISTINCT FROM current_setting('qa.assign.v1')::uuid THEN
    RAISE EXCEPTION 'FAIL: snapshot historico alterado'; END IF;
END $$;
ROLLBACK;
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM public.commission_policy_versions WHERE policy_code='QA-COMMISSION-ASSIGN')
     OR EXISTS(SELECT 1 FROM public.commercial_entities WHERE display_name='QA-COMMISSION-ASSIGN')
     OR EXISTS(SELECT 1 FROM public.opportunities WHERE title='QA-COMMISSION-ASSIGN') THEN
    RAISE EXCEPTION 'FAIL: fixtures residuales'; END IF;
  RAISE NOTICE 'PASS: cero fixtures residuales';
END $$;
