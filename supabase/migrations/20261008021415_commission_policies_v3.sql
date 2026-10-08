BEGIN;

CREATE TABLE public.commission_policy_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_code text NOT NULL CHECK (length(trim(policy_code)) > 0),
  version integer NOT NULL CHECK (version > 0),
  rate_percent numeric(7,4) NOT NULL CHECK (rate_percent BETWEEN 0 AND 100),
  created_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (policy_code, version)
);
ALTER TABLE public.commission_policy_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "commission versions authorized read"
ON public.commission_policy_versions FOR SELECT TO authenticated
USING (public.has_financial_info() OR EXISTS (
  SELECT 1 FROM public.profiles p
  WHERE p.id = (SELECT auth.uid()) AND p.active AND p.is_master
));
CREATE POLICY "commission versions master insert"
ON public.commission_policy_versions FOR INSERT TO authenticated
WITH CHECK (created_by = (SELECT auth.uid()) AND EXISTS (
  SELECT 1 FROM public.profiles p
  WHERE p.id = (SELECT auth.uid()) AND p.active AND p.is_master
));
REVOKE ALL ON public.commission_policy_versions FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON public.commission_policy_versions TO authenticated;

CREATE FUNCTION public.guard_commission_policy_version()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION 'commission policy versions are immutable; insert a new version'
    USING ERRCODE = '55000';
END;
$$;
REVOKE ALL ON FUNCTION public.guard_commission_policy_version() FROM PUBLIC, anon;
CREATE TRIGGER trg_guard_commission_policy_version
BEFORE UPDATE OR DELETE ON public.commission_policy_versions
FOR EACH ROW EXECUTE FUNCTION public.guard_commission_policy_version();

ALTER TABLE public.proposals ADD COLUMN commission_policy_id uuid
  REFERENCES public.commission_policy_versions(id) ON DELETE RESTRICT;
CREATE INDEX proposals_commission_policy_idx ON public.proposals(commission_policy_id)
  WHERE commission_policy_id IS NOT NULL;

ALTER TABLE public.sales
  ADD COLUMN commission_policy_id uuid REFERENCES public.commission_policy_versions(id) ON DELETE RESTRICT,
  ADD COLUMN commission_policy_code text,
  ADD COLUMN commission_policy_version integer,
  ADD COLUMN commission_rate_percent numeric(7,4),
  ADD COLUMN commission_amount numeric(18,2);
CREATE INDEX sales_commission_policy_idx ON public.sales(commission_policy_id)
  WHERE commission_policy_id IS NOT NULL;
ALTER TABLE public.sales ADD CONSTRAINT sales_commission_snapshot_v3_check CHECK (
  (commission_policy_id IS NULL AND commission_policy_code IS NULL
   AND commission_policy_version IS NULL AND commission_rate_percent IS NULL
   AND commission_amount IS NULL)
  OR
  (commission_policy_id IS NOT NULL AND commission_policy_code IS NOT NULL
   AND commission_policy_version IS NOT NULL AND commission_policy_version > 0
   AND commission_rate_percent IS NOT NULL AND commission_rate_percent BETWEEN 0 AND 100
   AND commission_amount IS NOT NULL AND commission_amount >= 0
   AND commission_base_amount IS NOT NULL AND commission_base_amount >= 0
   AND commission_base_amount = gross_amount - tax_amount
   AND commission_amount = round(commission_base_amount * commission_rate_percent / 100, 2))
);

CREATE FUNCTION public.snapshot_sale_commission_v3()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = public
AS $$
DECLARE
  v_policy_id uuid;
  v_policy public.commission_policy_versions%ROWTYPE;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF ROW(NEW.commission_policy_id, NEW.commission_policy_code,
           NEW.commission_policy_version, NEW.commission_rate_percent,
           NEW.commission_amount, NEW.commission_base_amount)
       IS DISTINCT FROM
       ROW(OLD.commission_policy_id, OLD.commission_policy_code,
           OLD.commission_policy_version, OLD.commission_rate_percent,
           OLD.commission_amount, OLD.commission_base_amount)
       OR (OLD.commission_policy_id IS NOT NULL AND
           ROW(NEW.gross_amount, NEW.tax_amount, NEW.net_amount, NEW.currency, NEW.proposal_id)
           IS DISTINCT FROM
           ROW(OLD.gross_amount, OLD.tax_amount, OLD.net_amount, OLD.currency, OLD.proposal_id))
    THEN
      RAISE EXCEPTION 'historical sale commission snapshot is immutable'
        USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
  END IF;

  SELECT commission_policy_id INTO v_policy_id
  FROM public.proposals WHERE id = NEW.proposal_id;

  -- Sin politica explicita, no inventar porcentaje ni importe historico.
  NEW.commission_policy_id := NULL;
  NEW.commission_policy_code := NULL;
  NEW.commission_policy_version := NULL;
  NEW.commission_rate_percent := NULL;
  NEW.commission_amount := NULL;
  IF v_policy_id IS NULL THEN RETURN NEW; END IF;

  SELECT * INTO STRICT v_policy
  FROM public.commission_policy_versions WHERE id = v_policy_id;
  IF NEW.gross_amount - NEW.tax_amount < 0 OR NEW.tax_amount < 0 THEN
    RAISE EXCEPTION 'invalid commission base' USING ERRCODE = '22023';
  END IF;
  NEW.commission_base_amount := NEW.gross_amount - NEW.tax_amount;
  NEW.commission_policy_id := v_policy.id;
  NEW.commission_policy_code := v_policy.policy_code;
  NEW.commission_policy_version := v_policy.version;
  NEW.commission_rate_percent := v_policy.rate_percent;
  NEW.commission_amount := round(NEW.commission_base_amount * v_policy.rate_percent / 100, 2);
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.snapshot_sale_commission_v3() FROM PUBLIC, anon;
CREATE TRIGGER trg_snapshot_sale_commission_v3
BEFORE INSERT OR UPDATE ON public.sales
FOR EACH ROW EXECUTE FUNCTION public.snapshot_sale_commission_v3();

COMMIT;
