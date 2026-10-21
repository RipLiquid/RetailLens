SET search_path TO commerce, public;
-- PGlite may default sequential scans off; allow all standard scan choices.
SET enable_seqscan = on;
SET enable_indexscan = on;
SET enable_bitmapscan = on;
-- Run after schema, seed, views and quality checks. Safe to repeat.
-- Same query before/after the index; record actual evidence, never promise a speedup.
DROP INDEX IF EXISTS commerce.orders_customer_date_idx;
ANALYZE orders;
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date FROM orders
WHERE customer_id=42 AND order_date>=DATE '2025-01-01'
ORDER BY order_date;

CREATE INDEX orders_customer_date_idx ON orders(customer_id,order_date);
ANALYZE orders;
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id,order_date FROM orders
WHERE customer_id=42 AND order_date>=DATE '2025-01-01'
ORDER BY order_date;

-- For meaningful latency comparisons on your server, alternate runs after warming
-- caches, retain at least 10 runs per variant and report median + spread.
-- Indexes consume storage and slow writes. This benchmark covers one read pattern.
