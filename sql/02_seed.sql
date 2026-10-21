SET search_path TO commerce, public;
-- Stable pseudo-random values: no dependency on database random() state.
CREATE FUNCTION sample_int(key_text text, bucket_count integer) RETURNS integer
LANGUAGE sql IMMUTABLE STRICT AS $$
  SELECT ((('x' || substr(md5(key_text),1,8))::bit(32)::bigint) % bucket_count)::integer
$$;

INSERT INTO customers
SELECT n, DATE '2024-01-01' + sample_int('signup:'||n, 540),
       (ARRAY['Organic','Paid search','Social','Referral'])[1+sample_int('channel:'||n,4)],
       (ARRAY['Ontario','Quebec','British Columbia','Alberta'])[1+sample_int('region:'||n,4)]
FROM generate_series(1,10000) AS s(n);

INSERT INTO products
SELECT n, 'Product ' || lpad(n::text,3,'0'),
       (ARRAY['Apparel','Electronics','Home','Accessories'])[1+(n-1)%4],
       20 + sample_int('price:'||n,180),
       round((20 + sample_int('price:'||n,180)) * (0.35 + sample_int('cost:'||n,30)/100.0),2)
FROM generate_series(1,120) AS s(n);

INSERT INTO orders
SELECT n, c.customer_id,
       c.signup_date + sample_int('date:'||n, DATE '2026-01-01' - c.signup_date),
       CASE WHEN sample_int('status:'||n,100)<6 THEN 'cancelled' ELSE 'completed' END
FROM generate_series(1,36000) AS s(n)
-- 20% of signups never order; a smaller group buys more frequently.
JOIN customers c ON c.customer_id=CASE WHEN sample_int('segment:'||n,100)<40
    THEN 1+sample_int('customer:'||n,1000)
    ELSE 1001+sample_int('customer:'||n,7000) END;

INSERT INTO order_items
SELECT (o.order_id-1)*3+k, o.order_id, p.product_id,
       1+sample_int('qty:'||o.order_id||':'||k,3), p.list_price, p.unit_cost,
       round((1+sample_int('qty:'||o.order_id||':'||k,3))*p.list_price *
          CASE WHEN sample_int('discount:'||o.order_id||':'||k,100)<30 THEN 0.15 ELSE 0 END,2)
FROM orders o
CROSS JOIN generate_series(1,3) AS s(k)
JOIN products p ON p.product_id=1+sample_int('product:'||o.order_id||':'||k,120)
WHERE k <= 1+sample_int('lines:'||o.order_id,3);

-- One or two distinct unit-return events per selected line to exercise join fan-out.
INSERT INTO returns
SELECT i.order_item_id*2+event_no, i.order_item_id,
       o.order_date + CASE WHEN event_no=1 THEN 5+sample_int('delay:'||i.order_item_id,10)
                          ELSE 20+sample_int('delay2:'||i.order_item_id,11) END,
       1, round((i.quantity*i.unit_price-i.discount_amount)/i.quantity,2),
       CASE WHEN p.category='Apparel' THEN 'Fit' ELSE 'Changed mind' END
FROM order_items i
JOIN orders o USING(order_id)
JOIN products p USING(product_id)
CROSS JOIN generate_series(1,2) AS s(event_no)
WHERE o.status='completed'
  AND sample_int('return:'||i.order_item_id,100) < CASE WHEN p.category='Apparel' THEN 22 ELSE 8 END
  AND event_no <= CASE WHEN i.quantity>=2 AND sample_int('split:'||i.order_item_id,100)<25 THEN 2 ELSE 1 END;
