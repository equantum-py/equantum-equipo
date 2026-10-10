-- Read-only smoke check for a Supabase-compatible isolated test project.
-- Does not read application rows or change schema, data, grants, or settings.
DO $$
DECLARE
  v_version integer := current_setting('server_version_num')::integer;
  v_missing text;
  v_unprotected integer;
  v_missing_p1 text;
  v_missing_storage text;
BEGIN
  IF v_version < 170000 THEN
    RAISE EXCEPTION 'BLOCKED: PostgreSQL 17 or newer is required; version_num=%', v_version;
  END IF;

  IF to_regclass('auth.users') IS NULL
     OR to_regclass('storage.objects') IS NULL THEN
    RAISE EXCEPTION 'BLOCKED: Supabase-managed Auth and Storage schemas are required';
  END IF;

  IF to_regprocedure('public.handle_new_user()') IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM pg_trigger t
       WHERE t.tgrelid = 'auth.users'::regclass
         AND t.tgname = 'on_auth_user_created'
         AND t.tgfoid = 'public.handle_new_user()'::regprocedure
         AND t.tgenabled = 'O'
         AND NOT t.tgisinternal
     ) THEN
    RAISE EXCEPTION 'BLOCKED: auth.users lacks the enabled on_auth_user_created trigger for public.handle_new_user()';
  END IF;

  IF to_regclass('storage.buckets') IS NULL
     OR NOT EXISTS (
       SELECT 1 FROM storage.buckets
       WHERE id = 'ticket-attachments' AND public IS FALSE
     ) THEN
    RAISE EXCEPTION 'BLOCKED: private Storage bucket ticket-attachments is missing';
  END IF;

  SELECT string_agg(required_name, ', ' ORDER BY required_name)
  INTO v_missing_storage
  FROM (VALUES
    ('ticket attachments read authorized:SELECT'),
    ('ticket attachments authenticated insert:INSERT'),
    ('ticket attachments authenticated delete own:DELETE')
  ) AS required(required_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM pg_policies p
    WHERE p.schemaname = 'storage'
      AND p.tablename = 'objects'
      AND p.policyname = split_part(required_name, ':', 1)
      AND p.cmd = split_part(required_name, ':', 2)
      AND 'authenticated' = ANY(p.roles)
      AND CASE p.cmd
        WHEN 'SELECT' THEN p.qual LIKE '%ticket-attachments%'
          AND p.qual LIKE '%storage.foldername(name)%'
          AND p.qual LIKE '%auth.uid()%'
          AND p.qual LIKE '%is_internal_user()%'
        WHEN 'INSERT' THEN p.with_check LIKE '%ticket-attachments%'
          AND p.with_check LIKE '%storage.foldername(name)%'
          AND p.with_check LIKE '%auth.uid()%'
        WHEN 'DELETE' THEN p.qual LIKE '%ticket-attachments%'
          AND p.qual LIKE '%storage.foldername(name)%'
          AND p.qual LIKE '%auth.uid()%'
        ELSE FALSE
      END
  );

  IF v_missing_storage IS NOT NULL THEN
    RAISE EXCEPTION 'BLOCKED: Storage RLS policies missing: %', v_missing_storage;
  END IF;

  SELECT string_agg(required_name, ', ' ORDER BY required_name)
  INTO v_missing
  FROM (VALUES
    ('public.profiles'), ('public.user_permissions'), ('public.tasks'),
    ('public.tickets'), ('public.followups'), ('public.radar_items')
  ) AS required(required_name)
  WHERE to_regclass(required_name) IS NULL;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'BLOCKED: baseline tables missing: %', v_missing;
  END IF;

  SELECT count(*) INTO v_unprotected
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind IN ('r', 'p')
    AND c.relrowsecurity IS FALSE;

  IF v_unprotected <> 0 THEN
    RAISE EXCEPTION 'FAIL: % public tables do not have RLS enabled', v_unprotected;
  END IF;

  SELECT string_agg(required_name, ', ' ORDER BY required_name)
  INTO v_missing_p1
  FROM (VALUES
    ('public.transition_task_operational_status(uuid,text,text,text,text,timestamptz,text,text,text,boolean,text)'),
    ('public.archive_task(uuid,text)'),
    ('public.upsert_radar_item(text,uuid,uuid,text,timestamptz,text)'),
    ('public.close_radar_item(uuid)')
  ) AS required(required_name)
  WHERE to_regprocedure(required_name) IS NULL;

  IF v_missing_p1 IS NOT NULL THEN
    RAISE EXCEPTION 'BLOCKED: P1 task/Radar functions missing: %', v_missing_p1;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'public.tasks'::regclass
      AND NOT tgisinternal
      AND tgname = 'trg_guard_task_mutation_scope'
  ) THEN
    RAISE EXCEPTION 'BLOCKED: task mutation guard trigger is missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'radar_items'
      AND indexname = 'radar_items_active_source_uidx'
  ) THEN
    RAISE EXCEPTION 'BLOCKED: active Radar source uniqueness index is missing';
  END IF;
END
$$;

SELECT current_database() AS database_name,
       current_setting('server_version') AS postgres_version,
       (SELECT count(*) FROM pg_tables WHERE schemaname = 'public') AS public_table_count,
       (SELECT count(*) FROM pg_policies WHERE schemaname = 'public') AS public_policy_count,
       (SELECT count(*) FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public' AND c.relkind IN ('r','p')
           AND c.relrowsecurity IS FALSE) AS public_tables_without_rls,
       to_regprocedure('public.transition_task_operational_status(uuid,text,text,text,text,timestamptz,text,text,text,boolean,text)') IS NOT NULL AS task_transition_function_present,
       to_regprocedure('public.archive_task(uuid,text)') IS NOT NULL AS task_archive_function_present,
       to_regprocedure('public.upsert_radar_item(text,uuid,uuid,text,timestamptz,text)') IS NOT NULL AS radar_upsert_function_present,
       to_regclass('auth.users') IS NOT NULL AS managed_auth_present,
       to_regclass('storage.objects') IS NOT NULL AS managed_storage_present,
       EXISTS (
         SELECT 1 FROM pg_trigger t
         WHERE t.tgrelid = 'auth.users'::regclass
           AND t.tgname = 'on_auth_user_created'
           AND t.tgfoid = 'public.handle_new_user()'::regprocedure
           AND t.tgenabled = 'O'
           AND NOT t.tgisinternal
       ) AS auth_user_profile_trigger_present,
       EXISTS (
         SELECT 1 FROM storage.buckets
         WHERE id = 'ticket-attachments' AND public IS FALSE
       ) AS private_ticket_attachments_bucket_present;
