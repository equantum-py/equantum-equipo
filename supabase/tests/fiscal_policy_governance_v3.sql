\set ON_ERROR_STOP on
BEGIN;
GRANT USAGE ON SCHEMA public,auth TO authenticated;
GRANT SELECT ON public.profiles, public.proposals, public.proposal_items TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;

DO $$
DECLARE v_master uuid; v_denied uuid;
BEGIN
  IF EXISTS(SELECT 1 FROM public.fiscal_policy_versions WHERE policy_code LIKE 'QA-FISCAL-GOV-%') THEN
    RAISE EXCEPTION 'FAIL: preexisting fiscal policy fixtures'; END IF;
  SELECT p.id INTO v_master FROM public.profiles p JOIN public.user_permissions up ON up.user_id=p.id
  WHERE p.active AND p.is_master AND up.financial_info LIMIT 1;
  SELECT p.id INTO v_denied FROM public.profiles p JOIN public.user_permissions up ON up.user_id=p.id
  WHERE p.active AND NOT coalesce(p.is_master,false) AND NOT coalesce(up.financial_info,false) LIMIT 1;
  IF v_master IS NULL OR v_denied IS NULL THEN RAISE EXCEPTION 'FAIL: actors missing'; END IF;
  PERFORM set_config('qa.fiscal.master',v_master::text,true);
  PERFORM set_config('qa.fiscal.denied',v_denied::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_master::text,true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_master,'role','authenticated')::text,true);
  IF EXISTS(SELECT 1 FROM pg_proc WHERE proname IN ('approve_proposal_item_fiscal_v3',
    'validate_fiscal_approval_v3','apply_item_fiscal_snapshot_v3','snapshot_sale_item_fiscal_v3')
    AND pronamespace='public'::regnamespace AND prosecdef) THEN
    RAISE EXCEPTION 'FAIL: fiscal functions must use SECURITY INVOKER'; END IF;
  IF (SELECT count(*) FROM pg_class WHERE oid IN ('public.fiscal_policy_versions'::regclass,
      'public.proposal_item_fiscal_approvals'::regclass) AND relrowsecurity) <> 2 THEN
    RAISE EXCEPTION 'FAIL: fiscal tables require RLS'; END IF;
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_id uuid; v_rejected boolean:=false;
BEGIN
  IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolbypassrls)) THEN
    RAISE EXCEPTION 'FAIL: role bypasses RLS'; END IF;
  INSERT INTO public.fiscal_policy_versions(policy_code,version,classification,rate_percent,basis_reference,created_by)
  VALUES('QA-FISCAL-GOV-TAX',1,'taxable',10,'QA ONLY; not legal configuration',auth.uid()) RETURNING id INTO v_id;
  PERFORM set_config('qa.fiscal.tax',v_id::text,true);
  INSERT INTO public.fiscal_policy_versions(policy_code,version,classification,rate_percent,basis_reference,created_by)
  VALUES('QA-FISCAL-GOV-EXPORT',1,'export_zero',0,'QA export policy fixture',auth.uid()) RETURNING id INTO v_id;
  PERFORM set_config('qa.fiscal.export',v_id::text,true);
  INSERT INTO public.fiscal_policy_versions(policy_code,version,classification,rate_percent,basis_reference,created_by)
  VALUES('QA-FISCAL-GOV-EXEMPT',1,'exempt',0,'QA exempt policy fixture',auth.uid()) RETURNING id INTO v_id;
  PERFORM set_config('qa.fiscal.exempt',v_id::text,true);
  BEGIN
    INSERT INTO public.fiscal_policy_versions(policy_code,version,classification,rate_percent,basis_reference,created_by)
    VALUES('QA-FISCAL-GOV-BAD',1,'export_zero',5,'QA invalid policy',auth.uid());
  EXCEPTION WHEN check_violation THEN v_rejected:=true; END;
  IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: nonzero export policy accepted'; END IF;
  RAISE NOTICE 'PASS: Master creates explicit versioned policies; invalid policy rejected';
END $$;
RESET ROLE;
DO $$
DECLARE v_entity uuid; v_opp uuid; v_proposal uuid; v_item uuid; v_case record;
        v_cases jsonb:='[]'::jsonb;
