\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_entity uuid;
  v_opportunity uuid;
  v_proposal uuid;
  v_item uuid;
  v_sale uuid;
  v_retry uuid;
  v_case record;
  v_snapshot public.sales%ROWTYPE;
  v_line public.sale_items%ROWTYPE;
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.commercial_entities
    WHERE display_name = 'QA-FISCAL-SNAPSHOT-V3'
  ) THEN
    RAISE EXCEPTION 'FAIL: fixture fiscal preexistente';
  END IF;

  INSERT INTO public.commercial_entities(entity_type, display_name)
  VALUES ('company', 'QA-FISCAL-SNAPSHOT-V3')
  RETURNING id INTO v_entity;

  -- Configuraciones explicitas de prueba, no tasas fiscales legales.
  -- Misma moneda USD: un caso gravado y otro sin impuesto.
  FOR v_case IN
    SELECT * FROM (VALUES
      ('PYG', 'qa-explicit-tax', 1000000::numeric),
      ('USD', 'qa-explicit-tax', 1000000::numeric),
      ('USD', 'qa-explicit-export-zero', 0::numeric)
    ) AS cases(currency, treatment, tax)
  LOOP
    INSERT INTO public.opportunities(
      commercial_entity_id, title, stage, currency, expected_amount
    ) VALUES (
      v_entity, 'QA-FISCAL-SNAPSHOT-V3', 'open',
      v_case.currency, 10000000 + v_case.tax
    ) RETURNING id INTO v_opportunity;

    INSERT INTO public.proposals(
      opportunity_id, version, status, currency, subtotal_amount,
      discount_amount, tax_amount, total_amount
    ) VALUES (
      v_opportunity, 1, 'draft', v_case.currency, 10000000,
      0, v_case.tax, 10000000 + v_case.tax
    ) RETURNING id INTO v_proposal;

    INSERT INTO public.proposal_items(
      proposal_id, description, quantity, unit_price,
      discount_amount, tax_treatment, tax_amount, line_subtotal, line_total
    ) VALUES (
      v_proposal, 'QA-FISCAL-SNAPSHOT-V3', 1, 10000000,
      0, v_case.treatment, v_case.tax, 10000000, 10000000 + v_case.tax
    ) RETURNING id INTO v_item;

    v_sale := public.close_opportunity_won(v_opportunity, v_proposal);

    SELECT * INTO STRICT v_snapshot FROM public.sales WHERE id = v_sale;
    SELECT * INTO STRICT v_line FROM public.sale_items WHERE sale_id = v_sale;

    IF v_snapshot.currency IS DISTINCT FROM v_case.currency
       OR v_snapshot.tax_amount IS DISTINCT FROM v_case.tax
       OR v_snapshot.gross_amount IS DISTINCT FROM 10000000 + v_case.tax
       OR v_snapshot.net_amount IS DISTINCT FROM 10000000::numeric
       OR v_snapshot.commission_base_amount IS DISTINCT FROM 10000000::numeric
       OR v_snapshot.proposal_version IS DISTINCT FROM 1
       OR v_line.tax_treatment IS DISTINCT FROM v_case.treatment
       OR v_line.tax_amount IS DISTINCT FROM v_case.tax
       OR v_line.total_amount IS DISTINCT FROM 10000000 + v_case.tax
    THEN
      RAISE EXCEPTION 'FAIL: snapshot fiscal/base %, %',
        v_case.currency, v_case.treatment;
    END IF;

    -- Cambiar el origen no debe recalcular la venta historica.
    UPDATE public.proposal_items
    SET tax_treatment = 'qa-changed-source',
        tax_amount = 2000000,
        line_total = 12000000
    WHERE id = v_item;

    UPDATE public.proposals
    SET tax_amount = 2000000, total_amount = 12000000
    WHERE id = v_proposal;

    v_retry := public.close_opportunity_won(v_opportunity, v_proposal);
    IF v_retry IS DISTINCT FROM v_sale THEN
      RAISE EXCEPTION 'FAIL: retry fiscal creo otra venta';
    END IF;

    SELECT * INTO STRICT v_snapshot FROM public.sales WHERE id = v_sale;
    SELECT * INTO STRICT v_line FROM public.sale_items WHERE sale_id = v_sale;

    IF v_snapshot.tax_amount IS DISTINCT FROM v_case.tax
       OR v_snapshot.gross_amount IS DISTINCT FROM 10000000 + v_case.tax
       OR v_snapshot.commission_base_amount IS DISTINCT FROM 10000000::numeric
       OR v_line.tax_treatment IS DISTINCT FROM v_case.treatment
       OR v_line.tax_amount IS DISTINCT FROM v_case.tax
       OR v_line.total_amount IS DISTINCT FROM 10000000 + v_case.tax
    THEN
      RAISE EXCEPTION 'FAIL: origen modificado altero snapshot historico';
    END IF;

    RAISE NOTICE 'PASS fiscal snapshot: currency=%, treatment=%, tax=%, base=10000000',
      v_case.currency, v_case.treatment, v_case.tax;
  END LOOP;
END $$;

ROLLBACK;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.commercial_entities
    WHERE display_name = 'QA-FISCAL-SNAPSHOT-V3'
  ) OR EXISTS (
    SELECT 1 FROM public.opportunities
    WHERE title = 'QA-FISCAL-SNAPSHOT-V3'
  ) OR EXISTS (
    SELECT 1 FROM public.proposal_items
    WHERE description = 'QA-FISCAL-SNAPSHOT-V3'
  ) OR EXISTS (
    SELECT 1 FROM public.sale_items
    WHERE description = 'QA-FISCAL-SNAPSHOT-V3'
  ) THEN
    RAISE EXCEPTION 'FAIL: objetos QA fiscales residuales';
  END IF;
  RAISE NOTICE 'PASS: cero fixtures fiscales residuales';
END $$;
