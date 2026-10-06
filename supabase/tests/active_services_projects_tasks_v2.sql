-- Tests Servicios Activos + Proyectos + Tareas V2

-- Una línea de venta no origina dos servicios.
select sale_item_id,count(*) qty
from public.active_services
where sale_item_id is not null
group by sale_item_id having count(*)>1;

-- Projects cerrados con Tasks abiertas: debe devolver 0 después de aplicar
-- el contrato de cierre. Ajustar los estados finales al mapping V2 aprobado.
select p.id,p.name
from public.projects p
where p.status::text in ('completed','closed','completado','cerrado')
  and public.project_has_open_tasks(p.id);

-- Cerrar Project nunca debe cambiar el servicio por efecto implícito.
-- Se valida E2E comparando active_services.status antes/después del cierre.

-- Task completada no implica Ticket cerrado.
-- Esta consulta es informativa: encontrar filas NO es inconsistencia.
select t.id task_id,t.ticket_id,x.status ticket_status
from public.tasks t
join public.tickets x on x.id=t.ticket_id
where t.status::text in ('completada','completed','done');

-- Ticket -> N Tasks está permitido; no tratar >1 como duplicado.
select ticket_id,count(*) task_count
from public.tasks
where ticket_id is not null
group by ticket_id
order by task_count desc;

-- Servicio puede existir sin Project.
select s.id
from public.active_services s
left join public.projects p on p.active_service_id=s.id
where p.id is null;
-- Resultado permitido: no es error.