BEGIN
  INSERT INTO public.commercial_entities(entity_type,display_name)
  VALUES('company','QA-FISCAL-GOV-V3') RETURNING id INTO v_entity;
  FOR v_case IN SELECT * FROM (VALUES
    ('PYG',current_setting('qa.fiscal.tax')::uuid,'taxable',1000000::numeric),
    ('USD',current_setting('qa.fiscal.tax')::uuid,'taxable',1000000::numeric),
    ('USD',current_setting('qa.fiscal.export')::uuid,'export_zero',0::numeric),
    ('USD',current_setting('qa.fiscal.exempt')::uuid,'exempt',0::numeric)
  ) AS cases(currency,policy,classification,tax)
  LOOP
    INSERT INTO public.opportunities(commercial_entity_id,title,stage,currency,expected_amount)
    VALUES(v_entity,'QA-FISCAL-GOV-V3','open',v_case.currency,11000000) RETURNING id INTO v_opp;
    INSERT INTO public.proposals(opportunity_id,version,status,currency,total_amount,subtotal_amount,tax_amount)
    VALUES(v_opp,1,'draft',v_case.currency,0,0,0) RETURNING id INTO v_proposal;
    INSERT INTO public.proposal_items(proposal_id,description,quantity,unit_price,discount_amount,
      tax_treatment,tax_amount,line_subtotal,line_total)
    VALUES(v_proposal,'QA-FISCAL-GOV-V3',1,10000000,0,'unapproved-fixture',999,1,1)
    RETURNING id INTO v_item;
    v_cases:=v_cases||jsonb_build_array(jsonb_build_object('item',v_item,'opp',v_opp,
      'proposal',v_proposal,'policy',v_case.policy,'currency',v_case.currency,
      'classification',v_case.classification,'tax',v_case.tax));
  END LOOP;
  PERFORM set_config('qa.fiscal.cases',v_cases::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_case jsonb; v_id uuid; v_rejected boolean:=false;
        v_item public.proposal_items%ROWTYPE; v_proposal public.proposals%ROWTYPE;
        v_cases jsonb:='[]'::jsonb;
BEGIN
  BEGIN
    PERFORM public.approve_proposal_item_fiscal_v3(
      (current_setting('qa.fiscal.cases')::jsonb->0->>'item')::uuid,
      current_setting('qa.fiscal.tax')::uuid,'','QA reference');
  EXCEPTION WHEN SQLSTATE '22023' THEN v_rejected:=true; END;
  IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: missing justification accepted'; END IF;
  FOR v_case IN SELECT value FROM jsonb_array_elements(current_setting('qa.fiscal.cases')::jsonb)
  LOOP
    v_id:=public.approve_proposal_item_fiscal_v3((v_case->>'item')::uuid,
      (v_case->>'policy')::uuid,'QA explicit manual classification','QA-EVIDENCE-ONLY');
    SELECT * INTO STRICT v_item FROM public.proposal_items WHERE id=(v_case->>'item')::uuid;
    SELECT * INTO STRICT v_proposal FROM public.proposals WHERE id=(v_case->>'proposal')::uuid;
    IF v_item.fiscal_approval_id IS DISTINCT FROM v_id
      OR v_item.line_subtotal IS DISTINCT FROM 10000000::numeric
      OR v_item.tax_amount IS DISTINCT FROM (v_case->>'tax')::numeric
      OR v_item.tax_treatment IS DISTINCT FROM v_case->>'classification'
      OR v_item.line_total IS DISTINCT FROM 10000000+(v_case->>'tax')::numeric
      OR v_proposal.tax_amount IS DISTINCT FROM v_item.tax_amount
      OR v_proposal.total_amount IS DISTINCT FROM v_item.line_total THEN
      RAISE EXCEPTION 'FAIL: governed fiscal calculation/headers'; END IF;
    v_cases:=v_cases||jsonb_build_array(v_case||jsonb_build_object('approval',v_id));
    RAISE NOTICE 'PASS fiscal approval: currency=%, class=%, tax=%',v_case->>'currency',v_case->>'classification',v_item.tax_amount;
  END LOOP;
  PERFORM set_config('qa.fiscal.cases',v_cases::text,true);
END $$;
RESET ROLE;
DO $$
DECLARE v_case jsonb; v_sale uuid; v_snapshot public.sale_items%ROWTYPE;
        v_cases jsonb:='[]'::jsonb; v_rejected boolean;
BEGIN
  FOR v_case IN SELECT value FROM jsonb_array_elements(current_setting('qa.fiscal.cases')::jsonb)
  LOOP
    v_sale:=public.close_opportunity_won((v_case->>'opp')::uuid,(v_case->>'proposal')::uuid);
    SELECT * INTO STRICT v_snapshot FROM public.sale_items WHERE sale_id=v_sale;
    IF v_snapshot.fiscal_approval_id IS DISTINCT FROM (v_case->>'approval')::uuid
       OR v_snapshot.fiscal_policy_version IS DISTINCT FROM 1
       OR v_snapshot.fiscal_approved_by IS DISTINCT FROM current_setting('qa.fiscal.master')::uuid
       OR v_snapshot.fiscal_approved_at IS NULL
       OR v_snapshot.fiscal_evidence_reference IS DISTINCT FROM 'QA-EVIDENCE-ONLY'
       OR v_snapshot.tax_amount IS DISTINCT FROM (v_case->>'tax')::numeric THEN
      RAISE EXCEPTION 'FAIL: fiscal sale audit snapshot'; END IF;
    v_rejected:=false;
    BEGIN UPDATE public.sale_items SET tax_amount=9 WHERE sale_id=v_sale;
    EXCEPTION WHEN SQLSTATE '55000' THEN v_rejected:=true; END;
    IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: historical fiscal snapshot mutable'; END IF;
    v_rejected:=false;
    BEGIN UPDATE public.proposal_items SET quantity=2 WHERE id=(v_case->>'item')::uuid;
    EXCEPTION WHEN SQLSTATE '22023' THEN v_rejected:=true; END;
    IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: approved base changed without new decision'; END IF;
    v_cases:=v_cases||jsonb_build_array(v_case||jsonb_build_object('sale',v_sale));
  END LOOP;
  PERFORM set_config('qa.fiscal.cases',v_cases::text,true);
  v_rejected:=false;
  BEGIN UPDATE public.fiscal_policy_versions SET rate_percent=15 WHERE id=current_setting('qa.fiscal.tax')::uuid;
  EXCEPTION WHEN SQLSTATE '55000' THEN v_rejected:=true; END;
  IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: policy version mutable'; END IF;
  v_rejected:=false;
  BEGIN UPDATE public.proposal_item_fiscal_approvals SET evidence_reference='changed'
    WHERE id=(v_cases->0->>'approval')::uuid;
  EXCEPTION WHEN SQLSTATE '55000' THEN v_rejected:=true; END;
  IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: approval audit mutable'; END IF;
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_id uuid; v_case jsonb;
BEGIN
  INSERT INTO public.fiscal_policy_versions(policy_code,version,classification,rate_percent,basis_reference,created_by)
  VALUES('QA-FISCAL-GOV-TAX',2,'taxable',15,'QA newer policy fixture',auth.uid()) RETURNING id INTO v_id;
  v_case:=current_setting('qa.fiscal.cases')::jsonb->0;
  PERFORM public.approve_proposal_item_fiscal_v3((v_case->>'item')::uuid,v_id,
    'QA newer decision; historical sale stays unchanged','QA-EVIDENCE-V2');
END $$;
RESET ROLE;
DO $$
DECLARE v_case jsonb; v_snapshot public.sale_items%ROWTYPE;
BEGIN
  v_case:=current_setting('qa.fiscal.cases')::jsonb->0;
  SELECT * INTO STRICT v_snapshot FROM public.sale_items WHERE sale_id=(v_case->>'sale')::uuid;
  IF v_snapshot.fiscal_policy_version IS DISTINCT FROM 1 OR v_snapshot.fiscal_rate_percent IS DISTINCT FROM 10::numeric
     OR v_snapshot.tax_amount IS DISTINCT FROM 1000000::numeric
     OR v_snapshot.fiscal_evidence_reference IS DISTINCT FROM 'QA-EVIDENCE-ONLY' THEN
    RAISE EXCEPTION 'FAIL: new fiscal version changed historical sale'; END IF;
  PERFORM set_config('request.jwt.claim.sub',current_setting('qa.fiscal.denied'),true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',current_setting('qa.fiscal.denied'),'role','authenticated')::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_rejected boolean:=false;
BEGIN
  IF (SELECT count(*) FROM public.fiscal_policy_versions WHERE policy_code LIKE 'QA-FISCAL-GOV-%')<>0
     OR (SELECT count(*) FROM public.proposal_item_fiscal_approvals WHERE evidence_reference LIKE 'QA-EVIDENCE%')<>0 THEN
    RAISE EXCEPTION 'FAIL: restricted user reads fiscal decisions'; END IF;
  BEGIN
    PERFORM public.approve_proposal_item_fiscal_v3(
      (current_setting('qa.fiscal.cases')::jsonb->0->>'item')::uuid,
      current_setting('qa.fiscal.tax')::uuid,'unauthorized','unauthorized');
  EXCEPTION WHEN insufficient_privilege THEN v_rejected:=true; END;
  IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: restricted user approves fiscal policy'; END IF;
  RAISE NOTICE 'PASS: fiscal approval denied to restricted user';
END $$;
RESET ROLE;
ROLLBACK;
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM public.fiscal_policy_versions WHERE policy_code LIKE 'QA-FISCAL-GOV-%')
     OR EXISTS(SELECT 1 FROM public.commercial_entities WHERE display_name='QA-FISCAL-GOV-V3')
     OR EXISTS(SELECT 1 FROM public.proposal_items WHERE description='QA-FISCAL-GOV-V3')
     OR EXISTS(SELECT 1 FROM public.sale_items WHERE description='QA-FISCAL-GOV-V3') THEN
    RAISE EXCEPTION 'FAIL: fiscal governance fixtures remain'; END IF;
  RAISE NOTICE 'PASS: zero fiscal governance fixtures after rollback';
END $$;
