\set ON_ERROR_STOP on
BEGIN;

DO $$
DECLARE
  v_allowed uuid;
  v_denied uuid;
  v_count bigint;
BEGIN

  -- ==========================================================
  -- Usuarios reales de staging
  -- ==========================================================

  SELECT p.id
  INTO v_allowed
  FROM public.profiles p
  JOIN public.user_permissions up ON up.user_id = p.id
  WHERE p.active = true
    AND up.financial_info = true
  LIMIT 1;

  SELECT p.id
  INTO v_denied
  FROM public.profiles p
  JOIN public.user_permissions up ON up.user_id = p.id
  WHERE p.active = true
    AND COALESCE(up.financial_info,false) = false
  LIMIT 1;

  IF v_allowed IS NULL THEN
    RAISE EXCEPTION 'FAIL: falta usuario con financial_info=true';
  END IF;

  IF v_denied IS NULL THEN
    RAISE EXCEPTION 'FAIL: falta usuario con financial_info=false';
  END IF;

  -- ==========================================================
  -- SIN PERMISO
  -- ==========================================================

  PERFORM set_config('request.jwt.claim.sub', v_denied::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  IF public.has_financial_info() IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'FAIL: usuario restringido obtuvo financial_info';
  END IF;

  RAISE NOTICE 'PASS 1/10: financial_info=false respetado';

  SELECT count(*) INTO v_count FROM public.invoices;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL: usuario restringido ve invoices';
  END IF;

  RAISE NOTICE 'PASS 2/10: invoices bloqueadas';

  SELECT count(*) INTO v_count FROM public.payments;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL: usuario restringido ve payments';
  END IF;

  RAISE NOTICE 'PASS 3/10: payments bloqueados';

  SELECT count(*) INTO v_count FROM public.bank_movements;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL: usuario restringido ve bank_movements';
  END IF;

  RAISE NOTICE 'PASS 4/10: bank_movements bloqueados';

  SELECT count(*) INTO v_count
  FROM public.payment_bank_reconciliations;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL: usuario restringido ve reconciliaciones';
  END IF;

  RAISE NOTICE 'PASS 5/10: reconciliaciones bloqueadas';

  -- ==========================================================
  -- CON PERMISO
  -- ==========================================================

  PERFORM set_config('request.jwt.claim.sub', v_allowed::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  IF public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'FAIL: usuario autorizado no obtiene financial_info';
  END IF;

  RAISE NOTICE 'PASS 6/10: financial_info=true reconocido';

  -- Las consultas deben poder ejecutarse aunque staging esté vacío.

  PERFORM count(*) FROM public.invoices;
  RAISE NOTICE 'PASS 7/10: invoices accesibles autorizado';

  PERFORM count(*) FROM public.payments;
  RAISE NOTICE 'PASS 8/10: payments accesibles autorizado';

  PERFORM count(*) FROM public.bank_movements;
  RAISE NOTICE 'PASS 9/10: bank_movements accesibles autorizado';

  PERFORM count(*) FROM public.payment_bank_reconciliations;
  RAISE NOTICE 'PASS 10/10: reconciliaciones accesibles autorizado';

END $$;

ROLLBACK;
