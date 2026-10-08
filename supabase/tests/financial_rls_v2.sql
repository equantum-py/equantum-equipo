\set ON_ERROR_STOP on
BEGIN;

DO $$
DECLARE
  v_user uuid;
  v_entity uuid;
  v_sale uuid;
  v_invoice uuid;
  v_payment uuid;
  v_payment_retry uuid;
  v_bank uuid;
  v_rec uuid;
  v_rec_retry uuid;
  v_count bigint;
  v_status text;
BEGIN
  -- Usuario real de staging con financial_info.
  SELECT p.id
    INTO v_user
  FROM public.profiles p
  JOIN public.user_permissions up ON up.user_id = p.id
  WHERE p.active = true
    AND up.financial_info = true
  LIMIT 1;

  IF v_user IS NULL THEN
    RAISE EXCEPTION 'FAIL: no existe usuario activo con financial_info';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  IF public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'FAIL: usuario seleccionado no obtiene financial_info';
  END IF;

  RAISE NOTICE 'PASS 1/8: usuario autorizado';

  -- Dataset aislado y reproducible.
  -- Se crea dentro de BEGIN y desaparece con ROLLBACK.
  DECLARE
    v_opp uuid;
    v_proposal uuid;
  BEGIN
    INSERT INTO public.commercial_entities(
      entity_type,
      display_name
    )
    VALUES(
      'company',
      'E2E FINANCIAL FUNCTIONS'
    )
    RETURNING id INTO v_entity;

    INSERT INTO public.opportunities(
      commercial_entity_id,
      title,
      stage,
      currency,
      expected_amount
    )
    VALUES(
      v_entity,
      'E2E Financial Opportunity',
      'open',
      'PYG',
      7000000
    )
    RETURNING id INTO v_opp;

    INSERT INTO public.proposals(
      opportunity_id,
      version,
      status,
      currency,
      total_amount,
      subtotal_amount,
      discount_amount,
      tax_amount
    )
    VALUES(
      v_opp,
      1,
      'draft',
      'PYG',
      7000000,
      6363636,
      0,
      636364
    )
    RETURNING id INTO v_proposal;

    INSERT INTO public.proposal_items(
      proposal_id,
      description,
      quantity,
      unit_price,
      discount_amount,
      tax_treatment,
      tax_amount,
      line_subtotal,
      line_total
    )
    VALUES(
      v_proposal,
      'Servicio E2E Financial',
      1,
      6363636,
      0,
      'explicit-test-tax',
      636364,
      6363636,
      7000000
    );

    v_sale := public.close_opportunity_won(
      v_opp,
      v_proposal
    );
  END;

  IF v_sale IS NULL THEN
    RAISE EXCEPTION 'FAIL: no se pudo crear Sale de prueba';
  END IF;

  INSERT INTO public.invoices(
    sale_id,
    commercial_entity_id,
    invoice_number,
    currency,
    subtotal_amount,
    tax_amount,
    total_amount,
    status,
    issued_at,
    created_by
  )
  VALUES(
    v_sale,
    v_entity,
    'E2E-FIN-001',
    'PYG',
    6363636,
    636364,
    7000000,
    'issued',
    now(),
    v_user
  )
  RETURNING id INTO v_invoice;

  RAISE NOTICE 'PASS 2/8: Invoice creada separada de Sale';


  v_payment := public.register_invoice_payment(v_invoice,7000000,'PYG','transfer','QA-RLS-PAYMENT-V3',now());
  v_bank := public.create_bank_movement_v2('PYG',7000000,'credit',now(),'QA RLS','QA-RLS-BANK-V3');
  v_rec := public.reconcile_payment_bank_movement(v_payment,v_bank);
  PERFORM set_config('qa.financial.allowed',v_user::text,true);
  PERFORM set_config('qa.financial.invoice',v_invoice::text,true);
  PERFORM set_config('qa.financial.payment',v_payment::text,true);
  PERFORM set_config('qa.financial.bank',v_bank::text,true);
  PERFORM set_config('qa.financial.rec',v_rec::text,true);
  SELECT p.id INTO v_user FROM public.profiles p
  JOIN public.user_permissions up ON up.user_id=p.id
  WHERE p.active=true AND COALESCE(p.is_master,false)=false
    AND COALESCE(up.financial_info,false)=false LIMIT 1;
  IF v_user IS NULL THEN RAISE EXCEPTION 'FAIL: missing restricted active user'; END IF;
  PERFORM set_config('qa.financial.denied',v_user::text,true);
END $$;

GRANT USAGE ON SCHEMA public, auth TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;
GRANT SELECT ON public.invoices,public.payments,public.bank_movements,
  public.payment_bank_reconciliations TO authenticated;
SET LOCAL ROLE authenticated;

