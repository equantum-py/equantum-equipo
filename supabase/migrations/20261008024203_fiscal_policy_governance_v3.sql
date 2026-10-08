BEGIN;

CREATE TABLE public.fiscal_policy_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_code text NOT NULL CHECK (length(trim(policy_code))>0),
  version integer NOT NULL CHECK (version>0),
  classification text NOT NULL CHECK (classification IN ('taxable','export_zero','exempt')),
  rate_percent numeric(7,4) NOT NULL CHECK (rate_percent BETWEEN 0 AND 100),
  basis_reference text NOT NULL CHECK (length(trim(basis_reference))>0),
  created_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(policy_code,version),
  CHECK (classification='taxable' OR rate_percent=0)
);
CREATE TABLE public.proposal_item_fiscal_approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_item_id uuid NOT NULL REFERENCES public.proposal_items(id) ON DELETE RESTRICT,
  policy_id uuid NOT NULL REFERENCES public.fiscal_policy_versions(id) ON DELETE RESTRICT,
  approved_base_amount numeric(18,2) NOT NULL CHECK (approved_base_amount>=0),
  currency text NOT NULL,
  justification text NOT NULL CHECK (length(trim(justification))>0),
  evidence_reference text NOT NULL CHECK (length(trim(evidence_reference))>0),
  approved_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  approved_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX fiscal_approvals_item_idx ON public.proposal_item_fiscal_approvals(proposal_item_id);
CREATE INDEX fiscal_approvals_policy_idx ON public.proposal_item_fiscal_approvals(policy_id);
ALTER TABLE public.fiscal_policy_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proposal_item_fiscal_approvals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fiscal policy authorized read" ON public.fiscal_policy_versions
FOR SELECT TO authenticated USING (public.has_financial_info() OR EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id=(SELECT auth.uid()) AND p.active AND p.is_master
));
CREATE POLICY "fiscal policy master insert" ON public.fiscal_policy_versions
FOR INSERT TO authenticated WITH CHECK (created_by=(SELECT auth.uid()) AND EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id=(SELECT auth.uid()) AND p.active AND p.is_master
));
CREATE POLICY "fiscal approvals authorized read" ON public.proposal_item_fiscal_approvals
FOR SELECT TO authenticated USING (public.has_financial_info() OR EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id=(SELECT auth.uid()) AND p.active AND p.is_master
));
CREATE POLICY "fiscal approvals master insert" ON public.proposal_item_fiscal_approvals
FOR INSERT TO authenticated WITH CHECK (approved_by=(SELECT auth.uid()) AND EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id=(SELECT auth.uid()) AND p.active AND p.is_master
));
REVOKE ALL ON public.fiscal_policy_versions, public.proposal_item_fiscal_approvals FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON public.fiscal_policy_versions, public.proposal_item_fiscal_approvals TO authenticated;

CREATE FUNCTION public.guard_fiscal_version_v3()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
BEGIN
  RAISE EXCEPTION 'fiscal versions and approvals are immutable; create a new decision'
    USING ERRCODE='55000';
END;
$$;
REVOKE ALL ON FUNCTION public.guard_fiscal_version_v3() FROM PUBLIC, anon;
CREATE TRIGGER trg_guard_fiscal_policy_version BEFORE UPDATE OR DELETE ON public.fiscal_policy_versions
FOR EACH ROW EXECUTE FUNCTION public.guard_fiscal_version_v3();
CREATE TRIGGER trg_guard_fiscal_approval BEFORE UPDATE OR DELETE ON public.proposal_item_fiscal_approvals
FOR EACH ROW EXECUTE FUNCTION public.guard_fiscal_version_v3();

ALTER TABLE public.proposal_items ADD COLUMN fiscal_approval_id uuid
  REFERENCES public.proposal_item_fiscal_approvals(id) ON DELETE RESTRICT;
CREATE INDEX proposal_items_fiscal_approval_idx ON public.proposal_items(fiscal_approval_id)
  WHERE fiscal_approval_id IS NOT NULL;

CREATE FUNCTION public.validate_fiscal_approval_v3()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE v_item public.proposal_items%ROWTYPE; v_currency text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND active AND is_master)
     OR public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active Master with financial_info required' USING ERRCODE='42501';
  END IF;
  SELECT * INTO STRICT v_item FROM public.proposal_items WHERE id=NEW.proposal_item_id FOR UPDATE;
  SELECT currency INTO STRICT v_currency FROM public.proposals WHERE id=v_item.proposal_id FOR UPDATE;
  IF v_currency IS NULL OR round(v_item.quantity*v_item.unit_price,2)-v_item.discount_amount<0 THEN
    RAISE EXCEPTION 'invalid fiscal base or currency' USING ERRCODE='22023';
  END IF;
  NEW.approved_base_amount:=round(v_item.quantity*v_item.unit_price,2)-v_item.discount_amount;
  NEW.currency:=v_currency;
  NEW.approved_by:=auth.uid();
  NEW.approved_at:=clock_timestamp();
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.validate_fiscal_approval_v3() FROM PUBLIC, anon;
CREATE TRIGGER trg_validate_fiscal_approval BEFORE INSERT ON public.proposal_item_fiscal_approvals
FOR EACH ROW EXECUTE FUNCTION public.validate_fiscal_approval_v3();

