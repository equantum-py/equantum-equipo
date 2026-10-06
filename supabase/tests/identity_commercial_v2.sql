-- Pruebas de Identidad Comercial V2
-- Ejecutar después de la migración en entorno de ensayo.

-- Debe devolver 0.
select count(*) as clients_without_identity
from public.clients c
left join public.commercial_entities ce on ce.id=c.commercial_entity_id
where ce.id is null;

-- Debe devolver 0.
select count(*) as duplicate_legacy_identity
from (
  select legacy_client_id
  from public.commercial_entities
  where legacy_client_id is not null
  group by legacy_client_id
  having count(*) > 1
) x;

-- Debe ser igual a count(*) de clients en el corte.
select count(*) as legacy_clients from public.clients;
select count(*) as identities_from_clients
from public.commercial_entities where legacy_client_id is not null;

-- Debe devolver 0: el enlace debe ser bidireccionalmente coherente.
select count(*) as mismatched_links
from public.clients c
join public.commercial_entities ce on ce.legacy_client_id=c.id
where c.commercial_entity_id is distinct from ce.id;

-- Los casos ambiguos siguen sin auto-link si así estaban antes.
select id,title,client_id
from public.tasks
where title in ('Contenidos Portal Verde','Propuesta Ecotritura');
