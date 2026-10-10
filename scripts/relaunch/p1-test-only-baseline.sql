-- P1 TEST-ONLY baseline reconstructed from authorized schema metadata.
-- Structure only: no rows, user identifiers, passwords, secrets, or storage objects.
-- Apply ONLY to the Supabase project explicitly verified as rqisyolaffwktxhjwpqq.
-- PostgreSQL 17 / Supabase-managed auth and storage schemas are prerequisites.
SET search_path = public, extensions, auth, storage;
BEGIN;

CREATE TYPE public."app_role" AS ENUM ('admin', 'collaborator');
CREATE TYPE public."followup_status" AS ENUM ('pending', 'waiting_response', 'done', 'postponed', 'closed');
CREATE TYPE public."task_priority" AS ENUM ('low', 'normal', 'medium', 'high', 'critical');
CREATE TYPE public."task_status" AS ENUM ('pending', 'in_progress', 'paused', 'blocked', 'waiting_client', 'completed', 'cancelled');

CREATE SEQUENCE public."ticket_number_seq" AS bigint INCREMENT BY 1 MINVALUE 1 START WITH 1001 CACHE 1 NO CYCLE;

CREATE TABLE public."chat_messages" (
  "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "user_id" uuid NOT NULL,
  "message" text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "channel" text DEFAULT 'general'::text NOT NULL,
  "recipient_id" uuid,
  "reply_to" bigint
);
CREATE TABLE public."client_portal_users" (
  "user_id" uuid NOT NULL,
  "client_id" uuid NOT NULL,
  "full_name" text,
  "active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public."clients" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "name" text NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "service" text,
  "owner_name" text,
  "contact_name" text,
  "email" text,
  "phone" text,
  "website" text,
  "whatsapp" text,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public."followups" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "task_id" uuid NOT NULL,
  "responsible_id" uuid,
  "status" public.followup_status DEFAULT 'pending'::followup_status NOT NULL,
  "next_action" text NOT NULL,
  "next_followup_at" timestamp with time zone,
  "cadence" text,
  "last_movement_at" timestamp with time zone DEFAULT now() NOT NULL,
  "notes" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public."improvement_suggestions" (
  "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "title" text NOT NULL,
  "description" text,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "created_by" uuid,
  "decided_by" uuid,
  "decided_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "category" text DEFAULT 'optimization'::text NOT NULL,
  "source_type" text,
  "source_id" uuid,
  "action_type" text,
  "action_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "executed_at" timestamp with time zone,
  "execution_result" text
);
CREATE TABLE public."profiles" (
  "id" uuid NOT NULL,
  "full_name" text DEFAULT ''::text NOT NULL,
  "role" public.app_role DEFAULT 'collaborator'::app_role NOT NULL,
  "area" text,
  "active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "username" text,
  "position" text,
  "specialty" text,
  "phone" text,
  "strengths" text,
  "development_areas" text,
  "force_password_change" boolean DEFAULT false NOT NULL,
  "manager_id" uuid,
  "last_access_at" timestamp with time zone,
  "is_master" boolean DEFAULT false NOT NULL
);
CREATE TABLE public."projects" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "client_id" uuid,
  "name" text NOT NULL,
  "description" text,
  "status" text DEFAULT 'active'::text NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public."task_events" (
  "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "task_id" uuid NOT NULL,
  "actor_id" uuid,
  "event_type" text NOT NULL,
  "detail" text,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public."tasks" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "title" text NOT NULL,
  "original_title" text,
  "client_id" uuid,
  "project_id" uuid,
  "area" text NOT NULL,
  "task_type" text NOT NULL,
  "assignee_id" uuid,
  "due_date" date,
  "client_waiting_days" integer DEFAULT 0 NOT NULL,
  "client_urgency" integer DEFAULT 1 NOT NULL,
  "estimated_minutes" integer,
  "actual_minutes" integer DEFAULT 0 NOT NULL,
  "visibility" text DEFAULT 'team'::text NOT NULL,
  "description" text,
  "triage_impact" text,
  "triage_score" integer DEFAULT 25 NOT NULL,
  "priority" public.task_priority DEFAULT 'normal'::task_priority NOT NULL,
  "triage_reasons" text[] DEFAULT '{}'::text[] NOT NULL,
  "status" public.task_status DEFAULT 'pending'::task_status NOT NULL,
  "affects_sales" boolean DEFAULT false NOT NULL,
  "blocks_others" boolean DEFAULT false NOT NULL,
  "strategic" boolean DEFAULT false NOT NULL,
  "last_activity_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "completed_at" timestamp with time zone,
  "ticket_id" uuid
);
CREATE TABLE public."ticket_events" (
  "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "ticket_id" uuid NOT NULL,
  "actor_id" uuid,
  "event_type" text NOT NULL,
  "details" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public."ticket_messages" (
  "id" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  "ticket_id" uuid NOT NULL,
  "author_id" uuid,
  "message" text NOT NULL,
  "is_internal" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "attachments" jsonb DEFAULT '[]'::jsonb NOT NULL
);
CREATE TABLE public."tickets" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "ticket_number" text DEFAULT ('EQ-'::text || lpad((nextval('ticket_number_seq'::regclass))::text, 5, '0'::text)) NOT NULL,
  "client_id" uuid,
  "subject" text NOT NULL,
  "request_type" text DEFAULT 'Soporte'::text NOT NULL,
  "description" text NOT NULL,
  "priority" text DEFAULT 'normal'::text NOT NULL,
  "status" text DEFAULT 'new'::text NOT NULL,
  "opened_by" uuid,
  "assigned_to" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "resolved_at" timestamp with time zone,
  "closed_at" timestamp with time zone,
  "attachments" jsonb DEFAULT '[]'::jsonb NOT NULL
);
CREATE TABLE public."user_permissions" (
  "user_id" uuid NOT NULL,
  "view_own_tasks" boolean DEFAULT true NOT NULL,
  "view_area_tasks" boolean DEFAULT false NOT NULL,
  "view_all_tasks" boolean DEFAULT false NOT NULL,
  "create_tasks" boolean DEFAULT true NOT NULL,
  "reassign_tasks" boolean DEFAULT false NOT NULL,
  "delete_tasks" boolean DEFAULT false NOT NULL,
  "bi_personal" boolean DEFAULT true NOT NULL,
  "bi_area" boolean DEFAULT false NOT NULL,
  "bi_global" boolean DEFAULT false NOT NULL,
  "financial_info" boolean DEFAULT false NOT NULL,
  "manage_users" boolean DEFAULT false NOT NULL
);

ALTER TABLE public."chat_messages" ADD CONSTRAINT "chat_messages_pkey" PRIMARY KEY (id);
ALTER TABLE public."client_portal_users" ADD CONSTRAINT "client_portal_users_pkey" PRIMARY KEY (user_id);
ALTER TABLE public."clients" ADD CONSTRAINT "clients_pkey" PRIMARY KEY (id);
ALTER TABLE public."followups" ADD CONSTRAINT "followups_pkey" PRIMARY KEY (id);
ALTER TABLE public."improvement_suggestions" ADD CONSTRAINT "improvement_suggestions_pkey" PRIMARY KEY (id);
ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_pkey" PRIMARY KEY (id);
ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_username_key" UNIQUE (username);
ALTER TABLE public."projects" ADD CONSTRAINT "projects_pkey" PRIMARY KEY (id);
ALTER TABLE public."task_events" ADD CONSTRAINT "task_events_pkey" PRIMARY KEY (id);
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_pkey" PRIMARY KEY (id);
ALTER TABLE public."ticket_events" ADD CONSTRAINT "ticket_events_pkey" PRIMARY KEY (id);
ALTER TABLE public."ticket_messages" ADD CONSTRAINT "ticket_messages_pkey" PRIMARY KEY (id);
ALTER TABLE public."tickets" ADD CONSTRAINT "tickets_pkey" PRIMARY KEY (id);
ALTER TABLE public."tickets" ADD CONSTRAINT "tickets_ticket_number_key" UNIQUE (ticket_number);
ALTER TABLE public."user_permissions" ADD CONSTRAINT "user_permissions_pkey" PRIMARY KEY (user_id);
ALTER TABLE public."chat_messages" ADD CONSTRAINT "chat_messages_message_check" CHECK (char_length(message) >= 1 AND char_length(message) <= 2000);
ALTER TABLE public."chat_messages" ADD CONSTRAINT "chat_messages_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."chat_messages" ADD CONSTRAINT "chat_messages_reply_to_fkey" FOREIGN KEY (reply_to) REFERENCES chat_messages(id) ON DELETE SET NULL;
ALTER TABLE public."chat_messages" ADD CONSTRAINT "chat_messages_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE public."client_portal_users" ADD CONSTRAINT "client_portal_users_client_id_fkey" FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
ALTER TABLE public."client_portal_users" ADD CONSTRAINT "client_portal_users_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."clients" ADD CONSTRAINT "clients_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."followups" ADD CONSTRAINT "followups_responsible_id_fkey" FOREIGN KEY (responsible_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."followups" ADD CONSTRAINT "followups_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;
ALTER TABLE public."improvement_suggestions" ADD CONSTRAINT "improvement_suggestions_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."improvement_suggestions" ADD CONSTRAINT "improvement_suggestions_decided_by_fkey" FOREIGN KEY (decided_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."improvement_suggestions" ADD CONSTRAINT "improvement_suggestions_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text]));
ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_manager_id_fkey" FOREIGN KEY (manager_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."projects" ADD CONSTRAINT "projects_client_id_fkey" FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
ALTER TABLE public."projects" ADD CONSTRAINT "projects_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."task_events" ADD CONSTRAINT "task_events_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."task_events" ADD CONSTRAINT "task_events_task_id_fkey" FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_actual_minutes_check" CHECK (actual_minutes >= 0);
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_assignee_id_fkey" FOREIGN KEY (assignee_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_client_id_fkey" FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_client_urgency_check" CHECK (client_urgency >= 1 AND client_urgency <= 5);
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_client_waiting_days_check" CHECK (client_waiting_days >= 0);
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_created_by_fkey" FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_estimated_minutes_check" CHECK (estimated_minutes IS NULL OR estimated_minutes > 0);
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_project_id_fkey" FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_ticket_id_fkey" FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE SET NULL;
ALTER TABLE public."tasks" ADD CONSTRAINT "tasks_triage_score_check" CHECK (triage_score >= 0 AND triage_score <= 100);
ALTER TABLE public."ticket_events" ADD CONSTRAINT "ticket_events_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."ticket_events" ADD CONSTRAINT "ticket_events_ticket_id_fkey" FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE;
ALTER TABLE public."ticket_messages" ADD CONSTRAINT "ticket_messages_author_id_fkey" FOREIGN KEY (author_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."ticket_messages" ADD CONSTRAINT "ticket_messages_ticket_id_fkey" FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE;
ALTER TABLE public."tickets" ADD CONSTRAINT "tickets_assigned_to_fkey" FOREIGN KEY (assigned_to) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."tickets" ADD CONSTRAINT "tickets_client_id_fkey" FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
ALTER TABLE public."tickets" ADD CONSTRAINT "tickets_opened_by_fkey" FOREIGN KEY (opened_by) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public."tickets" ADD CONSTRAINT "tickets_priority_check" CHECK (priority = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text, 'urgent'::text]));
ALTER TABLE public."tickets" ADD CONSTRAINT "tickets_status_check" CHECK (status = ANY (ARRAY['new'::text, 'review'::text, 'in_progress'::text, 'waiting_client'::text, 'resolved'::text, 'closed'::text]));
ALTER TABLE public."user_permissions" ADD CONSTRAINT "user_permissions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

