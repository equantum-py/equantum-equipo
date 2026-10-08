BEGIN;

-- Data API: lecturas financieras sujetas a las politicas RLS existentes.
GRANT SELECT ON public.proposals, public.opportunities, public.sales TO authenticated;
GRANT UPDATE (commission_policy_id) ON public.proposals TO authenticated;

CREATE FUNCTION public.guard_proposal_commission_assignment_v3()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE v_stage text; v_outcome text;
BEGIN
  IF NEW.commission_policy_id IS NOT DISTINCT FROM OLD.commission_policy_id THEN RETURN NEW; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND active AND is_master)
     OR public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active Master with financial_info required' USING ERRCODE='42501';
  END IF;
  SELECT stage,outcome INTO STRICT v_stage,v_outcome FROM public.opportunities WHERE id=OLD.opportunity_id;
  IF OLD.status IN ('accepted','rejected') OR v_stage='closed' OR v_outcome IN ('won','lost')
     OR EXISTS (SELECT 1 FROM public.sales WHERE opportunity_id=OLD.opportunity_id) THEN
    RAISE EXCEPTION 'closed proposal commission cannot be reassigned' USING ERRCODE='55000';
  END IF;
  IF NEW.commission_policy_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.commission_policy_versions WHERE id=NEW.commission_policy_id
  ) THEN RAISE EXCEPTION 'commission policy not available' USING ERRCODE='22023'; END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_proposal_commission_assignment_v3() FROM PUBLIC,anon;
CREATE TRIGGER trg_guard_proposal_commission_assignment
BEFORE UPDATE OF commission_policy_id ON public.proposals
FOR EACH ROW EXECUTE FUNCTION public.guard_proposal_commission_assignment_v3();

CREATE FUNCTION public.assign_proposal_commission_v3(p_proposal_id uuid,p_policy_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE v_proposal public.proposals%ROWTYPE;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id=auth.uid() AND active AND is_master)
     OR public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active Master with financial_info required' USING ERRCODE='42501';
  END IF;
  SELECT * INTO v_proposal FROM public.proposals WHERE id=p_proposal_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'proposal not available' USING ERRCODE='42501'; END IF;
  -- Reintentar la misma seleccion no modifica nada, incluso despues del cierre.
  IF v_proposal.commission_policy_id IS NOT DISTINCT FROM p_policy_id THEN RETURN v_proposal.id; END IF;
  UPDATE public.proposals SET commission_policy_id=p_policy_id WHERE id=p_proposal_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'proposal update denied' USING ERRCODE='42501'; END IF;
  RETURN p_proposal_id;
END;
$$;
REVOKE ALL ON FUNCTION public.assign_proposal_commission_v3(uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.assign_proposal_commission_v3(uuid,uuid) TO authenticated;

-- Operaciones del circuito reservadas a Master activo con acceso financiero.
DO $$
DECLARE tab text; predicate text := 'public.has_financial_info() AND EXISTS (SELECT 1 FROM public.profiles WHERE id=(SELECT auth.uid()) AND active AND is_master)';
BEGIN
  FOREACH tab IN ARRAY ARRAY['opportunities','proposals','proposal_items','sales','sale_items','invoices','payments'] LOOP
    IF NOT EXISTS(SELECT 1 FROM pg_class WHERE oid=to_regclass('public.'||tab) AND relrowsecurity) THEN
      RAISE EXCEPTION 'RLS required on %',tab;
    END IF;
    EXECUTE format('GRANT SELECT,INSERT ON public.%I TO authenticated',tab);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO authenticated WITH CHECK (%s)',
      tab||' workflow master insert',tab,predicate);
  END LOOP;
  FOREACH tab IN ARRAY ARRAY['opportunities','sales','invoices'] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE TO authenticated USING (%s) WITH CHECK (%s)',
      tab||' workflow master update',tab,predicate,predicate);
  END LOOP;
END $$;
GRANT SELECT ON public.commercial_entities,public.catalog_items,public.bank_movements TO authenticated;
GRANT UPDATE(outcome,stage,closed_at,loss_reason) ON public.opportunities TO authenticated;
GRANT UPDATE(status,accepted_at) ON public.proposals TO authenticated;
-- Esta columna ya es inmutable en ventas: el permiso permite el bloqueo FOR UPDATE.
GRANT UPDATE(commission_policy_id) ON public.sales TO authenticated;
GRANT UPDATE(status,updated_at) ON public.invoices TO authenticated;
ALTER TABLE public.proposals ADD COLUMN workflow_request jsonb;

