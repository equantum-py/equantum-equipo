-- Financial Operations V2
-- Positive + negative validation.
-- Designed for staging/test only.
-- Everything runs inside transactions and is rolled back.

\set ON_ERROR_STOP on

-- ============================================================
-- POSITIVE
-- ============================================================

BEGIN;

UPDATE public.user_permissions
SET financial_info=true
WHERE user_id='9ab6ef4a-71e2-462b-a6cd-395baabccdb3';

SELECT set_config(
  'request.jwt.claim.sub',
  '9ab6ef4a-71e2-462b-a6cd-395baabccdb3',
  true
);

INSERT INTO public.commercial_entities
  (id,entity_type,display_name,status)
VALUES
  ('11111111-1111-4111-8111-111111111111',
   'company','TEST FINANCE OPS','active');

INSERT INTO public.opportunities
  (id,commercial_entity_id,title,stage,currency,
   expected_amount,outcome,closed_at)
VALUES
  ('22222222-2222-4222-8222-222222222222',
   '11111111-1111-4111-8111-111111111111',
   'TEST FINANCE OPS',
   'closed','PYG',1000000,'won',now());

INSERT INTO public.sales
  (id,opportunity_id,commercial_entity_id,currency,
   gross_amount,tax_amount,net_amount,closed_at)
VALUES
  ('33333333-3333-4333-8333-333333333333',
   '22222222-2222-4222-8222-222222222222',
   '11111111-1111-4111-8111-111111111111',
   'PYG',1000000,0,1000000,now());

SELECT public.create_invoice_v2(
  '33333333-3333-4333-8333-333333333333',
  'TEST-INV-001',
  1000000,0,1000000,
  now(),
  now() + interval '30 days'
);

SELECT public.create_bank_movement_v2(
  'PYG',
  1000000,
  'credit',
  now(),
  'TEST FINANCE OPS',
  'TEST-BANK-001'
);

DO $$
BEGIN
  IF (SELECT count(*) FROM public.invoices
      WHERE invoice_number='TEST-INV-001') <> 1 THEN
    RAISE EXCEPTION 'FAIL POSITIVE: invoice not created exactly once';
  END IF;

  IF (SELECT count(*) FROM public.bank_movements
      WHERE external_reference='TEST-BANK-001') <> 1 THEN
    RAISE EXCEPTION 'FAIL POSITIVE: bank movement not created exactly once';
  END IF;

  RAISE NOTICE 'PASS POSITIVE: invoice + bank movement';
END
$$;

ROLLBACK;

-- ============================================================
-- NEGATIVE PERMISSION
-- ============================================================

BEGIN;

UPDATE public.user_permissions
SET financial_info=false
WHERE user_id='9ab6ef4a-71e2-462b-a6cd-395baabccdb3';

SELECT set_config(
  'request.jwt.claim.sub',
  '9ab6ef4a-71e2-462b-a6cd-395baabccdb3',
  true
);

DO $$
BEGIN
  BEGIN
    PERFORM public.create_invoice_v2(
      gen_random_uuid(),'NEG-NO-PERM',
      1,0,1,now(),null
    );
    RAISE EXCEPTION 'FAIL: invoice allowed without financial_info';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'PASS NEGATIVE 1: invoice permission';
  END;
END
$$;

DO $$
BEGIN
  BEGIN
    PERFORM public.create_bank_movement_v2(
      'PYG',1,'credit',now(),null,'NEG-NO-PERM'
    );
    RAISE EXCEPTION 'FAIL: movement allowed without financial_info';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'PASS NEGATIVE 2: movement permission';
  END;
END
$$;

ROLLBACK;

-- ============================================================
-- NEGATIVE VALIDATION
-- ============================================================

BEGIN;

UPDATE public.user_permissions
SET financial_info=true
WHERE user_id='9ab6ef4a-71e2-462b-a6cd-395baabccdb3';

SELECT set_config(
  'request.jwt.claim.sub',
  '9ab6ef4a-71e2-462b-a6cd-395baabccdb3',
  true
);

INSERT INTO public.commercial_entities
  (id,entity_type,display_name,status)
VALUES
  ('11111111-1111-4111-8111-111111111111',
   'company','TEST FINANCE NEGATIVE','active');

INSERT INTO public.opportunities
  (id,commercial_entity_id,title,stage,currency,
   expected_amount,outcome,closed_at)
VALUES
  ('22222222-2222-4222-8222-222222222222',
   '11111111-1111-4111-8111-111111111111',
   'TEST FINANCE NEGATIVE',
   'closed','PYG',1000000,'won',now());

INSERT INTO public.sales
  (id,opportunity_id,commercial_entity_id,currency,
   gross_amount,tax_amount,net_amount,closed_at)
VALUES
  ('33333333-3333-4333-8333-333333333333',
   '22222222-2222-4222-8222-222222222222',
   '11111111-1111-4111-8111-111111111111',
   'PYG',1000000,0,1000000,now());

DO $$
BEGIN
  BEGIN
    PERFORM public.create_invoice_v2(
      '33333333-3333-4333-8333-333333333333',
      'NEG-TOTAL',
      900000,0,1000000,now(),null
    );
    RAISE EXCEPTION 'FAIL: inconsistent invoice total accepted';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM='subtotal plus tax must equal total' THEN
        RAISE NOTICE 'PASS NEGATIVE 3: inconsistent total';
      ELSE
        RAISE;
      END IF;
  END;
END
$$;

DO $$
BEGIN
  BEGIN
    PERFORM public.create_bank_movement_v2(
      'PYG',1000000,'sideways',now(),
      'NEGATIVE TEST','NEG-DIRECTION'
    );
    RAISE EXCEPTION 'FAIL: invalid direction accepted';
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM='invalid bank movement direction' THEN
        RAISE NOTICE 'PASS NEGATIVE 4: invalid direction';
      ELSE
        RAISE;
      END IF;
  END;
END
$$;

ROLLBACK;

-- Final residue check.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.invoices
    WHERE invoice_number IN ('TEST-INV-001','NEG-TOTAL','NEG-NO-PERM')
  ) THEN
    RAISE EXCEPTION 'FAIL: test invoice residue';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.bank_movements
    WHERE external_reference IN
      ('TEST-BANK-001','NEG-DIRECTION','NEG-NO-PERM')
  ) THEN
    RAISE EXCEPTION 'FAIL: test bank movement residue';
  END IF;

  RAISE NOTICE 'PASS CLEANUP: zero test residue';
END
$$;