CREATE OR REPLACE FUNCTION public.detect_operational_improvements()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare n integer:=0;
begin
 insert into improvement_suggestions(title,description,status,category,source_type,source_id,action_type,action_payload)
 select 'Crear seguimiento faltante',
        'La tarea “'||left(t.title,80)||'” está activa y no tiene próximo seguimiento registrado.',
        'pending','attention','task',t.id,'create_followup',
        jsonb_build_object('task_id',t.id,'responsible_id',t.assignee_id,'next_action','Revisar avance de '||t.title,'days',2)
 from tasks t
 where t.status not in ('completed','cancelled')
   and not exists(select 1 from followups f where f.task_id=t.id and f.status='pending')
   and not exists(select 1 from improvement_suggestions s where s.status='pending' and s.action_type='create_followup' and s.source_id=t.id)
   and (t.client_waiting_days>0 or t.due_date is not null or t.last_activity_at < now()-interval '3 days');
 get diagnostics n=row_count;

 insert into improvement_suggestions(title,description,status,category,source_type,source_id,action_type,action_payload)
 select 'Recuperar silencio operativo',
        'La tarea “'||left(t.title,80)||'” no registra movimiento reciente. Conviene revisar su estado.',
        'pending','attention','task',t.id,'create_followup',
        jsonb_build_object('task_id',t.id,'responsible_id',t.assignee_id,'next_action','Retomar tarea sin movimiento: '||t.title,'days',1)
 from tasks t
 where t.status not in ('completed','cancelled')
   and coalesce(t.last_activity_at,t.created_at)<now()-interval '5 days'
   and not exists(select 1 from followups f where f.task_id=t.id and f.status='pending')
   and not exists(select 1 from improvement_suggestions s where s.status='pending' and s.action_type='create_followup' and s.source_id=t.id);
 return n;
