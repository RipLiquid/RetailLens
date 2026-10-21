SET search_path TO commerce, public;
-- Aggregate the many-side BEFORE joining: exactly one row per order item.
CREATE VIEW item_economics AS
WITH refunded AS (
    SELECT order_item_id, sum(returned_quantity) AS returned_units,
           sum(refund_amount) AS refunds
    FROM returns WHERE return_date < DATE '2026-02-01'
    GROUP BY order_item_id
)
SELECT i.order_item_id, i.order_id, o.customer_id, o.order_date,
       i.product_id, i.quantity, i.quantity*i.unit_price AS gross_sales,
       i.discount_amount, i.quantity*i.unit_price-i.discount_amount AS booked_sales,
       coalesce(r.returned_units,0) AS returned_units, coalesce(r.refunds,0) AS refunds,
       i.quantity*i.unit_price-i.discount_amount-coalesce(r.refunds,0) AS net_sales,
       (i.quantity-coalesce(r.returned_units,0))*i.unit_cost_at_sale AS retained_cogs
FROM order_items i JOIN orders o USING(order_id)
LEFT JOIN refunded r USING(order_item_id)
WHERE o.status='completed' AND o.order_date < DATE '2026-01-01';

CREATE VIEW order_economics AS
SELECT order_id, customer_id, order_date,
       sum(booked_sales) AS booked_sales, sum(refunds) AS refunds,
       sum(net_sales) AS net_sales, sum(retained_cogs) AS retained_cogs
FROM item_economics GROUP BY order_id, customer_id, order_date;
