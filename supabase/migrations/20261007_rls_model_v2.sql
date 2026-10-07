BEGIN;

-- ============================================================
-- eQuantum Relanzamiento 2026
-- RLS Modelo V2
-- Portal cerrado por defecto.
-- Operativas: usuarios internos activos.
-- Financieras: internos + financial_info.
-- ============================================================

-- ---------- OPERATIVAS ----------

CREATE POLICY "commercial entities internal read"
ON public.commercial_entities
FOR SELECT TO authenticated
USING (public.is_internal_user());

CREATE POLICY "catalog items internal read"
ON public.catalog_items
FOR SELECT TO authenticated
USING (public.is_internal_user());

CREATE POLICY "prospects internal read"
ON public.prospects
FOR SELECT TO authenticated
USING (public.is_internal_user());

CREATE POLICY "active services internal read"
ON public.active_services
FOR SELECT TO authenticated
USING (public.is_internal_user());

CREATE POLICY "active service events internal read"
ON public.active_service_events
FOR SELECT TO authenticated
USING (public.is_internal_user());

CREATE POLICY "radar items internal read"
ON public.radar_items
FOR SELECT TO authenticated
USING (public.is_internal_user());

CREATE POLICY "task status history internal read"
ON public.task_status_history
FOR SELECT TO authenticated
USING (public.is_internal_user());

-- ---------- FINANCIERAS ----------
-- opportunities se protege completa por expected_amount.

CREATE POLICY "opportunities financial read"
ON public.opportunities
FOR SELECT TO authenticated
USING (public.has_financial_info());

CREATE POLICY "proposals financial read"
ON public.proposals
FOR SELECT TO authenticated
USING (public.has_financial_info());

CREATE POLICY "proposal items financial read"
ON public.proposal_items
FOR SELECT TO authenticated
USING (public.has_financial_info());

CREATE POLICY "sales financial read"
ON public.sales
FOR SELECT TO authenticated
USING (public.has_financial_info());

CREATE POLICY "sale items financial read"
ON public.sale_items
FOR SELECT TO authenticated
USING (public.has_financial_info());

COMMIT;
