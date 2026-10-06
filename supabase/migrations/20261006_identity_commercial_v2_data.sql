-- Identidad Comercial V2 - migracion idempotente desde clients
-- PREPARACION: no aplicar en produccion hasta ejecutar expand V2 + reconciliacion + pruebas.
-- No borra ni fusiona clientes. No infiere relaciones desde textos de Tasks.

begin;

-- Precondicion: commercial_entities y clients.commercial_entity_id
-- existen por 20261006_model_data_v2_expand.sql.

-- 1) Crear exactamente una identidad por client legado.
-- legacy_client_id UNIQUE hace la operacion idempotente.
insert into public.commercial_entities (
  entity_type, display_name, email, phone, website, status,
  legacy_client_id, created_by, created_at, updated_at
)
select
  'company',
  c.name,
  c.email,
  coalesce(c.phone, c.whatsapp),
  c.website,
  c.status,
  c.id,
  c.created_by,
  c.created_at,
  c.updated_at
from public.clients c
where not exists (
  select 1 from public.commercial_entities ce
  where ce.legacy_client_id = c.id
)
on conflict (legacy_client_id) do nothing;

-- 2) Vincular el client original con su identidad canónica.
-- Solo rellena NULL: no pisa una relación ya existente.
update public.clients c
set commercial_entity_id = ce.id
from public.commercial_entities ce
where ce.legacy_client_id = c.id
  and c.commercial_entity_id is null;

-- 3) Bloqueos: si algo no reconcilia, abortar la transacción.
do $$
declare
  missing_count integer;
  duplicate_count integer;
  mismatch_count integer;
begin
  select count(*) into missing_count
  from public.clients c
  left join public.commercial_entities ce on ce.legacy_client_id = c.id
  where ce.id is null;

  select count(*) into duplicate_count
  from (
    select legacy_client_id
    from public.commercial_entities
    where legacy_client_id is not null
    group by legacy_client_id
    having count(*) <> 1
  ) x;

  select count(*) into mismatch_count
  from public.clients c
  join public.commercial_entities ce on ce.legacy_client_id = c.id
  where c.commercial_entity_id is distinct from ce.id;

  if missing_count <> 0 or duplicate_count <> 0 or mismatch_count <> 0 then
    raise exception 'Identity reconciliation failed: missing=%, duplicate=%, mismatch=%',
      missing_count, duplicate_count, mismatch_count;
  end if;
end $$;

commit;

-- IMPORTANTE:
-- owner_name/contact_name/service NO se convierten aquí a personas/catálogo.
-- contact_name contiene datos que pueden no ser nombres; conservar legado sin reinterpretar.
-- Tasks sin client_id, incluida "Contenidos Portal Verde" y "Propuesta Ecotritura",
-- permanecen sin relación hasta confirmación humana.
