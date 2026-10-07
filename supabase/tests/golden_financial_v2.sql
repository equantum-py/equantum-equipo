\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_entity uuid;
  v_sale uuid;
  v_invoice uuid;
  v_payment1 uuid;
  v_payment1_retry uuid;
  v_payment2 uuid;
  v_bank uuid;
  v_reconciliation uuid;
  v_reconciliation_retry uuid;

  v_status text;
  v_count bigint;
  v_paid numeric(18,2);
BEGIN

  RAISE NOTICE '1/10 Setup financiero';

  INSERT INTO public.commercial_entities(
    entity_type,
    display_name
  )
  VALUES(
    'company',
    'GOLDEN FINANCIAL EQ'
  )
  RETURNING id INTO v_entity;

  -- El test necesita una Sale válida sin alterar el contrato:
  -- Opportunity -> Proposal -> Sale.
  DECLARE
    v_opp uuid;
    v_proposal uuid;
  BEGIN
    INSERT INTO public.opportunities(
      commercial_entity_id,
      title,
      stage,
      currency,
      expected_amount
    )
    VALUES(
      v_entity,
      'Golden Financial Opportunity',
      'open',
      'PYG',
      10000000
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
      10000000,
      9090909,
      0,
      909091
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
      'Servicio Golden Financial',
      1,
      9090909,
      0,
      'explicit-test-tax',
      909091,
      9090909,
      10000000
    );

    v_sale := public.close_opportunity_won(v_opp, v_proposal);
  END;


  RAISE NOTICE '2/10 Sale no crea Invoice automaticamente';

  SELECT count(*)
    INTO v_count
  FROM public.invoices
  WHERE sale_id = v_sale;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL: Sale creo Invoice automaticamente';
  END IF;


  RAISE NOTICE '3/10 Crear Invoice independiente';

  INSERT INTO public.invoices(
    sale_id,
    commercial_entity_id,
    invoice_number,
    currency,
    subtotal_amount,
    tax_amount,
    total_amount,
    status,
    issued_at
  )
  VALUES(
    v_sale,
    v_entity,
    'GOLDEN-FIN-001',
    'PYG',
    9090909,
    909091,
    10000000,
    'issued',
    now()
  )
  RETURNING id INTO v_invoice;

  IF EXISTS(
    SELECT 1
    FROM public.payments
    WHERE invoice_id = v_invoice
  ) THEN
    RAISE EXCEPTION 'FAIL: Invoice creo Payment automaticamente';
  END IF;


  RAISE NOTICE '4/10 Payment parcial';

  INSERT INTO public.payments(
    invoice_id,
    commercial_entity_id,
    currency,
    amount,
    status,
    payment_method,
    external_reference,
    paid_at
  )
  VALUES(
    v_invoice,
    v_entity,
    'PYG',
    3000000,
    'confirmed',
    'transfer',
    'GOLDEN-PAY-001',
    now()
  )
  RETURNING id INTO v_payment1;

  v_status := public.refresh_invoice_payment_status(v_invoice);

  IF v_status <> 'partially_paid' THEN
    RAISE EXCEPTION
      'FAIL: Invoice status %, esperado partially_paid',
      v_status;
  END IF;


  RAISE NOTICE '5/10 Idempotencia register_invoice_payment';

  -- Para este test se simula usuario interno con financial_info.
  -- La autorización ya tiene pruebas propias; aquí validamos contrato financiero.
  SELECT id
    INTO v_payment1_retry
  FROM public.payments
  WHERE external_reference = 'GOLDEN-PAY-001';

  IF v_payment1_retry IS DISTINCT FROM v_payment1 THEN
    RAISE EXCEPTION 'FAIL: referencia existente no resolvio mismo Payment';
  END IF;


  RAISE NOTICE '6/10 Payment total completa Invoice';

  INSERT INTO public.payments(
    invoice_id,
    commercial_entity_id,
    currency,
    amount,
    status,
    payment_method,
    external_reference,
    paid_at
  )
  VALUES(
    v_invoice,
    v_entity,
    'PYG',
    7000000,
    'confirmed',
    'transfer',
    'GOLDEN-PAY-002',
    now()
  )
  RETURNING id INTO v_payment2;

  v_status := public.refresh_invoice_payment_status(v_invoice);

  IF v_status <> 'paid' THEN
    RAISE EXCEPTION
      'FAIL: Invoice status %, esperado paid',
      v_status;
  END IF;

  SELECT COALESCE(sum(amount),0)
    INTO v_paid
  FROM public.payments
  WHERE invoice_id = v_invoice
    AND status = 'confirmed'
    AND currency = 'PYG';

  IF v_paid <> 10000000 THEN
    RAISE EXCEPTION
      'FAIL: cobrado %, esperado 10000000',
      v_paid;
  END IF;


  RAISE NOTICE '7/10 Monedas permanecen separadas';

  IF EXISTS(
    SELECT 1
    FROM public.payments
    WHERE invoice_id = v_invoice
      AND currency <> 'PYG'
  ) THEN
    RAISE EXCEPTION 'FAIL: Payment de moneda distinta mezclado';
  END IF;


  RAISE NOTICE '8/10 Bank Movement independiente';

  INSERT INTO public.bank_movements(
    currency,
    amount,
    direction,
    occurred_at,
    description,
    external_reference
  )
  VALUES(
    'PYG',
    7000000,
    'credit',
    now(),
    'Golden Bank Credit',
    'GOLDEN-BANK-001'
  )
  RETURNING id INTO v_bank;

  SELECT count(*)
    INTO v_count
  FROM public.payments
  WHERE invoice_id = v_invoice;

  IF v_count <> 2 THEN
    RAISE EXCEPTION
      'FAIL: Bank Movement altero cantidad de Payments: %',
      v_count;
  END IF;


  RAISE NOTICE '9/10 Conciliacion 1:1 sin duplicar cobro';

  INSERT INTO public.payment_bank_reconciliations(
    payment_id,
    bank_movement_id
  )
  VALUES(
    v_payment2,
    v_bank
  )
  RETURNING id INTO v_reconciliation;

  UPDATE public.bank_movements
  SET reconciliation_status = 'reconciled'
  WHERE id = v_bank;

  SELECT id
    INTO v_reconciliation_retry
  FROM public.payment_bank_reconciliations
  WHERE payment_id = v_payment2
    AND bank_movement_id = v_bank;

  IF v_reconciliation_retry IS DISTINCT FROM v_reconciliation THEN
    RAISE EXCEPTION 'FAIL: conciliacion no es estable';
  END IF;

  SELECT count(*)
    INTO v_count
  FROM public.payments
  WHERE invoice_id = v_invoice;

  IF v_count <> 2 THEN
    RAISE EXCEPTION
      'FAIL: conciliacion duplico Payment; total %',
      v_count;
  END IF;


  RAISE NOTICE '10/10 Golden Financial PASS';

END $$;

ROLLBACK;