end $function$;
CREATE OR REPLACE FUNCTION public.guard_master_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin if old.is_master then raise exception 'Cuenta maestra protegida'; end if; return old; end $function$;
CREATE OR REPLACE FUNCTION public.guard_master_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin if old.is_master and (not new.is_master or new.role <> 'admin'::public.app_role or not new.active) then raise exception 'Cuenta maestra protegida'; end if; return new; end $function$;
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 insert into public.profiles(id,full_name,active,force_password_change)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),true,coalesce((new.raw_user_meta_data->>'force_password_change')::boolean,false))
 on conflict(id) do nothing;
 insert into public.user_permissions(user_id) values(new.id) on conflict(user_id) do nothing;
 return new;
end $function$;
CREATE OR REPLACE FUNCTION public.is_active_user()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select exists(select 1 from public.profiles where id=auth.uid() and active=true)
$function$;
CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin' and active); $function$;
CREATE OR REPLACE FUNCTION public.is_client_portal_user()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists(select 1 from public.client_portal_users u where u.user_id=auth.uid() and u.active);
$function$;
CREATE OR REPLACE FUNCTION public.portal_client_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select client_id from public.client_portal_users where user_id=auth.uid() and active limit 1;
$function$;

CREATE TRIGGER guard_master_delete_trg BEFORE DELETE ON profiles FOR EACH ROW EXECUTE FUNCTION guard_master_delete();
CREATE TRIGGER guard_master_profile_trg BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION guard_master_profile();

