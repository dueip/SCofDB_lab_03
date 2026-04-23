\timing on
\echo '=== BEFORE OPTIMIZATION ==='

-- Рекомендуемые настройки для сравнимых замеров
SET max_parallel_workers_per_gather = 0;
SET work_mem = '32MB';
ANALYZE;

-- ============================================
-- TODO: Добавьте не менее 3 запросов
-- Для каждого обязательно: EXPLAIN (ANALYZE, BUFFERS)
-- ============================================

\echo '--- Q1: Фильтрация + сортировка (пример класса запроса) ---'
-- TODO: Подставьте свой запрос
-- Пример класса:
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT ...
-- FROM orders
-- WHERE ...
-- ORDER BY created_at DESC
-- LIMIT ...;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, status, total_amount, created_at
FROM orders
WHERE user_id = (SELECT id FROM users WHERE email = 'user00001@example.com')  and status = 'paid'
ORDER by created_at DESC
LIMIT 20;

\echo '--- Q2: Фильтрация по статусу + диапазону дат ---'
-- TODO: Подставьте свой запрос
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT ...
-- FROM orders
-- WHERE status = 'paid'
--   AND created_at >= ...
--   AND created_at < ...;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, total_amount, created_at
FROM orders
WHERE status = 'paid'
    AND created_at >= '2025-01-01'::timestamptz
    AND created_at < '2026-01-01'::timestamptz;
\echo '--- Q3: JOIN + GROUP BY ---'
-- TODO: Подставьте свой запрос
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT ...
-- FROM orders o
-- JOIN order_items oi ON oi.order_id = o.id
-- WHERE ...
-- GROUP BY ...
-- ORDER BY ...
-- LIMIT ...;
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

-- (Опционально) Q4: полный агрегат по периоду, который сложно ускорить индексами
