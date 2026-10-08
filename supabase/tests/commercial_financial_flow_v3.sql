\set ON_ERROR_STOP on
BEGIN;
-- Solo infraestructura de Auth del restore local. Sin GRANT de escrituras del circuito.
GRANT USAGE ON SCHEMA public,auth TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;
DO $$
DECLARE m uuid; d uuid; e uuid;
BEGIN
  IF EXISTS(SELECT 1 FROM public.commercial_entities WHERE display_name='QA-FULL-FLOW-V3') THEN
    RAISE EXCEPTION 'FAIL: fixtures preexistentes'; END IF;
  SELECT id INTO m FROM public.profiles WHERE active AND is_master LIMIT 1;
  SELECT p.id INTO d FROM public.profiles p JOIN public.user_permissions u ON u.user_id=p.id
  WHERE p.active AND NOT coalesce(p.is_master,false) AND NOT coalesce(u.financial_info,false) LIMIT 1;
  IF m IS NULL OR d IS NULL THEN RAISE EXCEPTION 'FAIL: actores faltantes'; END IF;
  INSERT INTO public.commercial_entities(entity_type,display_name) VALUES('company','QA-FULL-FLOW-V3') RETURNING id INTO e;
  PERFORM set_config('qa.flow.entity',e::text,true); PERFORM set_config('qa.flow.master',m::text,true);
  PERFORM set_config('qa.flow.denied',d::text,true);
  PERFORM set_config('request.jwt.claim.sub',m::text,true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',m,'role','authenticated')::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE fiscal uuid; commission uuid; proposal uuid; sale uuid; invoice uuid; payment uuid; retry uuid;
        request uuid:=gen_random_uuid(); issued timestamptz:='2026-10-08 03:00:00+00'; rejected boolean;
        currency text; amount numeric; items jsonb; s public.sales%ROWTYPE; paid numeric;
BEGIN
  IF current_user<>'authenticated' OR EXISTS(SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolbypassrls)) THEN
    RAISE EXCEPTION 'FAIL: rol omite RLS'; END IF;
  INSERT INTO public.fiscal_policy_versions(policy_code,version,classification,rate_percent,basis_reference,created_by)
  VALUES('QA-FULL-FLOW-V3',1,'exempt',0,'QA ONLY; no configuracion tributaria real',auth.uid()) RETURNING id INTO fiscal;
  INSERT INTO public.commission_policy_versions(policy_code,version,rate_percent,created_by)
  VALUES('QA-FULL-FLOW-V3',1,5,auth.uid()) RETURNING id INTO commission;
  FOR currency,amount IN SELECT * FROM (VALUES('PYG',14000000::numeric),('USD',1000::numeric)) AS cases(c,a) LOOP
    request:=gen_random_uuid();
    items:=jsonb_build_array(jsonb_build_object('description','QA-FULL-FLOW-V3','quantity',1,'unit_price',amount,'discount_amount',0));
    proposal:=public.create_proposal_workflow_v3(request,current_setting('qa.flow.entity')::uuid,'QA-FULL-FLOW-V3',currency,items,fiscal,commission,'QA manual decision','QA-EVIDENCE-ONLY');
    retry:=public.create_proposal_workflow_v3(request,current_setting('qa.flow.entity')::uuid,'QA-FULL-FLOW-V3',currency,items,fiscal,commission,'QA manual decision','QA-EVIDENCE-ONLY');
    IF proposal IS DISTINCT FROM retry THEN RAISE EXCEPTION 'FAIL: propuesta duplicada'; END IF;
    rejected:=false;
    BEGIN PERFORM public.create_proposal_workflow_v3(request,current_setting('qa.flow.entity')::uuid,'changed',currency,items,fiscal,commission,'QA manual decision','QA-EVIDENCE-ONLY');
    EXCEPTION WHEN SQLSTATE '22023' THEN rejected:=true; END;
    IF NOT rejected THEN RAISE EXCEPTION 'FAIL: request reutilizado con otros datos'; END IF;
    IF EXISTS(SELECT 1 FROM public.proposal_items WHERE proposal_id=proposal AND fiscal_approval_id IS NULL) THEN
      RAISE EXCEPTION 'FAIL: partida sin aprobacion fiscal'; END IF;
    sale:=public.close_proposal_workflow_v3(proposal);
    IF public.close_proposal_workflow_v3(proposal) IS DISTINCT FROM sale THEN
      RAISE EXCEPTION 'FAIL: cierre duplica venta'; END IF;
    SELECT * INTO STRICT s FROM public.sales WHERE id=sale;
    IF s.gross_amount IS DISTINCT FROM amount OR s.commission_amount IS DISTINCT FROM round(amount*0.05,2) THEN
      RAISE EXCEPTION 'FAIL: snapshot importes'; END IF;
    invoice:=public.create_workflow_invoice_v3(sale,'QA-FULL-FLOW-V3-'||currency,
      CASE WHEN currency='PYG' THEN 10000000 ELSE 500 END,0,issued,NULL);
    IF public.create_workflow_invoice_v3(sale,'QA-FULL-FLOW-V3-'||currency,
      CASE WHEN currency='PYG' THEN 10000000 ELSE 500 END,0,issued,NULL) IS DISTINCT FROM invoice THEN
      RAISE EXCEPTION 'FAIL: factura duplicada'; END IF;
    rejected:=false;
    BEGIN PERFORM public.create_workflow_invoice_v3(sale,'QA-FULL-FLOW-V3-EXCESS-'||currency,amount,0,issued,NULL);
    EXCEPTION WHEN SQLSTATE '22023' THEN rejected:=true; END;
    IF NOT rejected THEN RAISE EXCEPTION 'FAIL: sobrefacturacion aceptada'; END IF;
    paid:=CASE WHEN currency='PYG' THEN 7000000 ELSE 100 END;
    payment:=public.register_invoice_payment(invoice,paid,currency,'QA transfer','QA-FULL-FLOW-PAY-'||currency,issued);
    IF public.register_invoice_payment(invoice,paid,currency,'QA transfer','QA-FULL-FLOW-PAY-'||currency,issued) IS DISTINCT FROM payment THEN
      RAISE EXCEPTION 'FAIL: cobro duplicado'; END IF;
    IF (SELECT status FROM public.invoices WHERE id=invoice) IS DISTINCT FROM 'partially_paid'
       OR (SELECT sum(total_amount) FROM public.invoices WHERE sale_id=sale) IS DISTINCT FROM (CASE WHEN currency='PYG' THEN 10000000 ELSE 500 END)::numeric
       OR (SELECT sum(p.amount) FROM public.payments p WHERE p.invoice_id=invoice AND p.status='confirmed') IS DISTINCT FROM paid
       OR (SELECT count(*) FROM public.sales WHERE opportunity_id=s.opportunity_id)<>1 THEN
      RAISE EXCEPTION 'FAIL: factura/cobro/venta inconsistente'; END IF;
    IF currency='PYG' AND (s.gross_amount-10000000<>4000000 OR 10000000-paid<>3000000) THEN
      RAISE EXCEPTION 'FAIL: Golden 14M/10M/7M/4M/3M'; END IF;
    RAISE NOTICE 'PASS: Master % propuesta fiscal/comision -> venta -> factura -> cobro; reintentos sin duplicar',currency;
    PERFORM set_config('qa.flow.proposal',proposal::text,true); PERFORM set_config('qa.flow.sale',sale::text,true);
    PERFORM set_config('qa.flow.invoice',invoice::text,true);
  END LOOP;
