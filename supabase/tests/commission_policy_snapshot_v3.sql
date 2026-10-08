\set ON_ERROR_STOP on
BEGIN;

GRANT USAGE ON SCHEMA public, auth TO authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;

DO $$
DECLARE v_master uuid; v_denied uuid;
BEGIN
  IF EXISTS (SELECT 1 FROM public.commission_policy_versions WHERE policy_code = 'QA-COMMISSION-V3') THEN
    RAISE EXCEPTION 'FAIL: preexisting commission fixture';
  END IF;
  SELECT id INTO v_master FROM public.profiles WHERE active AND is_master LIMIT 1;
  SELECT p.id INTO v_denied FROM public.profiles p
  JOIN public.user_permissions up ON up.user_id = p.id
  WHERE p.active AND NOT coalesce(p.is_master,false) AND NOT coalesce(up.financial_info,false)
  LIMIT 1;
  IF v_master IS NULL OR v_denied IS NULL THEN RAISE EXCEPTION 'FAIL: missing master/restricted actors'; END IF;
  PERFORM set_config('qa.commission.master',v_master::text,true);
  PERFORM set_config('qa.commission.denied',v_denied::text,true);
  PERFORM set_config('request.jwt.claim.sub',v_master::text,true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',v_master,'role','authenticated')::text,true);
END $$;

SET LOCAL ROLE authenticated;
DO $$
DECLARE v_id uuid;
BEGIN
  IF current_user <> 'authenticated' OR EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolbypassrls)
  ) THEN RAISE EXCEPTION 'FAIL: role bypasses RLS'; END IF;
  IF auth.uid() IS DISTINCT FROM current_setting('qa.commission.master')::uuid THEN
    RAISE EXCEPTION 'FAIL: simulated Master UID mismatch'; END IF;
  INSERT INTO public.commission_policy_versions(policy_code,version,rate_percent,created_by)
  VALUES ('QA-COMMISSION-V3',1,5,auth.uid()) RETURNING id INTO v_id;
  PERFORM set_config('qa.commission.v1',v_id::text,true);
  INSERT INTO public.commission_policy_versions(policy_code,version,rate_percent,created_by)
  VALUES ('QA-COMMISSION-V3',2,7,auth.uid()) RETURNING id INTO v_id;
  PERFORM set_config('qa.commission.v2',v_id::text,true);
  IF (SELECT count(*) FROM public.commission_policy_versions WHERE policy_code='QA-COMMISSION-V3') <> 2 THEN
    RAISE EXCEPTION 'FAIL: Master cannot read policy versions';
  END IF;
  RAISE NOTICE 'PASS: active Master creates/reads explicit policy versions';
END $$;
RESET ROLE;

DO $$
DECLARE
  v_entity uuid; v_opp uuid; v_proposal uuid; v_sale uuid; v_retry uuid;
  v_case record; v_snapshot public.sales%ROWTYPE; v_rejected boolean;