CREATE FUNCTION public.apply_item_fiscal_snapshot_v3()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE v_approval public.proposal_item_fiscal_approvals%ROWTYPE; v_policy public.fiscal_policy_versions%ROWTYPE;
        v_currency text; v_base numeric(18,2);
BEGIN
  IF TG_OP='UPDATE' AND OLD.fiscal_approval_id IS NOT NULL AND NEW.fiscal_approval_id IS NULL THEN
    RAISE EXCEPTION 'approved fiscal decision cannot be removed' USING ERRCODE='55000';
  END IF;
  IF NEW.fiscal_approval_id IS NULL THEN RETURN NEW; END IF;
  SELECT * INTO STRICT v_approval FROM public.proposal_item_fiscal_approvals WHERE id=NEW.fiscal_approval_id;
  SELECT * INTO STRICT v_policy FROM public.fiscal_policy_versions WHERE id=v_approval.policy_id;
  SELECT currency INTO STRICT v_currency FROM public.proposals WHERE id=NEW.proposal_id;
  v_base:=round(NEW.quantity*NEW.unit_price,2)-NEW.discount_amount;
  IF v_approval.proposal_item_id IS DISTINCT FROM NEW.id
     OR v_approval.currency IS DISTINCT FROM v_currency
     OR v_approval.approved_base_amount IS DISTINCT FROM v_base THEN
    RAISE EXCEPTION 'fiscal approval does not match item/base/currency; new proposal version required'
      USING ERRCODE='22023';
  END IF;
  NEW.line_subtotal:=round(NEW.quantity*NEW.unit_price,2);
  NEW.tax_treatment:=v_policy.classification;
  NEW.tax_amount:=round(v_base*v_policy.rate_percent/100,2);
  NEW.line_total:=v_base+NEW.tax_amount;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.apply_item_fiscal_snapshot_v3() FROM PUBLIC, anon;
CREATE TRIGGER trg_apply_item_fiscal_snapshot BEFORE INSERT OR UPDATE ON public.proposal_items
FOR EACH ROW EXECUTE FUNCTION public.apply_item_fiscal_snapshot_v3();

-- Permisos nuevos limitados a aprobación/campos derivados; conservar políticas existentes.
CREATE POLICY "proposal fiscal master update" ON public.proposals FOR UPDATE TO authenticated
USING (public.has_financial_info() AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=(SELECT auth.uid()) AND p.active AND p.is_master))
WITH CHECK (public.has_financial_info() AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=(SELECT auth.uid()) AND p.active AND p.is_master));
CREATE POLICY "proposal items fiscal master update" ON public.proposal_items FOR UPDATE TO authenticated
USING (public.has_financial_info() AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=(SELECT auth.uid()) AND p.active AND p.is_master))
WITH CHECK (public.has_financial_info() AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=(SELECT auth.uid()) AND p.active AND p.is_master));
GRANT UPDATE(fiscal_approval_id) ON public.proposal_items TO authenticated;
GRANT UPDATE(subtotal_amount,discount_amount,tax_amount,total_amount) ON public.proposals TO authenticated;