CREATE FUNCTION public.create_proposal_workflow_v3(
  p_request_id uuid,p_entity_id uuid,p_title text,p_currency text,p_items jsonb,
  p_fiscal_policy_id uuid,p_commission_policy_id uuid,p_justification text,p_evidence_reference text
) RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE payload jsonb; existing jsonb; o uuid; item uuid; v_row jsonb;
        qty numeric; price numeric; discount numeric; description text;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND active AND is_master)
     OR public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active Master with financial_info required' USING ERRCODE='42501'; END IF;
  IF p_request_id IS NULL OR p_currency NOT IN ('PYG','USD','BRL','EUR') OR p_currency IS NULL
     OR nullif(trim(p_title),'') IS NULL OR nullif(trim(p_justification),'') IS NULL
     OR nullif(trim(p_evidence_reference),'') IS NULL OR p_fiscal_policy_id IS NULL THEN
    RAISE EXCEPTION 'required proposal fields missing' USING ERRCODE='22023'; END IF;
  IF jsonb_typeof(p_items) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'items array required' USING ERRCODE='22023'; END IF;
  IF jsonb_array_length(p_items) NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'one to 100 items required' USING ERRCODE='22023'; END IF;
  payload:=jsonb_build_object('entity',p_entity_id,'title',trim(p_title),'currency',p_currency,'items',p_items,
    'fiscal',p_fiscal_policy_id,'commission',p_commission_policy_id,'reason',trim(p_justification),'evidence',trim(p_evidence_reference));
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text,0));
  SELECT workflow_request INTO existing FROM public.proposals WHERE id=p_request_id;
  IF FOUND THEN
    IF existing IS DISTINCT FROM payload THEN RAISE EXCEPTION 'request id reused with different proposal' USING ERRCODE='22023'; END IF;
    RETURN p_request_id;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.commercial_entities WHERE id=p_entity_id AND status='active') THEN
    RAISE EXCEPTION 'active commercial entity required' USING ERRCODE='22023'; END IF;
  INSERT INTO public.opportunities(commercial_entity_id,title,stage,currency,owner_id)
  VALUES(p_entity_id,trim(p_title),'open',p_currency,auth.uid()) RETURNING id INTO o;
  INSERT INTO public.proposals(id,opportunity_id,version,status,currency,total_amount,created_by,workflow_request)
  VALUES(p_request_id,o,1,'draft',p_currency,0,auth.uid(),payload);
  FOR v_row IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    qty:=(v_row->>'quantity')::numeric; price:=(v_row->>'unit_price')::numeric;
    discount:=coalesce((v_row->>'discount_amount')::numeric,0); description:=nullif(trim(v_row->>'description'),'');
    IF qty IS NULL OR qty<=0 OR price IS NULL OR price<0 OR discount<0
       OR discount>round(qty*price,2) OR description IS NULL OR qty<>round(qty,4)
       OR price<>round(price,2) OR discount<>round(discount,2)
       OR qty::text IN ('NaN','Infinity','-Infinity') OR price::text IN ('NaN','Infinity','-Infinity')
       OR discount::text IN ('NaN','Infinity','-Infinity') THEN
      RAISE EXCEPTION 'invalid proposal item' USING ERRCODE='22023'; END IF;
    INSERT INTO public.proposal_items(proposal_id,description,quantity,unit_price,discount_amount,
      line_subtotal,line_total,tax_amount)
    VALUES(p_request_id,description,qty,price,discount,round(qty*price,2),round(qty*price,2)-discount,0)
    RETURNING id INTO item;
    PERFORM public.approve_proposal_item_fiscal_v3(item,p_fiscal_policy_id,p_justification,p_evidence_reference);
  END LOOP;
  PERFORM public.assign_proposal_commission_v3(p_request_id,p_commission_policy_id);
  RETURN p_request_id;
