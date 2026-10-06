-- Catalogo + Prospectos + Oportunidades V2
-- PREPARACION. No ejecutar en produccion hasta ensayo y ACC-MIG.
-- Requiere 20261006_model_data_v2_expand.sql e identidad comercial V2.

begin;

-- Clave normalizada estable para evitar duplicados de texto en Catalog.
alter table public.catalog_items
  add column if not exists normalized_name text
  generated always as (lower(trim(name))) stored;

create unique index if not exists catalog_items_type_normalized_name_uq
  on public.catalog_items(item_type, normalized_name);

-- Semilla derivada UNICAMENTE de services existentes.
insert into public.catalog_items(name,item_type,active)
select min(trim(c.service)), 'service', true
from public.clients c
where nullif(trim(c.service),'') is not null
group by lower(trim(c.service))
on conflict (item_type, normalized_name) do nothing;

-- Vinculo legado Cliente -> servicio de Catalog sin borrar clients.service.
create table if not exists public.client_legacy_services (
  client_id uuid not null references public.clients(id) on delete cascade,
  catalog_item_id uuid not null references public.catalog_items(id) on delete restrict,
  source_text text not null,
  created_at timestamptz not null default now(),
  primary key(client_id,catalog_item_id)
);
alter table public.client_legacy_services enable row level security;

insert into public.client_legacy_services(client_id,catalog_item_id,source_text)
select c.id,ci.id,c.service
from public.clients c
join public.catalog_items ci
  on ci.item_type='service'
 and ci.normalized_name=lower(trim(c.service))
where nullif(trim(c.service),'') is not null
on conflict (client_id,catalog_item_id) do nothing;

-- Idempotencia Prospect -> Opportunity: una conversión explícita no puede
-- crear dos Opportunities para el mismo Prospect.
create unique index if not exists opportunities_prospect_once_uq
  on public.opportunities(prospect_id)
  where prospect_id is not null;

-- Cada oportunidad declara su servicio/producto principal cuando aplica.
alter table public.opportunities
  add column if not exists catalog_item_id uuid
  references public.catalog_items(id) on delete restrict;

-- Cierre explícito.
alter table public.opportunities
  add column if not exists outcome text
  check (outcome is null or outcome in ('won','lost'));

-- Venta rápida: marca de procedencia, sin saltar una oportunidad equivalente.
alter table public.opportunities
  add column if not exists is_quick_sale boolean not null default false;

-- Una equivalencia operativa se define por identidad comercial + item de catálogo
-- mientras la oportunidad esté abierta. Sin catalog_item_id no se deduplica por
-- inferencia: requiere decisión explícita.
create unique index if not exists opportunities_open_equivalent_uq
  on public.opportunities(commercial_entity_id,catalog_item_id)
  where closed_at is null and catalog_item_id is not null;

-- Una Sale por Opportunity ya queda protegida por sales.opportunity_id UNIQUE.
-- WON debe materializar Sale en una operación transaccional de backend.
-- LOST nunca crea Sale ni Client.
-- Quick Sale:
--   1) buscar oportunidad abierta equivalente;
--   2) si existe, usar/cerrar ESA oportunidad;
--   3) si no existe, crear oportunidad mínima is_quick_sale=true;
--   4) marcar WON y crear exactamente una Sale en la misma transacción.

commit;
