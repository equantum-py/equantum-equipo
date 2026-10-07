\set ON_ERROR_STOP on

BEGIN;

-- ============================================================
-- 1. MASTER PUEDE OTORGAR
-- ============================================================

SELECT set_config(
  'request.jwt.claim.sub',
  '9ab6ef4a-71e2-462b-a6cd-395baabccdb3',
  true
);

SET LOCAL ROLE authenticated;

SELECT public.set_financial_info_permission(
  '8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b',
  true
);

RESET ROLE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.user_permissions
    WHERE user_id='8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b'
      AND financial_info=true
  ) THEN
    RAISE EXCEPTION 'FAIL: Master grant failed';
  END IF;

  RAISE NOTICE 'PASS 1/4: Master can grant financial_info';
END
$$;

-- ============================================================
-- 2. MASTER PUEDE QUITAR
-- ============================================================

SET LOCAL ROLE authenticated;

SELECT public.set_financial_info_permission(
  '8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b',
  false
);

RESET ROLE;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.user_permissions
    WHERE user_id='8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b'
      AND financial_info=true
  ) THEN
    RAISE EXCEPTION 'FAIL: Master revoke failed';
  END IF;

  RAISE NOTICE 'PASS 2/4: Master can revoke financial_info';
END
$$;

-- ============================================================
-- 3. NO-MASTER NO PUEDE OTORGAR
-- ============================================================

SELECT set_config(
  'request.jwt.claim.sub',
  '8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b',
  true
);

SET LOCAL ROLE authenticated;

DO $$
BEGIN
  BEGIN
    PERFORM public.set_financial_info_permission(
      '8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b',
      true
    );

    RAISE EXCEPTION 'FAIL: non-Master granted financial_info';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'PASS 3/4: non-Master cannot grant financial_info';
  END;
END
$$;

-- ============================================================
-- 4. NO-MASTER NO PUEDE QUITAR
-- ============================================================

DO $$
BEGIN
  BEGIN
    PERFORM public.set_financial_info_permission(
      '8df5806c-7bf7-4e2c-b8a4-39dfb705ab5b',
      false
    );

    RAISE EXCEPTION 'FAIL: non-Master revoked financial_info';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'PASS 4/4: non-Master cannot revoke financial_info';
  END;
END
$$;

RESET ROLE;

ROLLBACK;

-- ============================================================
-- RESIDUO
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE 'PASS CLEANUP: transaction rolled back';
END
$$;