END;
$$;
REVOKE ALL ON FUNCTION public.create_proposal_workflow_v3(uuid,uuid,text,text,jsonb,uuid,uuid,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_proposal_workflow_v3(uuid,uuid,text,text,jsonb,uuid,uuid,text,text) TO authenticated;

CREATE FUNCTION public.close_proposal_workflow_v3(p_proposal_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE o uuid; proposal public.proposals%ROWTYPE;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND active AND is_master)
     OR public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active Master with financial_info required' USING ERRCODE='42501'; END IF;
  SELECT opportunity_id INTO o FROM public.proposals WHERE id=p_proposal_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'proposal unavailable' USING ERRCODE='42501'; END IF;
  PERFORM 1 FROM public.opportunities WHERE id=o FOR UPDATE;
  SELECT * INTO STRICT proposal FROM public.proposals WHERE id=p_proposal_id FOR UPDATE;
  IF EXISTS(SELECT 1 FROM public.proposal_items WHERE proposal_id=p_proposal_id AND fiscal_approval_id IS NULL) THEN
    RAISE EXCEPTION 'approve all item fiscal decisions before closing' USING ERRCODE='22023'; END IF;
  RETURN public.close_opportunity_won(o,p_proposal_id);
END;
$$;
REVOKE ALL ON FUNCTION public.close_proposal_workflow_v3(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.close_proposal_workflow_v3(uuid) TO authenticated;

CREATE FUNCTION public.create_workflow_invoice_v3(p_sale_id uuid,p_invoice_number text,
  p_subtotal numeric,p_tax numeric,p_issued_at timestamptz,p_due_at timestamptz DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path=public AS $$
DECLARE sale public.sales%ROWTYPE; inv public.invoices%ROWTYPE; subtotal numeric; tax numeric;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND active AND is_master)
     OR public.has_financial_info() IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'active Master with financial_info required' USING ERRCODE='42501'; END IF;
  IF nullif(trim(p_invoice_number),'') IS NULL OR p_issued_at IS NULL OR p_subtotal IS NULL OR p_tax IS NULL
     OR p_subtotal<0 OR p_tax<0 OR p_subtotal+p_tax<=0 OR (p_due_at IS NOT NULL AND p_due_at<p_issued_at)
     OR p_subtotal::text IN ('NaN','Infinity','-Infinity') OR p_tax::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'invalid invoice fields' USING ERRCODE='22023'; END IF;
  p_subtotal:=round(p_subtotal,2); p_tax:=round(p_tax,2);
  IF p_subtotal+p_tax<=0 THEN RAISE EXCEPTION 'positive invoice total required' USING ERRCODE='22023'; END IF;
  SELECT * INTO sale FROM public.sales WHERE id=p_sale_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sale unavailable' USING ERRCODE='42501'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('invoice:'||trim(p_invoice_number),0));
  SELECT * INTO inv FROM public.invoices WHERE invoice_number=trim(p_invoice_number);
  IF FOUND THEN
    IF inv.sale_id IS DISTINCT FROM p_sale_id OR inv.subtotal_amount IS DISTINCT FROM p_subtotal
       OR inv.tax_amount IS DISTINCT FROM p_tax OR inv.issued_at IS DISTINCT FROM p_issued_at
       OR inv.due_at IS DISTINCT FROM p_due_at OR inv.status='void' THEN
      RAISE EXCEPTION 'invoice number reused with different operation' USING ERRCODE='22023'; END IF;
    RETURN inv.id;
  END IF;
  SELECT coalesce(sum(subtotal_amount),0),coalesce(sum(tax_amount),0) INTO subtotal,tax
  FROM public.invoices WHERE sale_id=p_sale_id AND status IN ('issued','partially_paid','paid');
  IF p_subtotal>sale.net_amount-subtotal OR p_tax>sale.tax_amount-tax THEN
    RAISE EXCEPTION 'invoice exceeds sale remaining net or tax' USING ERRCODE='22023'; END IF;
  RETURN public.create_invoice_v2(p_sale_id,trim(p_invoice_number),p_subtotal,p_tax,p_subtotal+p_tax,p_issued_at,p_due_at);
END;
$$;
REVOKE ALL ON FUNCTION public.create_workflow_invoice_v3(uuid,text,numeric,numeric,timestamptz,timestamptz) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_workflow_invoice_v3(uuid,text,numeric,numeric,timestamptz,timestamptz) TO authenticated;
COMMIT;
