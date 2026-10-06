-- Reconciliacion V2 - consultas read-only para ensayo y corte
-- Este archivo NO modifica datos.

-- Conteos base
select 'clients' entity,count(*) total from public.clients
union all select 'projects',count(*) from public.projects
union all select 'tasks',count(*) from public.tasks
union all select 'followups',count(*) from public.followups
union all select 'tickets',count(*) from public.tickets;

-- Duplicados exactos normalizados
select lower(trim(name)) key,count(*) qty,array_agg(id) ids
from public.clients group by lower(trim(name)) having count(*)>1;

select lower(trim(email)) key,count(*) qty,array_agg(id) ids
from public.clients where nullif(trim(email),'') is not null
group by lower(trim(email)) having count(*)>1;

select regexp_replace(phone,'[^0-9]','','g') key,count(*) qty,array_agg(id) ids
from public.clients
where nullif(regexp_replace(phone,'[^0-9]','','g'),'') is not null
group by regexp_replace(phone,'[^0-9]','','g') having count(*)>1;

-- Relaciones huerfanas
select 'projects.client_id' relation,count(*) orphan_count from public.projects p left join public.clients c on c.id=p.client_id where p.client_id is not null and c.id is null
union all select 'tasks.client_id',count(*) from public.tasks t left join public.clients c on c.id=t.client_id where t.client_id is not null and c.id is null
union all select 'tasks.project_id',count(*) from public.tasks t left join public.projects p on p.id=t.project_id where t.project_id is not null and p.id is null
union all select 'tasks.ticket_id',count(*) from public.tasks t left join public.tickets x on x.id=t.ticket_id where t.ticket_id is not null and x.id is null
union all select 'followups.task_id',count(*) from public.followups f left join public.tasks t on t.id=f.task_id where t.id is null
union all select 'tickets.client_id',count(*) from public.tickets x left join public.clients c on c.id=x.client_id where x.client_id is not null and c.id is null;

-- Candidatos ambiguos: solo reporte, nunca auto-link.
select id,title,client_id,project_id,ticket_id
from public.tasks
where client_id is null
order by created_at,id;

-- Multiplicidad Ticket -> Tasks. Tener >1 NO es error en V2.
select ticket_id,count(*) task_count
from public.tasks where ticket_id is not null
group by ticket_id order by task_count desc;
