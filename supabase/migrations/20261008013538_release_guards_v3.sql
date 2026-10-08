-- Release guards: local rehearsal only until approved release.
BEGIN;

DROP TRIGGER IF EXISTS trg_apply_task_triage_v2 ON public.tasks;
CREATE TRIGGER trg_apply_task_triage_v2
BEFORE INSERT OR UPDATE OF
  client_urgency, client_waiting_days, affects_sales, blocks_others, strategic,
  triage_score, priority, triage_reasons
ON public.tasks FOR EACH ROW
EXECUTE FUNCTION public.apply_task_triage_v2();

CREATE OR REPLACE FUNCTION public.register_invoice_payment(
  p_invoice_id uuid,
  p_amount numeric,
  p_currency text,
  p_payment_method text DEFAULT NULL,
  p_external_reference text DEFAULT NULL,
  p_paid_at timestamptz DEFAULT now()
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_invoice public.invoices%rowtype;
  v_payment_id uuid;
  v_existing public.payments%rowtype;
BEGIN
  IF public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'financial_info required'
      USING ERRCODE = '42501';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'payment amount must be positive';
  END IF;

  SELECT *
    INTO v_invoice
  FROM public.invoices
  WHERE id = p_invoice_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invoice not found';
  END IF;

  IF v_invoice.status = 'void' THEN
    RAISE EXCEPTION 'cannot pay void invoice';
  END IF;

  IF p_currency IS DISTINCT FROM v_invoice.currency THEN
    RAISE EXCEPTION 'payment currency must match invoice currency';
  END IF;

  IF p_external_reference IS NOT NULL THEN
    IF btrim(p_external_reference) = '' THEN
      RAISE EXCEPTION 'payment external reference must not be blank'
        USING ERRCODE = '22023';
    END IF;

    SELECT * INTO v_existing
    FROM public.payments
    WHERE external_reference = p_external_reference;

    IF FOUND THEN
      IF v_existing.invoice_id IS DISTINCT FROM p_invoice_id
         OR v_existing.amount IS DISTINCT FROM round(p_amount,2)
         OR v_existing.currency IS DISTINCT FROM p_currency
         OR v_existing.payment_method IS DISTINCT FROM p_payment_method
         OR v_existing.status IS DISTINCT FROM 'confirmed' THEN
        RAISE EXCEPTION 'payment idempotency reference conflicts with existing payload'
          USING ERRCODE = '22023';
      END IF;
      RETURN v_existing.id;
    END IF;
  END IF;

  INSERT INTO public.payments(
    invoice_id,
    commercial_entity_id,
    currency,
    amount,
    status,
    payment_method,
    external_reference,
    paid_at,
    created_by
  )
  VALUES(
    v_invoice.id,
    v_invoice.commercial_entity_id,
    v_invoice.currency,
    p_amount,
    'confirmed',
    p_payment_method,
    p_external_reference,
    p_paid_at,
    auth.uid()
  )
  RETURNING id INTO v_payment_id;

  PERFORM public.refresh_invoice_payment_status(v_invoice.id);

  RETURN v_payment_id;
END;
$$;

REVOKE ALL ON FUNCTION public.register_invoice_payment(uuid,numeric,text,text,text,timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_invoice_payment(uuid,numeric,text,text,text,timestamptz) TO authenticated;
COMMIT;