END $$;
RESET ROLE;
DO $$ BEGIN
  PERFORM set_config('request.jwt.claim.sub',current_setting('qa.flow.denied'),true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',current_setting('qa.flow.denied'),'role','authenticated')::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE rejected boolean:=false;
BEGIN
  IF EXISTS(SELECT 1 FROM public.proposals WHERE id=current_setting('qa.flow.proposal')::uuid) THEN
    RAISE EXCEPTION 'FAIL: restringido lee propuesta financiera'; END IF;
  BEGIN PERFORM public.close_proposal_workflow_v3(current_setting('qa.flow.proposal')::uuid);
  EXCEPTION WHEN insufficient_privilege THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: restringido cierra venta'; END IF;
  rejected:=false;
  BEGIN PERFORM public.create_workflow_invoice_v3(current_setting('qa.flow.sale')::uuid,'QA-FULL-FLOW-DENIED',1,0,now(),NULL);
  EXCEPTION WHEN insufficient_privilege THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: restringido factura'; END IF;
  rejected:=false;
  BEGIN PERFORM public.register_invoice_payment(current_setting('qa.flow.invoice')::uuid,1,'USD','QA','QA-FULL-FLOW-DENIED',now());
  EXCEPTION WHEN insufficient_privilege THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: restringido cobra'; END IF;
END $$;
RESET ROLE;
-- financial_info concede consulta; no convierte al colaborador en operador Master.
-- Si el actor restringido era Portal, simular perfil interno solo en esta transaccion.
UPDATE public.client_portal_users SET active=false WHERE user_id=current_setting('qa.flow.denied')::uuid;
UPDATE public.user_permissions SET financial_info=true WHERE user_id=current_setting('qa.flow.denied')::uuid;
SET LOCAL ROLE authenticated;
DO $$
DECLARE rejected boolean:=false;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.invoices WHERE id=current_setting('qa.flow.invoice')::uuid) THEN
    RAISE EXCEPTION 'FAIL: financial_info no permite consulta'; END IF;
  BEGIN PERFORM public.create_invoice_v2(current_setting('qa.flow.sale')::uuid,'QA-FULL-FLOW-DENIED',1,0,1,now(),NULL);
  EXCEPTION WHEN insufficient_privilege THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'FAIL: lector financiero escribe'; END IF;
  RAISE NOTICE 'PASS: lector financiero consulta pero no factura';
END $$;
RESET ROLE;
ROLLBACK;
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM public.commercial_entities WHERE display_name='QA-FULL-FLOW-V3')
     OR EXISTS(SELECT 1 FROM public.invoices WHERE invoice_number LIKE 'QA-FULL-FLOW%')
     OR EXISTS(SELECT 1 FROM public.payments WHERE external_reference LIKE 'QA-FULL-FLOW%') THEN
    RAISE EXCEPTION 'FAIL: residuos del circuito'; END IF;
  RAISE NOTICE 'PASS: circuito completo revertido con ROLLBACK';
END $$;
