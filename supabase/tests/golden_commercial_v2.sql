\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_entity uuid;
  v_catalog uuid;

  v_prospect uuid;
  v_opp1 uuid;
  v_opp2 uuid;

  v_proposal uuid;
  v_sale1 uuid;
  v_sale2 uuid;

  v_lost_opp uuid;

  v_quick_opp uuid;
  v_quick_proposal uuid;
  v_quick_result uuid;

  v_count bigint;
  v_amount numeric;
BEGIN

  RAISE NOTICE '1/8 Setup Golden Dataset';

  INSERT INTO public.commercial_entities(
    entity_type,
    display_name
  )
  VALUES(
    'company',
    'GOLDEN TEST EQ'
  )
  RETURNING id INTO v_entity;

  INSERT INTO public.catalog_items(
    code,
    name,
    item_type
  )
  VALUES(
    'GOLDEN-EQ-001',
    'Servicio Golden Test',
    'service'
  )
  RETURNING id INTO v_catalog;


  RAISE NOTICE '2/8 Prospect -> Opportunity idempotente';

  INSERT INTO public.prospects(
    commercial_entity_id,
    source
  )
  VALUES(
    v_entity,
    'golden-test'
  )
  RETURNING id INTO v_prospect;

  v_opp1 := public.convert_prospect_to_opportunity(
    v_prospect,
    'Golden Opportunity',
    v_catalog,
    'PYG',
    5000000
  );

  v_opp2 := public.convert_prospect_to_opportunity(
    v_prospect,
    'Golden Opportunity repetida',
    v_catalog,
    'PYG',
    5000000
  );

  IF v_opp1 IS DISTINCT FROM v_opp2 THEN
    RAISE EXCEPTION 'FAIL: Prospect creo dos Opportunities';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM public.opportunities
  WHERE prospect_id = v_prospect;

  IF v_count <> 1 THEN
    RAISE EXCEPTION
      'FAIL: Prospect tiene % Opportunities, esperado 1',
      v_count;
  END IF;


  RAISE NOTICE '3/8 Proposal + items';

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
    v_opp1,
    1,
    'draft',
    'PYG',
    5500000,
    5000000,
    0,
    500000
  )
  RETURNING id INTO v_proposal;

  INSERT INTO public.proposal_items(
    proposal_id,
    catalog_item_id,
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
    v_catalog,
    'Servicio Golden Test',
    1,
    5000000,
    0,
    'explicit-test-tax',
    500000,
    5000000,
    5500000
  );


  RAISE NOTICE '4/8 WON -> exactamente una Sale';

  v_sale1 := public.close_opportunity_won(
    v_opp1,
    v_proposal
  );

  v_sale2 := public.close_opportunity_won(
    v_opp1,
    v_proposal
  );

  IF v_sale1 IS DISTINCT FROM v_sale2 THEN
    RAISE EXCEPTION
      'FAIL: repetir WON creo otra Sale';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM public.sales
  WHERE opportunity_id = v_opp1;

  IF v_count <> 1 THEN
    RAISE EXCEPTION
      'FAIL: WON tiene % Sales, esperado 1',
      v_count;
  END IF;

  SELECT commission_base_amount
  INTO v_amount
  FROM public.sales
  WHERE id = v_sale1;

  IF v_amount <> 5000000 THEN
    RAISE EXCEPTION
      'FAIL: commission_base_amount %, esperado 5000000',
      v_amount;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM public.sale_items
  WHERE sale_id = v_sale1;

  IF v_count <> 1 THEN
    RAISE EXCEPTION
      'FAIL: snapshot tiene % items, esperado 1',
      v_count;
  END IF;


  RAISE NOTICE '5/8 Snapshot preservado';

  IF NOT EXISTS(
    SELECT 1
    FROM public.sales
    WHERE id = v_sale1
      AND proposal_version = 1
      AND entity_display_name = 'GOLDEN TEST EQ'
      AND subtotal_amount = 5000000
      AND tax_amount = 500000
      AND gross_amount = 5500000
      AND net_amount = 5000000
      AND snapshot_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'FAIL: snapshot de Sale incorrecto';
  END IF;


  RAISE NOTICE '6/8 LOST -> cero Sales';

  INSERT INTO public.opportunities(
    commercial_entity_id,
    title,
    stage,
    currency,
    expected_amount
  )
  VALUES(
    v_entity,
    'Golden Lost',
    'open',
    'PYG',
    1000000
  )
  RETURNING id INTO v_lost_opp;

  PERFORM public.close_opportunity_lost(
    v_lost_opp,
    'Golden test lost'
  );

  SELECT count(*)
  INTO v_count
  FROM public.sales
  WHERE opportunity_id = v_lost_opp;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL: LOST genero Sale';
  END IF;

  IF NOT EXISTS(
    SELECT 1
    FROM public.opportunities
    WHERE id = v_lost_opp
      AND outcome = 'lost'
      AND closed_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'FAIL: LOST no cerro correctamente';
  END IF;


  RAISE NOTICE '7/8 Quick Sale reutiliza Opportunity abierta';

  INSERT INTO public.opportunities(
    commercial_entity_id,
    catalog_item_id,
    title,
    stage,
    currency,
    expected_amount
  )
  VALUES(
    v_entity,
    v_catalog,
    'Golden Quick Existing',
    'open',
    'PYG',
    2000000
  )
  RETURNING id INTO v_quick_opp;

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
    v_quick_opp,
    1,
    'draft',
    'PYG',
    2200000,
    2000000,
    0,
    200000
  )
  RETURNING id INTO v_quick_proposal;

  INSERT INTO public.proposal_items(
    proposal_id,
    catalog_item_id,
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
    v_quick_proposal,
    v_catalog,
    'Golden Quick Item',
    1,
    2000000,
    0,
    'explicit-test-tax',
    200000,
    2000000,
    2200000
  );

  v_quick_result := public.quick_sale(
    v_entity,
    v_catalog,
    'NO DEBE CREAR OTRA',
    v_quick_proposal
  );

  IF v_quick_result IS DISTINCT FROM v_quick_opp THEN
    RAISE EXCEPTION
      'FAIL: Quick Sale no reutilizo Opportunity existente';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM public.opportunities
  WHERE commercial_entity_id = v_entity
    AND catalog_item_id = v_catalog;

  IF v_count <> 2 THEN
    -- Una es la Opportunity del Prospect ya cerrada y otra la Quick existente.
    RAISE EXCEPTION
      'FAIL: cantidad inesperada de Opportunities equivalentes: %',
      v_count;
  END IF;

  IF NOT EXISTS(
    SELECT 1
    FROM public.sales
    WHERE opportunity_id = v_quick_opp
  ) THEN
    RAISE EXCEPTION
      'FAIL: Quick Sale no genero Sale';
  END IF;


  RAISE NOTICE '8/8 Golden Commercial PASS';

END
$$;

ROLLBACK;
