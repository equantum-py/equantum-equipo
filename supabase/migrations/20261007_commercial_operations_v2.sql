-- Operaciones Comerciales V2
-- Prospect -> Opportunity / WON -> Sale / LOST / Quick Sale
-- PREPARACION: probar solamente en staging antes de produccion.

begin;

-- ============================================================
-- 1. PROSPECT -> OPPORTUNITY
-- Idempotente: un Prospect solo puede originar una Opportunity.
-- ============================================================

create or replace function public.convert_prospect_to_opportunity(
  p_prospect_id uuid,
  p_title text,
  p_catalog_item_id uuid default null,
  p_currency text default null,
  p_expected_amount numeric default null
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_prospect public.prospects%rowtype;
  v_opportunity_id uuid;
begin
  select *
    into v_prospect
  from public.prospects
  where id = p_prospect_id
    and archived_at is null
  for update;

  if not found then
    raise exception 'prospect not found or archived';
  end if;

  -- Idempotencia: devolver la Opportunity existente.
  select id
    into v_opportunity_id
  from public.opportunities
  where prospect_id = p_prospect_id
  limit 1;

  if v_opportunity_id is not null then
    return v_opportunity_id;
  end if;

  insert into public.opportunities(
    commercial_entity_id,
    prospect_id,
    title,
    stage,
    owner_id,
    currency,
    expected_amount,
    catalog_item_id
  )
  values(
    v_prospect.commercial_entity_id,
    v_prospect.id,
    p_title,
    'open',
    v_prospect.owner_id,
    p_currency,
    p_expected_amount,
    p_catalog_item_id
  )
  returning id into v_opportunity_id;

  update public.prospects
  set status = 'converted',
      converted_at = coalesce(converted_at, now())
  where id = p_prospect_id;

  return v_opportunity_id;
end;
$$;


-- ============================================================
-- 2. WON -> SALE
-- Exactamente una Sale por Opportunity.
-- Snapshot de Proposal + Proposal Items.
-- ============================================================

create or replace function public.close_opportunity_won(
  p_opportunity_id uuid,
  p_proposal_id uuid
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_opportunity public.opportunities%rowtype;
  v_proposal public.proposals%rowtype;
  v_entity public.commercial_entities%rowtype;
  v_sale_id uuid;
  v_subtotal numeric(18,2);
  v_discount numeric(18,2);
  v_tax numeric(18,2);
  v_total numeric(18,2);
begin
  select *
    into v_opportunity
  from public.opportunities
  where id = p_opportunity_id
  for update;

  if not found then
    raise exception 'opportunity not found';
  end if;

  -- Repetir WON devuelve la misma Sale.
  select id
    into v_sale_id
  from public.sales
  where opportunity_id = p_opportunity_id;

  if v_sale_id is not null then
    if v_opportunity.outcome = 'won' then
      return v_sale_id;
    end if;

    raise exception 'sale exists for opportunity in incompatible state';
  end if;

  if v_opportunity.outcome = 'lost' then
    raise exception 'lost opportunity cannot be won';
  end if;

  select *
    into v_proposal
  from public.proposals
  where id = p_proposal_id
    and opportunity_id = p_opportunity_id
  for update;

  if not found then
    raise exception 'proposal not found for opportunity';
  end if;

  if v_proposal.currency is null then
    raise exception 'proposal currency is required';
  end if;

  select *
    into v_entity
  from public.commercial_entities
  where id = v_opportunity.commercial_entity_id;

  if not found then
    raise exception 'commercial entity not found';
  end if;

  select
    coalesce(sum(coalesce(line_subtotal, quantity * unit_price)),0),
    coalesce(sum(discount_amount),0),
    coalesce(sum(tax_amount),0),
    coalesce(sum(
      coalesce(
        line_total,
        coalesce(line_subtotal, quantity * unit_price)
          - discount_amount
          + tax_amount
      )
    ),0)
  into
    v_subtotal,
    v_discount,
    v_tax,
    v_total
  from public.proposal_items
  where proposal_id = p_proposal_id;

  if not exists (
    select 1
    from public.proposal_items
    where proposal_id = p_proposal_id
  ) then
    raise exception 'proposal requires at least one item';
  end if;

  insert into public.sales(
    opportunity_id,
    commercial_entity_id,
    proposal_id,
    currency,
    gross_amount,
    tax_amount,
    net_amount,
    closed_at,
    proposal_version,
    entity_display_name,
    entity_legal_name,
    entity_tax_id,
    subtotal_amount,
    discount_amount,
    commission_base_amount,
    snapshot_at
  )
  values(
    p_opportunity_id,
    v_opportunity.commercial_entity_id,
    p_proposal_id,
    v_proposal.currency,
    v_total,
    v_tax,
    v_total - v_tax,
    now(),
    v_proposal.version,
    v_entity.display_name,
    v_entity.legal_name,
    v_entity.tax_id,
    v_subtotal,
    v_discount,
    v_total - v_tax,
    now()
  )
  returning id into v_sale_id;

  insert into public.sale_items(
    sale_id,
    source_proposal_item_id,
    catalog_item_id,
    item_name,
    description,
    quantity,
    unit_price,
    discount_amount,
    subtotal_amount,
    tax_treatment,
    tax_amount,
    total_amount
  )
  select
    v_sale_id,
    pi.id,
    pi.catalog_item_id,
    coalesce(ci.name, pi.description),
    pi.description,
    pi.quantity,
    pi.unit_price,
    pi.discount_amount,
    coalesce(pi.line_subtotal, pi.quantity * pi.unit_price),
    pi.tax_treatment,
    pi.tax_amount,
    coalesce(
      pi.line_total,
      coalesce(pi.line_subtotal, pi.quantity * pi.unit_price)
        - pi.discount_amount
        + pi.tax_amount
    )
  from public.proposal_items pi
  left join public.catalog_items ci on ci.id = pi.catalog_item_id
  where pi.proposal_id = p_proposal_id;

  update public.proposals
  set status = 'accepted',
      accepted_at = coalesce(accepted_at, now())
  where id = p_proposal_id;

  update public.opportunities
  set outcome = 'won',
      stage = 'closed',
      closed_at = coalesce(closed_at, now()),
      loss_reason = null
  where id = p_opportunity_id;

  return v_sale_id;
end;
$$;


-- ============================================================
-- 3. LOST
-- Nunca crea Sale ni Client.
-- ============================================================

create or replace function public.close_opportunity_lost(
  p_opportunity_id uuid,
  p_loss_reason text
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_opportunity public.opportunities%rowtype;
begin
  select *
    into v_opportunity
  from public.opportunities
  where id = p_opportunity_id
  for update;

  if not found then
    raise exception 'opportunity not found';
  end if;

  if exists (
    select 1 from public.sales
    where opportunity_id = p_opportunity_id
  ) then
    raise exception 'opportunity with sale cannot be lost';
  end if;

  if v_opportunity.outcome = 'won' then
    raise exception 'won opportunity cannot be lost';
  end if;

  update public.opportunities
  set outcome = 'lost',
      stage = 'closed',
      closed_at = coalesce(closed_at, now()),
      loss_reason = nullif(trim(p_loss_reason),'')
  where id = p_opportunity_id;

  return p_opportunity_id;
end;
$$;


-- ============================================================
-- 4. QUICK SALE
-- Reutiliza Opportunity abierta equivalente.
-- Si no existe crea la mínima y luego usa el mismo cierre WON.
-- ============================================================

create or replace function public.quick_sale(
  p_commercial_entity_id uuid,
  p_catalog_item_id uuid,
  p_title text,
  p_proposal_id uuid
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_opportunity_id uuid;
begin
  select id
    into v_opportunity_id
  from public.opportunities
  where commercial_entity_id = p_commercial_entity_id
    and catalog_item_id = p_catalog_item_id
    and closed_at is null
  order by created_at
  limit 1
  for update;

  if v_opportunity_id is null then
    insert into public.opportunities(
      commercial_entity_id,
      catalog_item_id,
      title,
      stage,
      is_quick_sale
    )
    values(
      p_commercial_entity_id,
      p_catalog_item_id,
      p_title,
      'open',
      true
    )
    returning id into v_opportunity_id;
  end if;

  -- La propuesta debe pertenecer a la Opportunity reutilizada/creada.
  if not exists (
    select 1
    from public.proposals
    where id = p_proposal_id
      and opportunity_id = v_opportunity_id
  ) then
    raise exception 'proposal does not belong to quick-sale opportunity';
  end if;

  perform public.close_opportunity_won(
    v_opportunity_id,
    p_proposal_id
  );

  return v_opportunity_id;
end;
$$;

-- No exponer estas operaciones a anon.
revoke execute on function public.convert_prospect_to_opportunity(uuid,text,uuid,text,numeric) from public, anon;
revoke execute on function public.close_opportunity_won(uuid,uuid) from public, anon;
revoke execute on function public.close_opportunity_lost(uuid,text) from public, anon;
revoke execute on function public.quick_sale(uuid,uuid,text,uuid) from public, anon;

grant execute on function public.convert_prospect_to_opportunity(uuid,text,uuid,text,numeric) to authenticated;
grant execute on function public.close_opportunity_won(uuid,uuid) to authenticated;
grant execute on function public.close_opportunity_lost(uuid,text) to authenticated;
grant execute on function public.quick_sale(uuid,uuid,text,uuid) to authenticated;

commit;
