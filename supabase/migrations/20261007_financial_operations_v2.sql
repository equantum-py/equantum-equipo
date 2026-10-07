BEGIN;

-- ============================================================
-- FINANCIAL OPERATIONS V2
-- Escrituras financieras controladas por backend.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_invoice_v2(
  p_sale_id uuid,
  p_invoice_number text,
  p_subtotal_amount numeric,
  p_tax_amount numeric,
  p_total_amount numeric,
  p_issued_at timestamptz DEFAULT now(),
  p_due_at timestamptz DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_sale public.sales%rowtype;
  v_invoice_id uuid;
BEGIN
  IF NOT public.has_financial_info() THEN
    RAISE EXCEPTION 'financial_info required'
      USING ERRCODE = '42501';
  END IF;

  IF p_total_amount IS NULL OR p_total_amount < 0 THEN
    RAISE EXCEPTION 'invoice total must be non-negative';
  END IF;

  IF COALESCE(p_subtotal_amount,0) < 0
     OR COALESCE(p_tax_amount,0) < 0 THEN
    RAISE EXCEPTION 'invoice amounts must be non-negative';
  END IF;

  IF round(
       COALESCE(p_subtotal_amount,0) +
       COALESCE(p_tax_amount,0), 2
     ) <> round(p_total_amount,2) THEN
    RAISE EXCEPTION 'subtotal plus tax must equal total';
  END IF;

  SELECT *
    INTO v_sale
  FROM public.sales
  WHERE id = p_sale_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'sale not found';
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
    due_at,
    created_by
  )
  VALUES(
    v_sale.id,
    v_sale.commercial_entity_id,
    NULLIF(trim(p_invoice_number),''),
    v_sale.currency,
    COALESCE(p_subtotal_amount,0),
    COALESCE(p_tax_amount,0),
    p_total_amount,
    'issued',
    COALESCE(p_issued_at,now()),
    p_due_at,
    auth.uid()
  )
  RETURNING id INTO v_invoice_id;

  RETURN v_invoice_id;
END;
$$;


CREATE OR REPLACE FUNCTION public.create_bank_movement_v2(
  p_currency text,
  p_amount numeric,
  p_direction text,
  p_occurred_at timestamptz,
  p_description text DEFAULT NULL,
  p_external_reference text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.has_financial_info() THEN
    RAISE EXCEPTION 'financial_info required'
      USING ERRCODE = '42501';
  END IF;

  IF p_currency IS NULL OR trim(p_currency) = '' THEN
    RAISE EXCEPTION 'currency required';
  END IF;

  IF p_amount IS NULL OR p_amount = 0 THEN
    RAISE EXCEPTION 'bank movement amount must be non-zero';
  END IF;

  IF p_direction NOT IN ('credit','debit') THEN
    RAISE EXCEPTION 'invalid bank movement direction';
  END IF;

  IF p_occurred_at IS NULL THEN
    RAISE EXCEPTION 'occurred_at required';
  END IF;

  INSERT INTO public.bank_movements(
    currency,
    amount,
    direction,
    occurred_at,
    description,
    external_reference
  )
  VALUES(
    upper(trim(p_currency)),
    abs(p_amount),
    p_direction,
    p_occurred_at,
    NULLIF(trim(p_description),''),
    NULLIF(trim(p_external_reference),'')
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;


REVOKE ALL ON FUNCTION public.create_invoice_v2(
  uuid,text,numeric,numeric,numeric,timestamptz,timestamptz
) FROM PUBLIC;

REVOKE ALL ON FUNCTION public.create_bank_movement_v2(
  text,numeric,text,timestamptz,text,text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_invoice_v2(
  uuid,text,numeric,numeric,numeric,timestamptz,timestamptz
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.create_bank_movement_v2(
  text,numeric,text,timestamptz,text,text
) TO authenticated;

COMMIT;
