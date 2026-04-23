\timing on
\echo '=== PARTITION ORDERS BY DATE ==='

-- ============================================
-- TODO: Реализуйте партиционирование orders по дате
-- ============================================

-- Вариант A (рекомендуется): RANGE по created_at (месяц/квартал)
-- Вариант B: альтернативная разумная стратегия

-- Шаг 1: Подготовка структуры
-- TODO:
-- - создайте partitioned table (или shadow-таблицу для безопасной миграции)
-- - определите partition key = created_at

CREATE TABLE orders_partitioned (
    id UUID,
    user_id UUID,
    status VARCHAR(15), 
    total_amount NUMERIC(15,2),
    created_at TIMESTAMPTZ 
)
PARTITION BY RANGE (created_at);

-- Шаг 2: Создание партиций
-- TODO:
-- - создайте набор партиций по диапазонам дат
-- - добавьте DEFAULT partition (опционально)
-- 2024
CREATE TABLE orders_2024_q1
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_2024_q2
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE orders_2024_q3
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE orders_2024_q4
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

-- 2025
CREATE TABLE orders_2025_q1
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE orders_2025_q2
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

CREATE TABLE orders_2025_q3
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');

CREATE TABLE orders_2025_q4
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');

CREATE TABLE orders_2026_q1
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');

CREATE TABLE orders_default
    PARTITION OF orders_partitioned
    DEFAULT;
-- Шаг 3: Перенос данных
-- TODO:
-- - перенесите данные из исходной таблицы
-- - проверьте количество строк до/после
INSERT INTO  orders_partitioned (id, user_id, status, total_amount, created_at)
SELECT id, user_id, status, total_amount, created_at FROM orders;

-- Шаг 4: Индексы на партиционированной таблице
-- TODO:
-- - создайте нужные индексы (если требуется)

CREATE INDEX idx_orders_user_created
    ON orders USING BTREE (user_id, created_at DESC);

CREATE INDEX idx_orders_paid_created
    ON orders USING BTREE (created_at)
    WHERE status = 'paid';

CREATE INDEX idx_order_items_order_id
    ON order_items USING BTREE (order_id);

-- Шаг 5: Проверка
-- TODO:
-- - ANALYZE
-- - проверка partition pruning на запросах по диапазону дат
ANALYZE orders_partitioned;