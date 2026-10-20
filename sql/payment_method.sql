-- sql/payment_method.sql
-- Add payment method tracking to orders table.
-- Run this in Supabase SQL Editor.

-- Add payment columns to orders table
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS payment_method VARCHAR(30) DEFAULT 'cash_on_delivery',
  ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS bkash_transaction_id VARCHAR(60),
  ADD COLUMN IF NOT EXISTS bkash_paid_to VARCHAR(20);

-- Constrain values
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_payment_method_check;
ALTER TABLE orders
  ADD CONSTRAINT orders_payment_method_check
  CHECK (payment_method IN ('cash_on_delivery', 'bkash'));

ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_payment_status_check;
ALTER TABLE orders
  ADD CONSTRAINT orders_payment_status_check
  CHECK (payment_status IN ('pending', 'paid', 'verified', 'failed'));

-- Index for admin filtering
CREATE INDEX IF NOT EXISTS idx_orders_payment_method ON orders (payment_method);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders (payment_status);

-- Update place_order_atomic RPC to accept payment info
CREATE OR REPLACE FUNCTION public.place_order_atomic(
  p_idempotency_key      text,
  p_user_id              uuid,
  p_full_name            text,
  p_phone                text,
  p_district             text,
  p_upazila              text,
  p_address_line         text,
  p_email                text,
  p_delivery_charge      numeric,
  p_note                 text,
  p_items                jsonb,
  p_payment_method       text    DEFAULT 'cash_on_delivery',
  p_bkash_transaction_id text    DEFAULT NULL,
  p_bkash_paid_to        text    DEFAULT NULL
)
returns jsonb
language plpgsql
as $function$
declare
    v_existing_order uuid;
    v_customer_id    uuid;
    v_order_id       uuid;
    v_subtotal       numeric := 0;
    v_total          numeric;
    v_item           jsonb;
    v_product_id     uuid;
    v_quantity       int;
    v_price          numeric;
    v_updated        int;
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

    -- Insert order (with payment info)
    insert into public.orders (
        customer_id,
        user_id,
        total_amount,
        delivery_charge,
        district,
        upazila,
        status,
        note,
        payment_method,
        payment_status,
        bkash_transaction_id,
        bkash_paid_to
    )
    values (
        v_customer_id,
        p_user_id,
        v_total,
        coalesce(p_delivery_charge, 0),
        p_district,
        p_upazila,
        'pending',
        p_note,
        coalesce(p_payment_method, 'cash_on_delivery'),
        case when p_payment_method = 'bkash' then 'pending' else 'paid' end,
        p_bkash_transaction_id,
        p_bkash_paid_to
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