CREATE INDEX chat_messages_channel_created_idx ON public.chat_messages USING btree (channel, created_at);
CREATE INDEX chat_messages_created_idx ON public.chat_messages USING btree (created_at);
CREATE INDEX chat_messages_recipient_idx ON public.chat_messages USING btree (recipient_id, created_at);
CREATE INDEX client_portal_users_client_idx ON public.client_portal_users USING btree (client_id);
CREATE INDEX clients_status_idx ON public.clients USING btree (status);
CREATE INDEX followups_next_idx ON public.followups USING btree (next_followup_at);
CREATE INDEX improvement_status_idx ON public.improvement_suggestions USING btree (status);
CREATE UNIQUE INDEX improvement_suggestions_pending_action_source_uidx ON public.improvement_suggestions USING btree (action_type, source_id) WHERE ((status = 'pending'::text) AND (source_id IS NOT NULL));
CREATE INDEX improvement_suggestions_status_category_idx ON public.improvement_suggestions USING btree (status, category);
CREATE INDEX task_events_task_idx ON public.task_events USING btree (task_id, created_at DESC);
CREATE INDEX idx_tasks_client_id ON public.tasks USING btree (client_id);
CREATE INDEX idx_tasks_ticket_id ON public.tasks USING btree (ticket_id);
CREATE INDEX tasks_assignee_idx ON public.tasks USING btree (assignee_id);
CREATE INDEX tasks_due_idx ON public.tasks USING btree (due_date);
CREATE INDEX tasks_priority_idx ON public.tasks USING btree (priority);
CREATE INDEX tasks_status_idx ON public.tasks USING btree (status);
CREATE INDEX ticket_events_ticket_idx ON public.ticket_events USING btree (ticket_id, created_at);
CREATE INDEX ticket_messages_ticket_idx ON public.ticket_messages USING btree (ticket_id, created_at);
CREATE INDEX tickets_assigned_idx ON public.tickets USING btree (assigned_to);
CREATE INDEX tickets_client_idx ON public.tickets USING btree (client_id);
CREATE INDEX tickets_status_idx ON public.tickets USING btree (status);

