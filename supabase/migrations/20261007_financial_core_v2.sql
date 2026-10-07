-- Financial Core V2
-- Sale != Invoice != Payment != Bank Movement
-- PREPARACION: staging solamente. No aplicar a produccion.

BEGIN;

-- ============================================================
-- 1. INVOICES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id uuid NOT NULL REFERENCES public.sales(id) ON DELETE RESTRICT,
  commercial_entity_id uuid NOT NULL REFERENCES public.commercial_entities(id) ON DELETE RESTRICT,
  invoice_number text,
  currency text NOT NULL,
  subtotal_amount numeric(18,2) NOT NULL DEFAULT 0,
  tax_amount numeric(18,2) NOT NULL DEFAULT 0,
  total_amount numeric(18,2) NOT NULL,
  status text NOT NULL DEFAULT 'issued'
    CHECK (status IN ('draft','issued','partially_paid','paid','void')),
  issued_at timestamptz,
  due_at timestamptz,
  voided_at timestamptz,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT invoices_amounts_check CHECK (
    subtotal_amount >= 0
    AND tax_amount >= 0
    AND total_amount >= 0
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS invoices_number_uq
  ON public.invoices(invoice_number)
  WHERE invoice_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS invoices_sale_idx
  ON public.invoices(sale_id);

CREATE INDEX IF NOT EXISTS invoices_entity_idx
  ON public.invoices(commercial_entity_id);

-- ============================================================
-- 2. PAYMENTS / COBROS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES public.invoices(id) ON DELETE RESTRICT,
  commercial_entity_id uuid NOT NULL REFERENCES public.commercial_entities(id) ON DELETE RESTRICT,
  currency text NOT NULL,
  amount numeric(18,2) NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'confirmed'
    CHECK (status IN ('pending','confirmed','reversed')),
  payment_method text,
  external_reference text,
  paid_at timestamptz,
  reversed_at timestamptz,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payments_invoice_idx
  ON public.payments(invoice_id);

CREATE INDEX IF NOT EXISTS payments_entity_idx
  ON public.payments(commercial_entity_id);

CREATE UNIQUE INDEX IF NOT EXISTS payments_external_reference_uq
  ON public.payments(external_reference)
  WHERE external_reference IS NOT NULL;

-- ============================================================
-- 3. BANK MOVEMENTS
-- Movimiento bancario NO equivale automáticamente a Payment.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.bank_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  currency text NOT NULL,
  amount numeric(18,2) NOT NULL CHECK (amount <> 0),
  direction text NOT NULL CHECK (direction IN ('credit','debit')),
  occurred_at timestamptz NOT NULL,
  description text,
  external_reference text,
  reconciliation_status text NOT NULL DEFAULT 'unreconciled'
    CHECK (reconciliation_status IN ('unreconciled','reconciled','ignored')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS bank_movements_external_reference_uq
  ON public.bank_movements(external_reference)
  WHERE external_reference IS NOT NULL;

CREATE INDEX IF NOT EXISTS bank_movements_reconciliation_idx
  ON public.bank_movements(reconciliation_status, occurred_at);

-- ============================================================
-- 4. RECONCILIATION
-- El mismo movimiento bancario no puede reconocer dos Payments.
-- Un Payment tampoco puede conciliarse dos veces.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.payment_bank_reconciliations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id uuid NOT NULL UNIQUE REFERENCES public.payments(id) ON DELETE RESTRICT,
  bank_movement_id uuid NOT NULL UNIQUE REFERENCES public.bank_movements(id) ON DELETE RESTRICT,
  reconciled_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reconciled_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- 5. ESTADO DE FACTURA DERIVADO DE COBROS CONFIRMADOS
-- No convertir moneda. Solo Payments de misma moneda.
-- ============================================================

CREATE OR REPLACE FUNCTION public.refresh_invoice_payment_status(
  p_invoice_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_invoice public.invoices%rowtype;
  v_paid numeric(18,2);
  v_status text;
BEGIN
  SELECT *
    INTO v_invoice
  FROM public.invoices
  WHERE id = p_invoice_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invoice not found';
  END IF;

  IF v_invoice.status = 'void' THEN
    RETURN 'void';
  END IF;

  SELECT COALESCE(sum(amount),0)
    INTO v_paid
  FROM public.payments
  WHERE invoice_id = p_invoice_id
    AND status = 'confirmed'
    AND currency = v_invoice.currency;

  IF v_paid <= 0 THEN
    v_status := CASE
      WHEN v_invoice.issued_at IS NULL THEN 'draft'
      ELSE 'issued'
    END;
  ELSIF v_paid < v_invoice.total_amount THEN
    v_status := 'partially_paid';
  ELSE
    v_status := 'paid';
  END IF;

  UPDATE public.invoices
  SET status = v_status,
      updated_at = now()
  WHERE id = p_invoice_id;

  RETURN v_status;
END;
$$;

-- ============================================================
-- 6. REGISTRAR PAYMENT
-- Idempotencia opcional mediante external_reference.
-- No crea Bank Movement.
-- ============================================================

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
BEGIN
  IF NOT public.has_financial_info() THEN
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
    SELECT id
      INTO v_payment_id
    FROM public.payments
    WHERE external_reference = p_external_reference;

    IF v_payment_id IS NOT NULL THEN
      RETURN v_payment_id;
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

-- ============================================================
-- 7. CONCILIAR PAYMENT CON BANK MOVEMENT
-- Conciliar NO genera otro Payment/cobro.
-- ============================================================

CREATE OR REPLACE FUNCTION public.reconcile_payment_bank_movement(
  p_payment_id uuid,
  p_bank_movement_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_payment public.payments%rowtype;
  v_movement public.bank_movements%rowtype;
  v_reconciliation_id uuid;
BEGIN
  IF NOT public.has_financial_info() THEN
    RAISE EXCEPTION 'financial_info required'
      USING ERRCODE = '42501';
  END IF;

  SELECT *
    INTO v_payment
  FROM public.payments
  WHERE id = p_payment_id
    AND status = 'confirmed'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'confirmed payment not found';
  END IF;

  SELECT *
    INTO v_movement
  FROM public.bank_movements
  WHERE id = p_bank_movement_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'bank movement not found';
  END IF;

  SELECT id
    INTO v_reconciliation_id
  FROM public.payment_bank_reconciliations
  WHERE payment_id = p_payment_id
    AND bank_movement_id = p_bank_movement_id;

  IF v_reconciliation_id IS NOT NULL THEN
    RETURN v_reconciliation_id;
  END IF;

  IF v_movement.reconciliation_status <> 'unreconciled' THEN
    RAISE EXCEPTION 'bank movement already reconciled or ignored';
  END IF;

  IF v_movement.direction <> 'credit' THEN
    RAISE EXCEPTION 'payment requires credit bank movement';
  END IF;

  IF v_payment.currency IS DISTINCT FROM v_movement.currency THEN
    RAISE EXCEPTION 'payment and bank movement currency mismatch';
  END IF;

  IF v_payment.amount IS DISTINCT FROM abs(v_movement.amount) THEN
    RAISE EXCEPTION 'payment and bank movement amount mismatch';
  END IF;

  INSERT INTO public.payment_bank_reconciliations(
    payment_id,
    bank_movement_id,
    reconciled_by
  )
  VALUES(
    p_payment_id,
    p_bank_movement_id,
    auth.uid()
  )
  RETURNING id INTO v_reconciliation_id;

  UPDATE public.bank_movements
  SET reconciliation_status = 'reconciled'
  WHERE id = p_bank_movement_id;

  RETURN v_reconciliation_id;
END;
$$;

-- ============================================================
-- 8. RLS
-- ============================================================

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_bank_reconciliations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invoices financial read"
ON public.invoices
FOR SELECT TO authenticated
USING (public.has_financial_info());

CREATE POLICY "payments financial read"
ON public.payments
FOR SELECT TO authenticated
USING (public.has_financial_info());

CREATE POLICY "bank movements financial read"
ON public.bank_movements
FOR SELECT TO authenticated
USING (public.has_financial_info());

CREATE POLICY "payment reconciliations financial read"
ON public.payment_bank_reconciliations
FOR SELECT TO authenticated
USING (public.has_financial_info());

REVOKE ALL ON FUNCTION public.refresh_invoice_payment_status(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.register_invoice_payment(uuid,numeric,text,text,text,timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reconcile_payment_bank_movement(uuid,uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.refresh_invoice_payment_status(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.register_invoice_payment(uuid,numeric,text,text,text,timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reconcile_payment_bank_movement(uuid,uuid) TO authenticated;

COMMIT;
