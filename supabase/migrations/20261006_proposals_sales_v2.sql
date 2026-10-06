-- Propuestas + Ventas V2
-- PREPARACION. No ejecutar en produccion.
-- Requiere model_data_v2_expand + catalog_pipeline_v2.
-- Venta, Factura y Pago son conceptos distintos. Este bloque NO crea Invoice/Payment.

begin;

-- PROPUESTAS VERSIONADAS
alter table public.proposals add column if not exists supersedes_proposal_id uuid references public.proposals(id) on delete restrict;
alter table public.proposals add column if not exists accepted_at timestamptz;
alter table public.proposals add column if not exists notes text;

-- Totales explícitos. La moneda NO determina el tratamiento tributario.
alter table public.proposals add column if not exists subtotal_amount numeric(18,2);
alter table public.proposals add column if not exists discount_amount numeric(18,2) not null default 0;
alter table public.proposals add column if not exists tax_amount numeric(18,2) not null default 0;

alter table public.proposal_items add column if not exists discount_amount numeric(18,2) not null default 0;
alter table public.proposal_items add column if not exists tax_treatment text;
alter table public.proposal_items add column if not exists line_subtotal numeric(18,2);
alter table public.proposal_items add column if not exists line_total numeric(18,2);

-- SNAPSHOT DE VENTA
-- Sale conserva identidad, moneda, propuesta aceptada y totales al cierre.
alter table public.sales add column if not exists proposal_version integer;
alter table public.sales add column if not exists entity_display_name text;
alter table public.sales add column if not exists entity_legal_name text;
alter table public.sales add column if not exists entity_tax_id text;
alter table public.sales add column if not exists subtotal_amount numeric(18,2);
alter table public.sales add column if not exists discount_amount numeric(18,2) not null default 0;
alter table public.sales add column if not exists commission_base_amount numeric(18,2);
alter table public.sales add column if not exists snapshot_at timestamptz;

-- Líneas propias: una venta no depende de que Catalog/Proposal cambien después.
create table if not exists public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete restrict,
  source_proposal_item_id uuid references public.proposal_items(id) on delete set null,
  catalog_item_id uuid references public.catalog_items(id) on delete restrict,
  item_name text not null,
  description text not null,
  quantity numeric(18,4) not null check(quantity > 0),
  unit_price numeric(18,2) not null,
  discount_amount numeric(18,2) not null default 0,
  subtotal_amount numeric(18,2) not null,
  tax_treatment text,
  tax_amount numeric(18,2) not null default 0,
  total_amount numeric(18,2) not null,
  created_at timestamptz not null default now()
);
create unique index if not exists sale_items_source_proposal_item_uq
  on public.sale_items(sale_id,source_proposal_item_id)
  where source_proposal_item_id is not null;
alter table public.sale_items enable row level security;

-- Consistencia de cierre.
alter table public.sales drop constraint if exists sales_amounts_v2_check;
alter table public.sales add constraint sales_amounts_v2_check check (
  tax_amount >= 0
  and discount_amount >= 0
  and (commission_base_amount is null or commission_base_amount >= 0)
);

-- Comisión: la base guardada excluye IVA/impuesto.
-- La política/porcentaje histórico definitivo queda fuera hasta su especificación.
-- No se calcula impuesto por moneda.

commit;

-- OPERACION WON -> SALE (contrato transaccional a implementar en backend/RPC):
-- 1. lock Opportunity FOR UPDATE.
-- 2. exigir que no esté LOST/cerrada incompatible.
-- 3. resolver propuesta aceptada/version concreta.
-- 4. validar moneda/totales/tratamiento tributario explícitos.
-- 5. INSERT Sale; opportunity_id UNIQUE impide segunda Sale.
-- 6. copiar Proposal Items a sale_items como snapshot.
-- 7. commission_base_amount = base sin tax_amount; no inferir porcentaje.
-- 8. marcar Opportunity outcome='won', closed_at.
-- 9. commit único. Cualquier fallo => rollback completo.
--
-- LOST:
-- marcar outcome='lost' + closed_at + motivo; NO insertar Sale.
--
-- No crear Invoice ni Payment aquí.
