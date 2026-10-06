-- Modelo de Datos V2 - Expansion segura
-- SOLO PREPARACION. No aplicar a produccion sin ensayo y ACC-MIG.
-- No borra tablas ni datos actuales.

begin;

create table if not exists public.commercial_entities (
 id uuid primary key default gen_random_uuid(), entity_type text not null check (entity_type in ('company','person')), display_name text not null, legal_name text, tax_id text, email text, phone text, website text, status text not null default 'active', legacy_client_id uuid unique references public.clients(id) on delete set null, created_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), archived_at timestamptz
);
create unique index if not exists commercial_entities_tax_id_unique on public.commercial_entities(tax_id) where tax_id is not null;

create table if not exists public.catalog_items (id uuid primary key default gen_random_uuid(), code text unique, name text not null, item_type text not null check (item_type in ('product','service')), description text, active boolean not null default true, created_at timestamptz not null default now(), archived_at timestamptz);
create table if not exists public.prospects (id uuid primary key default gen_random_uuid(), commercial_entity_id uuid not null references public.commercial_entities(id) on delete restrict, status text not null default 'new', owner_id uuid references public.profiles(id) on delete set null, source text, created_at timestamptz not null default now(), converted_at timestamptz, archived_at timestamptz);
create table if not exists public.opportunities (id uuid primary key default gen_random_uuid(), commercial_entity_id uuid not null references public.commercial_entities(id) on delete restrict, prospect_id uuid references public.prospects(id) on delete set null, title text not null, stage text not null default 'open', owner_id uuid references public.profiles(id) on delete set null, currency text, expected_amount numeric(18,2), loss_reason text, created_at timestamptz not null default now(), closed_at timestamptz, archived_at timestamptz);
create table if not exists public.proposals (id uuid primary key default gen_random_uuid(), opportunity_id uuid not null references public.opportunities(id) on delete restrict, version integer not null check(version>0), status text not null default 'draft', currency text, total_amount numeric(18,2), valid_until timestamptz, created_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now(), unique(opportunity_id,version));
create table if not exists public.proposal_items (id uuid primary key default gen_random_uuid(), proposal_id uuid not null references public.proposals(id) on delete cascade, catalog_item_id uuid references public.catalog_items(id) on delete restrict, description text not null, quantity numeric(18,4) not null default 1, unit_price numeric(18,2) not null default 0, tax_amount numeric(18,2) not null default 0);
create table if not exists public.sales (id uuid primary key default gen_random_uuid(), opportunity_id uuid not null unique references public.opportunities(id) on delete restrict, commercial_entity_id uuid not null references public.commercial_entities(id) on delete restrict, proposal_id uuid references public.proposals(id) on delete set null, currency text not null, gross_amount numeric(18,2) not null, tax_amount numeric(18,2) not null default 0, net_amount numeric(18,2) not null, closed_at timestamptz not null, created_by uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now());
create table if not exists public.active_services (id uuid primary key default gen_random_uuid(), commercial_entity_id uuid not null references public.commercial_entities(id) on delete restrict, catalog_item_id uuid references public.catalog_items(id) on delete restrict, sale_id uuid references public.sales(id) on delete set null, name text not null, status text not null default 'active', started_at timestamptz, ended_at timestamptz, created_at timestamptz not null default now());

alter table public.clients add column if not exists commercial_entity_id uuid references public.commercial_entities(id) on delete restrict;
alter table public.projects add column if not exists sale_id uuid references public.sales(id) on delete set null;
alter table public.tasks add column if not exists active_service_id uuid references public.active_services(id) on delete set null;

create table if not exists public.radar_items (id uuid primary key default gen_random_uuid(), source_type text not null, source_id uuid not null, responsible_id uuid references public.profiles(id) on delete set null, state text not null default 'active', next_action text, next_review_at timestamptz, condition_text text, last_movement_at timestamptz, legacy_followup_id uuid unique references public.followups(id) on delete set null, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), closed_at timestamptz);
create index if not exists radar_items_review_idx on public.radar_items(state,next_review_at);
create index if not exists radar_items_source_idx on public.radar_items(source_type,source_id);

create table if not exists public.task_status_history (id bigint generated by default as identity primary key, task_id uuid not null references public.tasks(id) on delete cascade, from_status text, to_status text not null, actor_id uuid references public.profiles(id) on delete set null, occurred_at timestamptz not null default now(), reason text, metadata jsonb not null default '{}'::jsonb);
create index if not exists task_status_history_task_idx on public.task_status_history(task_id,occurred_at desc);

alter table public.commercial_entities enable row level security;
alter table public.catalog_items enable row level security;
alter table public.prospects enable row level security;
alter table public.opportunities enable row level security;
alter table public.proposals enable row level security;
alter table public.proposal_items enable row level security;
alter table public.sales enable row level security;
alter table public.active_services enable row level security;
alter table public.radar_items enable row level security;
alter table public.task_status_history enable row level security;
commit;

-- Datos: reconciliar clients antes de commercial_entities; no inventar historia.
-- followups -> radar_items conservando legacy_followup_id.
-- Estados tasks se mapean en migracion separada.
-- Prospect->Opportunity idempotente. WON crea exactamente una Sale. LOST no crea Sale/Client.
-- Sale != Invoice != Payment.
