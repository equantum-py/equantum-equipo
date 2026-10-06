-- Phase 0 baseline/reconcile — READ ONLY

select 'clients' entity,count(*) total from public.clients
union all select 'projects',count(*) from public.projects
union all select 'tasks',count(*) from public.tasks
union all select 'followups',count(*) from public.followups
union all select 'tickets',count(*) from public.tickets
union all select 'ticket_messages',count(*) from public.ticket_messages
union all select 'ticket_events',count(*) from public.ticket_events
union all select 'profiles',count(*) from public.profiles
union all select 'user_permissions',count(*) from public.user_permissions
union all select 'chat_messages',count(*) from public.chat_messages
union all select 'client_portal_users',count(*) from public.client_portal_users
order by entity;

-- Huérfanos core: todos deben ser 0.
select 'tasks.client_id' relation,count(*) orphan_count
from public.tasks t left join public.clients c on c.id=t.client_id
where t.client_id is not null and c.id is null
union all
select 'tasks.project_id',count(*)
from public.tasks t left join public.projects p on p.id=t.project_id
where t.project_id is not null and p.id is null
union all
select 'tasks.ticket_id',count(*)
from public.tasks t left join public.tickets x on x.id=t.ticket_id
where t.ticket_id is not null and x.id is null
union all
select 'tickets.client_id',count(*)
from public.tickets x left join public.clients c on c.id=x.client_id
where x.client_id is not null and c.id is null
union all
select 'ticket_messages.ticket_id',count(*)
from public.ticket_messages m left join public.tickets x on x.id=m.ticket_id
where x.id is null
union all
select 'client_portal_users.client_id',count(*)
from public.client_portal_users u left join public.clients c on c.id=u.client_id
where c.id is null;

-- Ticket -> Task actual. >1 será válido en V2.
select ticket_id,count(*) task_count
from public.tasks
where ticket_id is not null
group by ticket_id order by ticket_id;

-- Portal mappings.
select client_id,count(*) portal_users
from public.client_portal_users
group by client_id order by client_id;
