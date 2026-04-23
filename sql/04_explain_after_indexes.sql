\timing on
\echo '=== AFTER INDEXES ==='

SET max_parallel_workers_per_gather = 0;
SET work_mem = '32MB';
ANALYZE;

-- ============================================
-- TODO:
-- Скопируйте сюда ТО ЖЕ множество запросов из 02_explain_before.sql
-- и выполните EXPLAIN (ANALYZE, BUFFERS) повторно.
-- ============================================

\echo '--- Q1 ---'
-- TODO: EXPLAIN (ANALYZE, BUFFERS) ...
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, status, total_amount, created_at
FROM orders
WHERE user_id = (SELECT id FROM users WHERE email = 'user00001@example.com')  and status = 'paid'
ORDER by created_at DESC
LIMIT 20;
\echo '--- Q2 ---'
-- TODO: EXPLAIN (ANALYZE, BUFFERS) ...
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, total_amount, created_at
FROM orders
WHERE status = 'paid'
    AND created_at >= '2025-01-01'::timestamptz
    AND created_at < '2026-01-01'::timestamptz;

\echo '--- Q3 ---'
-- TODO: EXPLAIN (ANALYZE, BUFFERS) ...
EXPLAIN (ANALYZE, BUFFERS)
SELECT oi.product_name, 
       COUNT(DISTINCT o.id) as order_count,
       SUM(oi.quantity) as total_quantity,
       SUM(oi.price * oi.quantity) as total_revenue
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.created_at >= '2025-01-01'
  AND o.created_at < '2025-04-01'
GROUP BY oi.product_name
ORDER BY total_revenue DESC
LIMIT 10;
-- (Опционально) Q4
-- TODO
