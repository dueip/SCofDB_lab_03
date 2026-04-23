\timing on
\echo '=== APPLY INDEXES ==='

-- ============================================
-- TODO: Создайте индексы на основе ваших EXPLAIN ANALYZE
-- ============================================

-- Индекс 1
-- TODO:
-- CREATE INDEX ... ON ... USING BTREE (...);
-- Обоснование:
-- - какой запрос ускоряет
-- - почему выбран именно этот тип индекса
CREATE INDEX IF NOT EXISTS idx_orders_user_id_created_at ON orders USING BTREE(user_id, created_at DESC);

-- Индекс 2
-- TODO:
-- CREATE INDEX ... ON ... USING ... (...);
-- Обоснование:
-- - какой запрос ускоряет
-- - почему выбран именно этот тип индекса
CREATE INDEX IF NOT EXISTS idx_orders_paid_created ON orders USING BTREE(created_at) WHERE status = 'paid';

-- Индекс 3
-- TODO:
-- CREATE INDEX ... ON ... USING ... (...);
-- Обоснование:
-- - какой запрос ускоряет
-- - почему выбран именно этот тип индекса
CREATE INDEX idx_order_items_order_id on order_items USING BTREE (order_id)

-- (Опционально) Частичный индекс / BRIN / составной индекс
-- TODO

-- Не забудьте обновить статистику после создания индексов
-- TODO:
-- ANALYZE;
ANALYZE orders;
ANALYZE order_status_history;
ANALYZE order_items;