SELECT set_config('request.jwt.claim.sub',current_setting('qa.financial.denied'),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT set_config('request.jwt.claims',json_build_object('sub',current_setting('qa.financial.denied'),'role','authenticated')::text,true);
DO $$
DECLARE v_table text; v_key text; v_count bigint;
BEGIN
  IF current_user <> 'authenticated' THEN RAISE EXCEPTION 'FAIL: role not authenticated'; END IF;
  IF public.has_financial_info() IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'FAIL: financial permission unexpected';
  END IF;
  FOR v_table,v_key IN SELECT * FROM (VALUES
    ('invoices','invoice'),('payments','payment'),('bank_movements','bank'),
    ('payment_bank_reconciliations','rec')) AS fixture(tab,key)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE oid=to_regclass('public.'||v_table) AND relrowsecurity) THEN
      RAISE EXCEPTION 'FAIL: RLS disabled on %',v_table;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolbypassrls))
      OR EXISTS (SELECT 1 FROM pg_class WHERE oid=to_regclass('public.'||v_table)
        AND relowner=(SELECT oid FROM pg_roles WHERE rolname=current_user)) THEN
      RAISE EXCEPTION 'FAIL: test role bypasses RLS';
    END IF;
    EXECUTE format('SELECT count(*) FROM public.%I WHERE id=$1',v_table)
      INTO v_count USING current_setting('qa.financial.'||v_key)::uuid;
    IF v_count <> 0 THEN RAISE EXCEPTION 'FAIL: % visible=%, expected 0',v_table,v_count; END IF;
  END LOOP;
  RAISE NOTICE 'PASS: denied real role against nonempty financial fixtures';
END $$;

SELECT set_config('request.jwt.claim.sub',current_setting('qa.financial.allowed'),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT set_config('request.jwt.claims',json_build_object('sub',current_setting('qa.financial.allowed'),'role','authenticated')::text,true);
DO $$
DECLARE v_table text; v_key text; v_count bigint;
BEGIN
  IF current_user <> 'authenticated' THEN RAISE EXCEPTION 'FAIL: role not authenticated'; END IF;
  IF public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'FAIL: financial permission unexpected';
  END IF;
  FOR v_table,v_key IN SELECT * FROM (VALUES
    ('invoices','invoice'),('payments','payment'),('bank_movements','bank'),
    ('payment_bank_reconciliations','rec')) AS fixture(tab,key)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE oid=to_regclass('public.'||v_table) AND relrowsecurity) THEN
      RAISE EXCEPTION 'FAIL: RLS disabled on %',v_table;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolbypassrls))
      OR EXISTS (SELECT 1 FROM pg_class WHERE oid=to_regclass('public.'||v_table)
        AND relowner=(SELECT oid FROM pg_roles WHERE rolname=current_user)) THEN
      RAISE EXCEPTION 'FAIL: test role bypasses RLS';
    END IF;
    EXECUTE format('SELECT count(*) FROM public.%I WHERE id=$1',v_table)
      INTO v_count USING current_setting('qa.financial.'||v_key)::uuid;
    IF v_count <> 1 THEN RAISE EXCEPTION 'FAIL: % visible=%, expected 1',v_table,v_count; END IF;
  END LOOP;
  RAISE NOTICE 'PASS: allowed real role against nonempty financial fixtures';
END $$;

SELECT set_config('request.jwt.claim.sub',current_setting('qa.financial.denied'),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT set_config('request.jwt.claims',json_build_object('sub',current_setting('qa.financial.denied'),'role','authenticated')::text,true);
DO $$
DECLARE v_table text; v_key text; v_count bigint;
BEGIN
  IF current_user <> 'authenticated' THEN RAISE EXCEPTION 'FAIL: role not authenticated'; END IF;
  IF public.has_financial_info() IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'FAIL: financial permission unexpected';
  END IF;
  FOR v_table,v_key IN SELECT * FROM (VALUES
    ('invoices','invoice'),('payments','payment'),('bank_movements','bank'),
    ('payment_bank_reconciliations','rec')) AS fixture(tab,key)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE oid=to_regclass('public.'||v_table) AND relrowsecurity) THEN
      RAISE EXCEPTION 'FAIL: RLS disabled on %',v_table;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolbypassrls))
      OR EXISTS (SELECT 1 FROM pg_class WHERE oid=to_regclass('public.'||v_table)
        AND relowner=(SELECT oid FROM pg_roles WHERE rolname=current_user)) THEN
      RAISE EXCEPTION 'FAIL: test role bypasses RLS';
    END IF;
    EXECUTE format('SELECT count(*) FROM public.%I WHERE id=$1',v_table)
      INTO v_count USING current_setting('qa.financial.'||v_key)::uuid;
    IF v_count <> 0 THEN RAISE EXCEPTION 'FAIL: % visible=%, expected 0',v_table,v_count; END IF;
  END LOOP;
  RAISE NOTICE 'PASS: denied real role against nonempty financial fixtures';
END $$;

RESET ROLE;
ROLLBACK;