ALTER TABLE public."chat_messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."client_portal_users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."clients" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."followups" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."improvement_suggestions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."projects" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."task_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."tasks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."ticket_events" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."ticket_messages" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."tickets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_permissions" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "active users read chat" ON public."chat_messages" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_active_user() AND ((channel <> 'direct'::text) OR (user_id = auth.uid()) OR (recipient_id = auth.uid()))));
CREATE POLICY "active users write own chat" ON public."chat_messages" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((is_active_user() AND (user_id = auth.uid()) AND ((channel <> 'direct'::text) OR (recipient_id IS NOT NULL))));
CREATE POLICY "portal user reads own mapping" ON public."client_portal_users" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));
CREATE POLICY "clients admin write" ON public."clients" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "clients authenticated read" ON public."clients" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "portal user reads own client" ON public."clients" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((id = portal_client_id()));
CREATE POLICY "followups scoped read" ON public."followups" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_admin() OR (responsible_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM tasks t
  WHERE ((t.id = followups.task_id) AND ((t.assignee_id = auth.uid()) OR (t.created_by = auth.uid())))))));
CREATE POLICY "followups scoped write" ON public."followups" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_admin() OR (responsible_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM tasks t
  WHERE ((t.id = followups.task_id) AND ((t.assignee_id = auth.uid()) OR (t.created_by = auth.uid()))))))) WITH CHECK ((is_admin() OR (responsible_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM tasks t
  WHERE ((t.id = followups.task_id) AND ((t.assignee_id = auth.uid()) OR (t.created_by = auth.uid())))))));
CREATE POLICY "admin decide improvements" ON public."improvement_suggestions" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "authenticated create improvements" ON public."improvement_suggestions" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((created_by = auth.uid()));
CREATE POLICY "authenticated read improvements" ON public."improvement_suggestions" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "profiles admin manage" ON public."profiles" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "profiles self or admin read" ON public."profiles" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((id = auth.uid()) OR is_admin()));
CREATE POLICY "projects admin write" ON public."projects" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "projects authenticated read" ON public."projects" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
CREATE POLICY "events authenticated insert" ON public."task_events" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((actor_id = auth.uid()));
CREATE POLICY "events scoped read" ON public."task_events" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_admin() OR (actor_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM tasks t
  WHERE ((t.id = task_events.task_id) AND ((t.assignee_id = auth.uid()) OR (t.created_by = auth.uid())))))));
