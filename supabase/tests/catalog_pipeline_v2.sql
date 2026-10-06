-- Tests Catalog + Prospectos + Oportunidades V2

-- Catálogo: cero duplicados normalizados.
select item_type,normalized_name,count(*) qty
from public.catalog_items
group by item_type,normalized_name having count(*)>1;

-- Todos los services legacy deben mapear a un item.
select c.id,c.service
from public.clients c
left join public.client_legacy_services cls on cls.client_id=c.id
where nullif(trim(c.service),'') is not null and cls.client_id is null;

-- Prospect no puede originar dos Opportunities.
select prospect_id,count(*) qty from public.opportunities
where prospect_id is not null group by prospect_id having count(*)>1;

-- No debe haber dos oportunidades abiertas equivalentes.
select commercial_entity_id,catalog_item_id,count(*) qty
from public.opportunities
where closed_at is null and catalog_item_id is not null
group by commercial_entity_id,catalog_item_id having count(*)>1;

-- WON: exactamente una Sale.
select o.id,count(s.id) sale_count
from public.opportunities o left join public.sales s on s.opportunity_id=o.id
where o.outcome='won'
group by o.id having count(s.id)<>1;

-- LOST: cero Sales.
select o.id,count(s.id) sale_count
from public.opportunities o join public.sales s on s.opportunity_id=o.id
where o.outcome='lost'
group by o.id;
