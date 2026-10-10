-- RLS does not restrict TRUNCATE. Public client roles have no P1 need to
-- truncate this legacy bridge table. This migration is reviewable; it has only
-- been applied to the isolated eQuantum P1 Pruebas project, not production.
REVOKE TRUNCATE ON TABLE public.client_legacy_services FROM anon, authenticated;
