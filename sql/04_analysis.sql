SET search_path TO commerce, public;

-- Q1: Does growth persist after discounts and observed returns?
-- Date spine retains months without sales; LAG compares adjacent calendar months.
CREATE VIEW monthly_performance AS
WITH months AS (
    SELECT d::date AS month FROM generate_series(DATE '2024-01-01',DATE '2025-12-01',INTERVAL '1 month') AS s(d)
), monthly AS (
    SELECT date_trunc('month',order_date)::date AS month,
           count(*) AS orders, count(DISTINCT customer_id) AS customers,
           sum(booked_sales) AS booked_sales, sum(refunds) AS refunds,
           sum(net_sales) AS net_sales
    FROM order_economics GROUP BY 1
), base AS (
    SELECT m.month, coalesce(x.orders,0) AS orders, coalesce(x.customers,0) AS customers,
           coalesce(x.booked_sales,0) AS booked_sales, coalesce(x.refunds,0) AS refunds,
           coalesce(x.net_sales,0) AS net_sales
    FROM months m LEFT JOIN monthly x USING(month)
)
SELECT *, round(net_sales/nullif(orders,0),2) AS net_aov,
       round(100*(net_sales/nullif(lag(net_sales) OVER (ORDER BY month),0)-1),2) AS mom_net_sales_pct
FROM base;

-- Q2: Which categories retain the most value after refunds?
CREATE VIEW category_performance AS
SELECT p.category, sum(i.quantity) AS sold_units, sum(i.returned_units) AS returned_units,
       round(100.0*sum(i.returned_units)/nullif(sum(i.quantity),0),2) AS unit_return_pct,
       sum(i.booked_sales) AS booked_sales, sum(i.refunds) AS refunds,
       sum(i.net_sales) AS net_sales,
       sum(i.net_sales-i.retained_cogs) AS merchandise_margin,
       round(100*sum(i.net_sales-i.retained_cogs)/nullif(sum(i.net_sales),0),2) AS margin_pct
FROM item_economics i JOIN products p USING(product_id) GROUP BY p.category;

-- Q3: Do acquisition channels attract customers who buy again?
CREATE VIEW channel_performance AS
WITH customer_value AS (
    SELECT c.customer_id,c.acquisition_channel,count(o.order_id) AS orders,
           coalesce(sum(o.net_sales),0) AS net_sales
    FROM customers c LEFT JOIN order_economics o USING(customer_id)
    GROUP BY c.customer_id,c.acquisition_channel
)
SELECT acquisition_channel,count(*) AS signups,
       count(*) FILTER (WHERE orders>0) AS buyers,
       count(*) FILTER (WHERE orders>1) AS repeat_buyers,
       round(100.0*count(*) FILTER (WHERE orders>1)/nullif(count(*) FILTER (WHERE orders>0),0),2) AS repeat_buyer_pct,
       sum(net_sales) AS net_sales,
       round(sum(net_sales)/nullif(count(*) FILTER (WHERE orders>0),0),2) AS net_sales_per_buyer
FROM customer_value GROUP BY acquisition_channel;

-- Q4: What proportion of a first-purchase cohort buys in each subsequent month?
-- New cohorts have no rows for unobserved ages; zero means observed but inactive.
CREATE VIEW cohort_retention AS
WITH first_purchase AS (
    SELECT customer_id,date_trunc('month',min(order_date))::date AS cohort_month
    FROM order_economics GROUP BY customer_id
), sizes AS (
    SELECT cohort_month,count(*) AS cohort_size FROM first_purchase GROUP BY cohort_month
), active AS (
    SELECT f.cohort_month,date_trunc('month',o.order_date)::date AS activity_month,
           count(DISTINCT o.customer_id) AS active_customers
    FROM first_purchase f JOIN order_economics o USING(customer_id) GROUP BY 1,2
), spine AS (
    SELECT z.*,d::date AS activity_month FROM sizes z
    CROSS JOIN LATERAL generate_series(z.cohort_month,DATE '2025-12-01',INTERVAL '1 month') AS s(d)
)
SELECT s.cohort_month,s.activity_month,
       (extract(year FROM age(s.activity_month,s.cohort_month))*12+
        extract(month FROM age(s.activity_month,s.cohort_month)))::integer AS month_number,
       s.cohort_size,coalesce(a.active_customers,0) AS active_customers,
       round(100.0*coalesce(a.active_customers,0)/s.cohort_size,2) AS retention_pct
FROM spine s LEFT JOIN active a USING(cohort_month,activity_month);

-- Q5: Which products account for the largest shares of revenue within a category?
CREATE VIEW product_ranking AS
WITH product_sales AS (
    SELECT p.product_id,p.product_name,p.category,sum(i.net_sales) AS net_sales
    FROM products p JOIN item_economics i USING(product_id) GROUP BY p.product_id
)
SELECT *,dense_rank() OVER (PARTITION BY category ORDER BY net_sales DESC) AS category_rank,
       round(100*net_sales/nullif(sum(net_sales) OVER (PARTITION BY category),0),2) AS category_share_pct,
       round(100*sum(net_sales) OVER (PARTITION BY category ORDER BY net_sales DESC,product_id ROWS UNBOUNDED PRECEDING)
           /nullif(sum(net_sales) OVER (PARTITION BY category),0),2) AS cumulative_category_share_pct
FROM product_sales;

-- Q6: Which customers are recent, frequent and high value at a fixed snapshot?
-- Quantile ties use customer_id for reproducibility; tied customers may span buckets.
CREATE VIEW customer_rfm AS
WITH base AS (
    SELECT customer_id,DATE '2026-01-01'-max(order_date) AS recency_days,
           count(*) AS frequency,sum(net_sales) AS monetary
    FROM order_economics GROUP BY customer_id
)
SELECT *,ntile(5) OVER (ORDER BY recency_days DESC,customer_id) AS recency_score,
       ntile(5) OVER (ORDER BY frequency,customer_id) AS frequency_score,
       ntile(5) OVER (ORDER BY monetary,customer_id) AS monetary_score
FROM base;