BEGIN
  INSERT INTO public.commercial_entities(entity_type,display_name)
  VALUES ('company','QA-COMMISSION-V3') RETURNING id INTO v_entity;
  FOR v_case IN SELECT * FROM (VALUES
    (current_setting('qa.commission.v1')::uuid,1,5::numeric,500000::numeric),
    (current_setting('qa.commission.v2')::uuid,2,7::numeric,700000::numeric),
    (NULL::uuid,NULL::integer,NULL::numeric,NULL::numeric)
  ) AS cases(policy_id,version,rate,amount)
  LOOP
    INSERT INTO public.opportunities(commercial_entity_id,title,stage,currency,expected_amount)
    VALUES (v_entity,'QA-COMMISSION-V3','open','PYG',11000000) RETURNING id INTO v_opp;
    INSERT INTO public.proposals(opportunity_id,version,status,currency,total_amount,
      subtotal_amount,tax_amount,commission_policy_id)
    VALUES (v_opp,1,'draft','PYG',11000000,10000000,1000000,v_case.policy_id)
    RETURNING id INTO v_proposal;
    INSERT INTO public.proposal_items(proposal_id,description,quantity,unit_price,
      tax_treatment,tax_amount,line_subtotal,line_total)
    VALUES (v_proposal,'QA-COMMISSION-V3',1,10000000,'qa-explicit-tax',1000000,10000000,11000000);

    v_sale := public.close_opportunity_won(v_opp,v_proposal);
    SELECT * INTO STRICT v_snapshot FROM public.sales WHERE id=v_sale;
    IF v_snapshot.commission_base_amount IS DISTINCT FROM 10000000::numeric
       OR v_snapshot.commission_policy_id IS DISTINCT FROM v_case.policy_id
       OR v_snapshot.commission_policy_version IS DISTINCT FROM v_case.version
       OR v_snapshot.commission_rate_percent IS DISTINCT FROM v_case.rate
       OR v_snapshot.commission_amount IS DISTINCT FROM v_case.amount
       OR (v_case.policy_id IS NOT NULL AND v_snapshot.commission_policy_code IS DISTINCT FROM 'QA-COMMISSION-V3')
       OR (v_case.policy_id IS NULL AND v_snapshot.commission_policy_code IS NOT NULL)
    THEN RAISE EXCEPTION 'FAIL: commission snapshot %, expected %',v_snapshot.commission_amount,v_case.amount;
    END IF;

    -- La seleccion de una propuesta cerrada queda protegida; su snapshot se conserva.
    IF v_case.policy_id IS DISTINCT FROM current_setting('qa.commission.v2')::uuid THEN
      v_rejected:=false;
      BEGIN
        UPDATE public.proposals SET commission_policy_id=current_setting('qa.commission.v2')::uuid
        WHERE id=v_proposal;
      EXCEPTION WHEN SQLSTATE '55000' THEN v_rejected:=true; END;
      IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: closed proposal reassignment allowed'; END IF;
    END IF;
    v_retry := public.close_opportunity_won(v_opp,v_proposal);
    SELECT * INTO STRICT v_snapshot FROM public.sales WHERE id=v_sale;
    IF v_retry IS DISTINCT FROM v_sale
       OR v_snapshot.commission_policy_id IS DISTINCT FROM v_case.policy_id
       OR v_snapshot.commission_rate_percent IS DISTINCT FROM v_case.rate
       OR v_snapshot.commission_amount IS DISTINCT FROM v_case.amount
    THEN RAISE EXCEPTION 'FAIL: proposal/retry changed historical commission'; END IF;

    v_rejected:=false;
    BEGIN
      UPDATE public.sales SET commission_amount=1 WHERE id=v_sale;
    EXCEPTION WHEN SQLSTATE '55000' THEN v_rejected:=true;
    END;
    IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: commission tampering allowed'; END IF;
    IF v_case.policy_id IS NOT NULL THEN
      v_rejected:=false;
      BEGIN UPDATE public.sales SET gross_amount=gross_amount+1 WHERE id=v_sale;
      EXCEPTION WHEN SQLSTATE '55000' THEN v_rejected:=true; END;
      IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: historical commission inputs mutable'; END IF;
    END IF;
    RAISE NOTICE 'PASS commission: version=%, rate=%, base=10000000, amount=%',v_case.version,v_case.rate,v_case.amount;
  END LOOP;

  v_rejected:=false;
  BEGIN UPDATE public.commission_policy_versions SET rate_percent=9 WHERE policy_code='QA-COMMISSION-V3';
  EXCEPTION WHEN SQLSTATE '55000' THEN v_rejected:=true; END;
  IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: policy version mutable'; END IF;
  v_rejected:=false;
  BEGIN DELETE FROM public.commission_policy_versions WHERE policy_code='QA-COMMISSION-V3';
  EXCEPTION WHEN SQLSTATE '55000' THEN v_rejected:=true; END;
  IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: policy version deletable'; END IF;
  RAISE NOTICE 'PASS: historical policy versions immutable';
  PERFORM set_config('request.jwt.claim.sub',current_setting('qa.commission.denied'),true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',current_setting('qa.commission.denied'),'role','authenticated')::text,true);
END $$;

SET LOCAL ROLE authenticated;
DO $$
DECLARE v_rejected boolean:=false;
BEGIN
  IF (SELECT count(*) FROM public.commission_policy_versions WHERE policy_code='QA-COMMISSION-V3') <> 0 THEN
    RAISE EXCEPTION 'FAIL: restricted actor reads commission policies'; END IF;
  BEGIN
    INSERT INTO public.commission_policy_versions(policy_code,version,rate_percent,created_by)
    VALUES ('QA-COMMISSION-V3',3,9,auth.uid());
  EXCEPTION WHEN insufficient_privilege THEN v_rejected:=true; END;
  IF NOT v_rejected THEN RAISE EXCEPTION 'FAIL: non-Master creates policy'; END IF;
  RAISE NOTICE 'PASS: restricted actor cannot read/create policies';
END $$;
RESET ROLE;
ROLLBACK;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.commission_policy_versions WHERE policy_code='QA-COMMISSION-V3')
     OR EXISTS (SELECT 1 FROM public.commercial_entities WHERE display_name='QA-COMMISSION-V3')
     OR EXISTS (SELECT 1 FROM public.opportunities WHERE title='QA-COMMISSION-V3')
     OR EXISTS (SELECT 1 FROM public.proposal_items WHERE description='QA-COMMISSION-V3')
     OR EXISTS (SELECT 1 FROM public.sale_items WHERE description='QA-COMMISSION-V3')
  THEN RAISE EXCEPTION 'FAIL: commission fixtures remain'; END IF;
  RAISE NOTICE 'PASS: zero commission fixtures after ROLLBACK';
END $$;
