begin;

-- ============================================================
-- RADAR V2
-- Fuente operativa para continuidad y seguimiento.
-- No depende de navegador, IA ni cron.
-- ============================================================

-- Evitar duplicados activos para la misma fuente.
create unique index if not exists radar_items_active_source_uidx
on public.radar_items(source_type, source_id)
where state = 'active';

-- ------------------------------------------------------------
-- Vista operativa:
-- vencido se calcula en tiempo real.
-- ------------------------------------------------------------

create or replace view public.radar_operational_v2
with (security_invoker = true)
as
select
  r.id,
  r.source_type,
  r.source_id,
  r.responsible_id,
  r.state,
  r.next_action,
  r.next_review_at,
  r.condition_text,
  r.last_movement_at,
  r.legacy_followup_id,
  r.created_at,
  r.updated_at,
  r.closed_at,

  case
    when r.state <> 'active' then 'closed'
    when r.next_review_at is null then 'unscheduled'
    when r.next_review_at < now() then 'overdue'
    else 'scheduled'
  end as operational_status,

  case
    when r.state = 'active'
     and r.next_review_at is not null
     and r.next_review_at < now()
    then true
    else false
  end as is_overdue

from public.radar_items r;

-- ------------------------------------------------------------
-- Registrar/actualizar un asunto en Radar.
-- Idempotente por source_type + source_id mientras esté activo.
-- ------------------------------------------------------------

create or replace function public.upsert_radar_item(
  p_source_type text,
  p_source_id uuid,
  p_responsible_id uuid,
  p_next_action text,
  p_next_review_at timestamptz default null,
  p_condition_text text default null
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_id uuid;
begin
  if not public.is_internal_user() then
    raise exception 'RADAR_INTERNAL_ONLY';
  end if;

  if nullif(trim(p_source_type), '') is null then
    raise exception 'RADAR_SOURCE_TYPE_REQUIRED';
  end if;

  if p_source_id is null then
    raise exception 'RADAR_SOURCE_ID_REQUIRED';
  end if;

  if nullif(trim(p_next_action), '') is null then
    raise exception 'RADAR_NEXT_ACTION_REQUIRED';
  end if;

  select id
    into v_id
  from public.radar_items
  where source_type = p_source_type
    and source_id = p_source_id
    and state = 'active'
  limit 1;

  if v_id is not null then

    update public.radar_items
       set responsible_id = coalesce(p_responsible_id, responsible_id),
           next_action = p_next_action,
           next_review_at = p_next_review_at,
           condition_text = p_condition_text,
           last_movement_at = now(),
           updated_at = now()
     where id = v_id;

    return v_id;

  end if;

  insert into public.radar_items(
    source_type,
    source_id,
    responsible_id,
    state,
    next_action,
    next_review_at,
    condition_text,
    last_movement_at
  )
  values(
    p_source_type,
    p_source_id,
    p_responsible_id,
    'active',
    p_next_action,
    p_next_review_at,
    p_condition_text,
    now()
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- ------------------------------------------------------------
-- Cerrar Radar.
-- ------------------------------------------------------------

create or replace function public.close_radar_item(
  p_radar_id uuid
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if not public.is_internal_user() then
    raise exception 'RADAR_INTERNAL_ONLY';
  end if;

  update public.radar_items
     set state = 'closed',
         closed_at = now(),
         last_movement_at = now(),
         updated_at = now()
   where id = p_radar_id
     and state = 'active';

  if not found then
    raise exception 'RADAR_ACTIVE_ITEM_NOT_FOUND';
  end if;
end;
$$;

-- ------------------------------------------------------------
-- Compatibilidad legacy:
-- Followup nuevo -> Radar.
-- ------------------------------------------------------------

create or replace function public.sync_followup_to_radar()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_radar_id uuid;
begin

  if new.status::text = 'pending' then

    select id
      into v_radar_id
    from public.radar_items
    where legacy_followup_id = new.id
    limit 1;

    if v_radar_id is null then

      insert into public.radar_items(
        source_type,
        source_id,
        responsible_id,
        state,
        next_action,
        next_review_at,
        condition_text,
        last_movement_at,
        legacy_followup_id
      )
      values(
        'task',
        new.task_id,
        new.responsible_id,
        'active',
        new.next_action,
        new.next_followup_at,
        'Seguimiento operativo',
        coalesce(new.last_movement_at, now()),
        new.id
      )
      returning id into v_radar_id;

    else

      update public.radar_items
         set responsible_id = new.responsible_id,
             state = 'active',
             next_action = new.next_action,
             next_review_at = new.next_followup_at,
             last_movement_at = coalesce(new.last_movement_at, now()),
             closed_at = null,
             updated_at = now()
       where id = v_radar_id;

    end if;

  else

    update public.radar_items
       set state = 'closed',
           closed_at = coalesce(closed_at, now()),
           last_movement_at = coalesce(new.last_movement_at, now()),
           updated_at = now()
     where legacy_followup_id = new.id
       and state = 'active';

  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_followup_to_radar
on public.followups;

create trigger trg_sync_followup_to_radar
after insert or update of
  status,
  next_action,
  next_followup_at,
  responsible_id,
  last_movement_at
on public.followups
for each row
execute function public.sync_followup_to_radar();

-- ------------------------------------------------------------
-- Reconciliación de followups existentes.
-- Es idempotente gracias a legacy_followup_id UNIQUE.
-- ------------------------------------------------------------

insert into public.radar_items(
  source_type,
  source_id,
  responsible_id,
  state,
  next_action,
  next_review_at,
  condition_text,
  last_movement_at,
  legacy_followup_id,
  closed_at
)
select
  'task',
  f.task_id,
  f.responsible_id,
  case
    when f.status::text = 'pending' then 'active'
    else 'closed'
  end,
  f.next_action,
  f.next_followup_at,
  'Seguimiento operativo',
  coalesce(f.last_movement_at, f.created_at),
  f.id,
  case
    when f.status::text = 'pending' then null
    else coalesce(f.last_movement_at, f.updated_at, now())
  end
from public.followups f
where not exists (
  select 1
  from public.radar_items r
  where r.legacy_followup_id = f.id
);

-- ------------------------------------------------------------
-- Seguridad
-- ------------------------------------------------------------

drop policy if exists "radar items internal read"
on public.radar_items;

create policy "radar items internal read"
on public.radar_items
for select
to authenticated
using (
  public.is_internal_user()
);

drop policy if exists "radar items internal insert"
on public.radar_items;

create policy "radar items internal insert"
on public.radar_items
for insert
to authenticated
with check (
  public.is_internal_user()
);

drop policy if exists "radar items internal update"
on public.radar_items;

create policy "radar items internal update"
on public.radar_items
for update
to authenticated
using (
  public.is_internal_user()
)
with check (
  public.is_internal_user()
);

revoke all on function public.upsert_radar_item(
  text, uuid, uuid, text, timestamptz, text
) from public, anon;

grant execute on function public.upsert_radar_item(
  text, uuid, uuid, text, timestamptz, text
) to authenticated;

revoke all on function public.close_radar_item(uuid)
from public, anon;

grant execute on function public.close_radar_item(uuid)
to authenticated;

revoke all on function public.sync_followup_to_radar()
from public, anon, authenticated;

commit;
