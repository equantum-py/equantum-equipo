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

COMMIT;
