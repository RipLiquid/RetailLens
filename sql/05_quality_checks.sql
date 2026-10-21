SET search_path TO commerce, public;
-- Every row must pass. This view is also exported by the verification runner.
CREATE VIEW quality_checks AS
SELECT 'orders contain items' AS check_name,
       NOT EXISTS(SELECT 1 FROM orders o LEFT JOIN order_items i USING(order_id) WHERE i.order_id IS NULL) AS passed
UNION ALL
SELECT 'orders follow signup',NOT EXISTS(
    SELECT 1 FROM orders o JOIN customers c USING(customer_id) WHERE o.order_date<c.signup_date)
UNION ALL
SELECT 'returns follow sale and meet 30 day window',NOT EXISTS(
    SELECT 1 FROM returns r JOIN order_items i USING(order_item_id) JOIN orders o USING(order_id)
    WHERE r.return_date<o.order_date OR r.return_date>o.order_date+30 OR o.status<>'completed')
UNION ALL
SELECT 'returned units and refunds within sold amounts',NOT EXISTS(
    SELECT 1 FROM returns r JOIN order_items i USING(order_item_id)
    GROUP BY i.order_item_id,i.quantity,i.unit_price,i.discount_amount
    HAVING sum(r.returned_quantity)>i.quantity OR sum(r.refund_amount)>i.quantity*i.unit_price-i.discount_amount)
UNION ALL
SELECT 'one analytics row per completed item',
    (SELECT count(*) FROM item_economics)=(SELECT count(*) FROM order_items i JOIN orders o USING(order_id) WHERE o.status='completed' AND o.order_date<DATE '2026-01-01')
    AND (SELECT count(*) FROM item_economics)=(SELECT count(DISTINCT order_item_id) FROM item_economics)
UNION ALL
SELECT 'booked revenue reconciles to source',
    (SELECT sum(booked_sales) FROM order_economics)=(SELECT sum(i.quantity*i.unit_price-i.discount_amount) FROM order_items i JOIN orders o USING(order_id) WHERE o.status='completed' AND o.order_date<DATE '2026-01-01')
UNION ALL
SELECT 'refunds reconcile to source',
    (SELECT sum(refunds) FROM order_economics)=(SELECT sum(refund_amount) FROM returns WHERE return_date<DATE '2026-02-01')
UNION ALL
SELECT 'net revenue reconciles across grains',
    (SELECT sum(net_sales) FROM item_economics)=(SELECT sum(net_sales) FROM order_economics)
    AND (SELECT sum(net_sales) FROM monthly_performance)=(SELECT sum(net_sales) FROM category_performance)
UNION ALL
SELECT 'month zero cohort retention equals 100',NOT EXISTS(
    SELECT 1 FROM cohort_retention WHERE month_number=0 AND retention_pct<>100)
UNION ALL
SELECT 'retention within bounds and observable months',NOT EXISTS(
    SELECT 1 FROM cohort_retention WHERE retention_pct<0 OR retention_pct>100 OR activity_month>=DATE '2026-01-01' OR month_number<0)
UNION ALL
SELECT '24 calendar months retained',(SELECT count(*) FROM monthly_performance)=24;

DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM quality_checks WHERE NOT passed) THEN
    RAISE EXCEPTION 'Data quality failed; inspect commerce.quality_checks';
  END IF;
END $$;