CREATE POLICY "tasks admin delete" ON public."tasks" AS PERMISSIVE FOR DELETE TO "authenticated" USING (is_admin());
CREATE POLICY "tasks create" ON public."tasks" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (((created_by = auth.uid()) AND (is_admin() OR (EXISTS ( SELECT 1
   FROM user_permissions p
  WHERE ((p.user_id = auth.uid()) AND p.create_tasks))))));
CREATE POLICY "tasks read" ON public."tasks" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_active_user() AND (is_admin() OR (assignee_id = auth.uid()) OR (created_by = auth.uid()) OR (EXISTS ( SELECT 1
   FROM user_permissions p
  WHERE ((p.user_id = auth.uid()) AND p.view_all_tasks))))));
CREATE POLICY "tasks scoped update" ON public."tasks" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((is_admin() OR (assignee_id = auth.uid()) OR (created_by = auth.uid()))) WITH CHECK ((is_admin() OR (assignee_id = auth.uid()) OR (created_by = auth.uid())));
CREATE POLICY "active users create ticket events" ON public."ticket_events" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((is_active_user() AND (actor_id = auth.uid())));
CREATE POLICY "active users read ticket events" ON public."ticket_events" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_active_user());
CREATE POLICY "active users create ticket messages" ON public."ticket_messages" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((is_active_user() AND (author_id = auth.uid())));
CREATE POLICY "active users read ticket messages" ON public."ticket_messages" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_active_user());
CREATE POLICY "authenticated create ticket messages" ON public."ticket_messages" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (((author_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND p.active)))));
CREATE POLICY "authenticated read ticket messages" ON public."ticket_messages" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND p.active))));
CREATE POLICY "portal user reads own ticket messages" ON public."ticket_messages" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM tickets t
  WHERE ((t.id = ticket_messages.ticket_id) AND (t.client_id = portal_client_id())))) AND (is_internal = false)));
CREATE POLICY "portal user replies own tickets" ON public."ticket_messages" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM tickets t
  WHERE ((t.id = ticket_messages.ticket_id) AND (t.client_id = portal_client_id())))) AND (is_internal = false) AND (author_id IS NULL)));
CREATE POLICY "active users create tickets" ON public."tickets" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((is_active_user() AND (opened_by = auth.uid())));
CREATE POLICY "active users read tickets" ON public."tickets" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_active_user());
CREATE POLICY "active users update tickets" ON public."tickets" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (is_active_user()) WITH CHECK (is_active_user());
CREATE POLICY "authenticated create tickets" ON public."tickets" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND p.active))));
CREATE POLICY "authenticated read tickets" ON public."tickets" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND p.active))));
CREATE POLICY "authenticated update tickets" ON public."tickets" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND p.active)))) WITH CHECK ((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND p.active))));
CREATE POLICY "portal user creates own tickets" ON public."tickets" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (((client_id = portal_client_id()) AND (opened_by IS NULL)));
CREATE POLICY "portal user reads own tickets" ON public."tickets" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((client_id = portal_client_id()));
CREATE POLICY "permissions admin manage" ON public."user_permissions" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "permissions self or admin read" ON public."user_permissions" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((user_id = auth.uid()) OR is_admin()));

REVOKE ALL ON FUNCTION public."detect_operational_improvements"() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public."guard_master_delete"() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public."guard_master_profile"() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public."handle_new_user"() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public."is_active_user"() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public."is_admin"() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public."is_client_portal_user"() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public."portal_client_id"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public."is_active_user"() TO authenticated;
GRANT EXECUTE ON FUNCTION public."is_admin"() TO authenticated;
GRANT EXECUTE ON FUNCTION public."is_client_portal_user"() TO authenticated;
GRANT EXECUTE ON FUNCTION public."portal_client_id"() TO authenticated;
COMMIT;

