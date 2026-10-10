-- Test-project-only ACL bootstrap. Do not include this file in production
-- deployment or the product migration runner. Run only after the explicit
-- P1_TEST_PROJECT_REF preflight confirms rqisyolaffwktxhjwpqq.
-- RLS policies are checked before table privileges are granted.
DO $lab_acl$
DECLARE
  v_table text;
  v_cmd text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY['public.followups','public.radar_items','public.task_events'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c
      WHERE c.oid = to_regclass(v_table) AND c.relrowsecurity
    ) THEN
      RAISE EXCEPTION 'Refusing test ACL setup: RLS is not enabled on %', v_table;
    END IF;
  END LOOP;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='followups' AND cmd='SELECT' AND 'authenticated'=ANY(roles))
     OR NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='followups' AND cmd='ALL' AND 'authenticated'=ANY(roles)) THEN
    RAISE EXCEPTION 'Refusing test ACL setup: followups lacks its scoped SELECT/ALL policies';
  END IF;

  FOREACH v_cmd IN ARRAY ARRAY['SELECT','INSERT','UPDATE'] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname='public' AND tablename='radar_items'
        AND cmd=v_cmd AND 'authenticated'=ANY(roles)
    ) THEN
      RAISE EXCEPTION 'Refusing test ACL setup: radar_items % policy is missing', v_cmd;
    END IF;
  END LOOP;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='task_events' AND cmd='SELECT' AND 'authenticated'=ANY(roles))
     OR NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='task_events' AND cmd='INSERT' AND 'authenticated'=ANY(roles)) THEN
    RAISE EXCEPTION 'Refusing test ACL setup: task_events lacks scoped SELECT/INSERT policies';
  END IF;
END
$lab_acl$;

-- authenticated needs only the operations covered by its RLS policies.
GRANT SELECT, INSERT, UPDATE ON TABLE public.followups TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.radar_items TO authenticated;
GRANT SELECT, INSERT ON TABLE public.task_events TO authenticated;

-- Admin API key is used only by the fixture script and never by the browser.
-- It can verify Auth side effects, assign only the viewer/inactive test flags,
-- and create/delete synthetic Portal mappings and their two synthetic clients.
GRANT SELECT ON TABLE public.profiles, public.user_permissions TO service_role;
GRANT SELECT ON TABLE public.clients, public.client_portal_users TO service_role;
GRANT INSERT, DELETE ON TABLE public.clients, public.client_portal_users TO service_role;
GRANT UPDATE (active) ON TABLE public.profiles TO service_role;
GRANT UPDATE (view_all_tasks, view_own_tasks) ON TABLE public.user_permissions TO service_role;

-- RLS does not filter TRUNCATE; remove the unnecessary privilege from public
-- client roles in the test project. service_role keeps its existing ACL.
REVOKE TRUNCATE ON TABLE public.client_legacy_services FROM anon, authenticated;
