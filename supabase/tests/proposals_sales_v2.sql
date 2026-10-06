-- Tests Propuestas + Ventas V2

-- Versiones no duplicadas.
select opportunity_id,version,count(*) qty
from public.proposals group by opportunity_id,version having count(*)>1;

-- WON debe tener exactamente una Sale.
select o.id,count(s.id) sale_count
from public.opportunities o left join public.sales s on s.opportunity_id=o.id
where o.outcome='won'
group by o.id having count(s.id)<>1;

-- LOST debe tener cero Sales.
select o.id,count(s.id) sale_count
from public.opportunities o join public.sales s on s.opportunity_id=o.id
where o.outcome='lost'
group by o.id;

-- Sale desde Proposal debe conservar versión.
select s.id
from public.sales s join public.proposals p on p.id=s.proposal_id
where s.proposal_version is distinct from p.version;

-- Cada línea de Proposal vendida debe aparecer una sola vez en el snapshot.
select si.sale_id,si.source_proposal_item_id,count(*) qty
from public.sale_items si
where si.source_proposal_item_id is not null
group by si.sale_id,si.source_proposal_item_id having count(*)>1;

-- Comisión nunca puede usar IVA como parte de la base.
-- Esta prueba detecta una base mayor al subtotal neto disponible.
select id from public.sales
where commission_base_amount is not null
  and subtotal_amount is not null
  and commission_base_amount > subtotal_amount;

-- No existe requisito de Invoice/Payment para que una Sale sea válida.
-- Facturación y cobro se prueban en su bloque futuro, no aquí.
