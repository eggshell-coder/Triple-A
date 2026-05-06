-- ============================================================
-- Triple A hardening SQL
-- Idempotent order placement + dashboard summaries
-- ============================================================


-- ============================================================
-- 1. Order idempotency table
-- ============================================================

create table if not exists public.order_idempotency (
  idempotency_key text primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  user_id uuid null,
  created_at timestamptz not null default now()
);

-- If your table already existed with a different primary key setup,
-- this keeps the required unique contract in place.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'order_idempotency_idempotency_key_unique'
  ) then
    alter table public.order_idempotency
    add constraint order_idempotency_idempotency_key_unique
    unique (idempotency_key);
  end if;
end $$;


-- ============================================================
-- 2. Drop old RPC if it used UUID idempotency key
-- ============================================================

drop function if exists public.place_order_atomic(
  uuid,
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  numeric,
  text,
  jsonb
);


-- ============================================================
-- 3. Recreate RPC with TEXT idempotency key
-- ============================================================

create or replace function public.place_order_atomic(
  p_idempotency_key text,
  p_user_id uuid,
  p_full_name text,
  p_phone text,
  p_district text,
  p_upazila text,
  p_address_line text,
  p_email text,
  p_delivery_charge numeric,
  p_note text,
  p_items jsonb
)
returns jsonb
language plpgsql
as $function$
declare
    v_existing_order uuid;
    v_customer_id uuid;
    v_order_id uuid;
    v_subtotal numeric := 0;
    v_total numeric;
    v_item jsonb;
    v_product_id uuid;
    v_quantity int;
    v_price numeric;
    v_updated int;
begin
    -- Idempotency: same key returns existing order
    if p_idempotency_key is not null then
        select oi.order_id
          into v_existing_order
          from public.order_idempotency oi
         where oi.idempotency_key = p_idempotency_key;

        if v_existing_order is not null then
            return jsonb_build_object(
                'order_id', v_existing_order,
                'duplicate', true
            );
        end if;
    end if;

    -- Validate items
    if p_items is null or jsonb_array_length(p_items) = 0 then
        raise exception 'EMPTY_ORDER_ITEMS';
    end if;

    -- Atomic stock decrement per item
    for v_item in select * from jsonb_array_elements(p_items) loop
        v_product_id := (v_item->>'product_id')::uuid;
        v_quantity := (v_item->>'quantity')::int;

        if v_quantity <= 0 then
            raise exception 'INVALID_QUANTITY:%', v_product_id;
        end if;

        update public.products
           set stock = stock - v_quantity
         where id = v_product_id
           and is_active = true
           and stock >= v_quantity
        returning price into v_price;

        get diagnostics v_updated = row_count;

        if v_updated = 0 then
            raise exception 'OUT_OF_STOCK:%', v_product_id;
        end if;

        v_subtotal := v_subtotal + (v_price * v_quantity);
    end loop;

    v_total := v_subtotal + coalesce(p_delivery_charge, 0);

    -- Insert customer shipping snapshot
    insert into public.customers (
        full_name,
        phone,
        district,
        upazila,
        address_line,
        email
    )
    values (
        p_full_name,
        p_phone,
        p_district,
        p_upazila,
        p_address_line,
        p_email
    )
    returning id into v_customer_id;

    -- Insert order
    insert into public.orders (
        customer_id,
        user_id,
        total_amount,
        delivery_charge,
        district,
        upazila,
        status,
        note
    )
    values (
        v_customer_id,
        p_user_id,
        v_total,
        coalesce(p_delivery_charge, 0),
        p_district,
        p_upazila,
        'pending',
        p_note
    )
    returning id into v_order_id;

    -- Insert order items
    insert into public.order_items (
        order_id,
        product_id,
        quantity,
        unit_price
    )
    select
        v_order_id,
        (i->>'product_id')::uuid,
        (i->>'quantity')::int,
        p.price
    from jsonb_array_elements(p_items) as i
    join public.products p
      on p.id = (i->>'product_id')::uuid;

    -- Record idempotency key
    if p_idempotency_key is not null then
        insert into public.order_idempotency (
            idempotency_key,
            order_id,
            user_id
        )
        values (
            p_idempotency_key,
            v_order_id,
            p_user_id
        );
    end if;

    return jsonb_build_object(
        'order_id', v_order_id,
        'total_amount', v_total,
        'duplicate', false
    );
end;
$function$;


-- ============================================================
-- 4. Revenue summary view
-- ============================================================

create or replace view public.v_revenue_summary as
select
  coalesce(sum(total_amount), 0) as total_revenue,
  coalesce(sum(total_amount) filter (where status = 'pending'), 0) as pending_revenue,
  coalesce(sum(total_amount) filter (where status = 'delivered'), 0) as delivered_revenue,
  coalesce(count(*), 0) as order_count,
  coalesce(count(*) filter (where status = 'pending'), 0) as pending_order_count,
  coalesce(count(*) filter (where status = 'delivered'), 0) as delivered_order_count
from public.orders;


-- ============================================================
-- 5. Product sales summary view
-- ============================================================

create or replace view public.v_product_sales_summary as
select
  p.id as product_id,
  p.name as product_name,
  coalesce(sum(oi.quantity), 0) as total_qty,
  coalesce(sum(oi.quantity * oi.unit_price), 0) as total_sales
from public.products p
left join public.order_items oi
  on oi.product_id = p.id
left join public.orders o
  on o.id = oi.order_id
group by
  p.id,
  p.name;


-- ============================================================
-- 6. Dashboard stats RPC
-- ============================================================

create or replace function public.get_dashboard_stats()
returns jsonb
language sql
stable
as $function$
  select jsonb_build_object(
    'total_revenue', coalesce(r.total_revenue, 0),
    'pending_revenue', coalesce(r.pending_revenue, 0),
    'delivered_revenue', coalesce(r.delivered_revenue, 0),
    'order_count', coalesce(r.order_count, 0),
    'pending_order_count', coalesce(r.pending_order_count, 0),
    'delivered_order_count', coalesce(r.delivered_order_count, 0),
    'total_products_sold', coalesce((
      select sum(total_qty)
      from public.v_product_sales_summary
    ), 0)
  )
  from public.v_revenue_summary r;
$function$;