CREATE FUNCTION public.approve_proposal_item_fiscal_v3(
  p_item_id uuid,p_policy_id uuid,p_justification text,p_evidence_reference text
) RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE v_id uuid; v_proposal uuid;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND active AND is_master)
     OR public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active Master with financial_info required' USING ERRCODE='42501';
  END IF;
  IF nullif(trim(p_justification),'') IS NULL OR nullif(trim(p_evidence_reference),'') IS NULL THEN
    RAISE EXCEPTION 'fiscal justification and evidence reference required' USING ERRCODE='22023';
  END IF;
  SELECT proposal_id INTO STRICT v_proposal FROM public.proposal_items WHERE id=p_item_id FOR UPDATE;
  INSERT INTO public.proposal_item_fiscal_approvals(proposal_item_id,policy_id,approved_base_amount,
    currency,justification,evidence_reference,approved_by)
  VALUES(p_item_id,p_policy_id,0,'pending',trim(p_justification),trim(p_evidence_reference),auth.uid())
  RETURNING id INTO v_id;
  UPDATE public.proposal_items SET fiscal_approval_id=v_id WHERE id=p_item_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'item update denied' USING ERRCODE='42501'; END IF;
  UPDATE public.proposals p SET
    subtotal_amount=s.subtotal, discount_amount=s.discount,
    tax_amount=s.tax, total_amount=s.total
  FROM (SELECT coalesce(sum(coalesce(line_subtotal,quantity*unit_price)),0) AS subtotal,
    coalesce(sum(discount_amount),0) AS discount, coalesce(sum(tax_amount),0) AS tax,
    coalesce(sum(coalesce(line_total,coalesce(line_subtotal,quantity*unit_price)-discount_amount+tax_amount)),0) AS total
    FROM public.proposal_items WHERE proposal_id=v_proposal) s
  WHERE p.id=v_proposal;
  IF NOT FOUND THEN RAISE EXCEPTION 'proposal update denied' USING ERRCODE='42501'; END IF;
  RETURN v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.approve_proposal_item_fiscal_v3(uuid,uuid,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.approve_proposal_item_fiscal_v3(uuid,uuid,text,text) TO authenticated;

ALTER TABLE public.sale_items
  ADD COLUMN fiscal_approval_id uuid REFERENCES public.proposal_item_fiscal_approvals(id) ON DELETE RESTRICT,
  ADD COLUMN fiscal_policy_code text,
  ADD COLUMN fiscal_policy_version integer,
  ADD COLUMN fiscal_rate_percent numeric(7,4),
  ADD COLUMN fiscal_approved_by uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
  ADD COLUMN fiscal_approved_at timestamptz,
  ADD COLUMN fiscal_evidence_reference text;
CREATE INDEX sale_items_fiscal_approval_idx ON public.sale_items(fiscal_approval_id)
  WHERE fiscal_approval_id IS NOT NULL;

CREATE FUNCTION public.snapshot_sale_item_fiscal_v3()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE v_id uuid; v_approval public.proposal_item_fiscal_approvals%ROWTYPE;
        v_policy public.fiscal_policy_versions%ROWTYPE; v_currency text;
BEGIN
  IF TG_OP='UPDATE' THEN
    IF ROW(NEW.fiscal_approval_id,NEW.fiscal_policy_code,NEW.fiscal_policy_version,
      NEW.fiscal_rate_percent,NEW.fiscal_approved_by,NEW.fiscal_approved_at,NEW.fiscal_evidence_reference)
      IS DISTINCT FROM ROW(OLD.fiscal_approval_id,OLD.fiscal_policy_code,OLD.fiscal_policy_version,
      OLD.fiscal_rate_percent,OLD.fiscal_approved_by,OLD.fiscal_approved_at,OLD.fiscal_evidence_reference)
      OR (OLD.fiscal_approval_id IS NOT NULL AND ROW(NEW.tax_amount,NEW.tax_treatment,NEW.total_amount,
      NEW.subtotal_amount,NEW.discount_amount,NEW.quantity,NEW.unit_price,NEW.sale_id,NEW.source_proposal_item_id)
      IS DISTINCT FROM ROW(OLD.tax_amount,OLD.tax_treatment,OLD.total_amount,
      OLD.subtotal_amount,OLD.discount_amount,OLD.quantity,OLD.unit_price,OLD.sale_id,OLD.source_proposal_item_id)) THEN
      RAISE EXCEPTION 'historical fiscal snapshot immutable' USING ERRCODE='55000';
    END IF;
    RETURN NEW;
  END IF;
  SELECT fiscal_approval_id INTO v_id FROM public.proposal_items WHERE id=NEW.source_proposal_item_id;
  NEW.fiscal_approval_id:=NULL; NEW.fiscal_policy_code:=NULL; NEW.fiscal_policy_version:=NULL;
  NEW.fiscal_rate_percent:=NULL; NEW.fiscal_approved_by:=NULL; NEW.fiscal_approved_at:=NULL;
  NEW.fiscal_evidence_reference:=NULL;
  IF v_id IS NULL THEN RETURN NEW; END IF;
  SELECT * INTO STRICT v_approval FROM public.proposal_item_fiscal_approvals WHERE id=v_id;
  SELECT * INTO STRICT v_policy FROM public.fiscal_policy_versions WHERE id=v_approval.policy_id;
  SELECT currency INTO STRICT v_currency FROM public.sales WHERE id=NEW.sale_id;
  IF v_approval.currency IS DISTINCT FROM v_currency
     OR v_approval.approved_base_amount IS DISTINCT FROM NEW.subtotal_amount-NEW.discount_amount
     OR NEW.tax_amount IS DISTINCT FROM round(v_approval.approved_base_amount*v_policy.rate_percent/100,2)
     OR NEW.tax_treatment IS DISTINCT FROM v_policy.classification
     OR NEW.total_amount IS DISTINCT FROM v_approval.approved_base_amount+NEW.tax_amount THEN
    RAISE EXCEPTION 'sale fiscal snapshot differs from approved decision' USING ERRCODE='22023';
  END IF;
  NEW.fiscal_approval_id:=v_id; NEW.fiscal_policy_code:=v_policy.policy_code;
  NEW.fiscal_policy_version:=v_policy.version; NEW.fiscal_rate_percent:=v_policy.rate_percent;
  NEW.fiscal_approved_by:=v_approval.approved_by; NEW.fiscal_approved_at:=v_approval.approved_at;
  NEW.fiscal_evidence_reference:=v_approval.evidence_reference;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.snapshot_sale_item_fiscal_v3() FROM PUBLIC, anon;
CREATE TRIGGER trg_snapshot_sale_item_fiscal BEFORE INSERT OR UPDATE ON public.sale_items
FOR EACH ROW EXECUTE FUNCTION public.snapshot_sale_item_fiscal_v3();

COMMIT;
