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

  v_payment := public.register_invoice_payment(
    v_invoice,
    7000000,
    'PYG',
    'transfer',
    'E2E-PAY-001',
    now()
  );

  SELECT status INTO v_status
  FROM public.invoices
  WHERE id = v_invoice;

  IF v_status <> 'paid' THEN
    RAISE EXCEPTION 'FAIL: Invoice %, esperado paid', v_status;
  END IF;

  RAISE NOTICE 'PASS 3/8: register_invoice_payment funciona';

  v_payment_retry := public.register_invoice_payment(
    v_invoice,
    7000000,
    'PYG',
    'transfer',
    'E2E-PAY-001',
    now()
  );

  IF v_payment_retry IS DISTINCT FROM v_payment THEN
    RAISE EXCEPTION 'FAIL: retry genero otro Payment';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.payments
  WHERE external_reference = 'E2E-PAY-001';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'FAIL: idempotencia Payment count=%', v_count;
  END IF;

  RAISE NOTICE 'PASS 4/8: retry Payment idempotente';

  -- Moneda incorrecta debe fallar sin crear Payment.
  BEGIN
    PERFORM public.register_invoice_payment(
      v_invoice,
      1,
      'USD',
      'transfer',
      'E2E-PAY-BAD-CURRENCY',
      now()
    );
    RAISE EXCEPTION 'FAIL: acepto Payment USD para Invoice PYG';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM = 'FAIL: acepto Payment USD para Invoice PYG' THEN
        RAISE;
      END IF;
  END;

  SELECT count(*) INTO v_count
  FROM public.payments
  WHERE external_reference = 'E2E-PAY-BAD-CURRENCY';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL: moneda incorrecta dejo Payment';
  END IF;

  RAISE NOTICE 'PASS 5/8: moneda incorrecta rechazada';

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
    'E2E Financial',
    'E2E-BANK-001'
  )
  RETURNING id INTO v_bank;

  v_rec := public.reconcile_payment_bank_movement(
    v_payment,
    v_bank
  );

  RAISE NOTICE 'PASS 6/8: conciliacion ejecutada';

  v_rec_retry := public.reconcile_payment_bank_movement(
    v_payment,
    v_bank
  );

  IF v_rec_retry IS DISTINCT FROM v_rec THEN
    RAISE EXCEPTION 'FAIL: retry conciliacion genero otro registro';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.payment_bank_reconciliations
  WHERE payment_id = v_payment;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'FAIL: conciliaciones=% esperado 1', v_count;
  END IF;

  RAISE NOTICE 'PASS 7/8: conciliacion idempotente';

  SELECT count(*) INTO v_count
  FROM public.payments
  WHERE invoice_id = v_invoice;

  IF v_count <> 1 THEN
    RAISE EXCEPTION
      'FAIL: conciliacion duplico caja; Payments=%',
      v_count;
  END IF;

  RAISE NOTICE 'PASS 8/8: conciliacion no duplica cobro';
END $$;

ROLLBACK;
