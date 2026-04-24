# Отчёт по лабораторной работе №3
## Диагностика и оптимизация маркетплейса

**Студент:** _[Воеводин Егор Олегович]_  
**Группа:** _[БПМ-22-ПО-3]_  
**Дата:** _[22.04.26]_

## 1. Исходные данные
### 1.1 Использованная схема
Использовалась схема backend/migrations/001_init.sql. Коммит: https://github.com/dueip/SCofDB_lab_03/commit/1dc6a829fb59e687e14db09fffd97783208e7932#diff-6758c10af666a9e6b8aca38f0a93d1a5947773650c1255e3b8deeb71cda434cc

### 1.2 Объём данных
      table_name      | rows_count
----------------------+------------
 users                |      10000
 orders               |     100000
 order_status_history |     199904
 order_items          |     400000

## 2. Найденные медленные запросы (до оптимизации)
_TODO: Укажите не менее 3 запросов, которые вы считаете медленными._

Для каждого запроса:
1. SQL текста запроса;
2. план `EXPLAIN ANALYZE` (кратко: ключевые узлы);
3. `Execution Time`;
4. почему запрос медленный.

### Запрос №1
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, status, total_amount, created_at
FROM orders
WHERE user_id = (SELECT id FROM users WHERE email = 'user00001@example.com')  and status = 'paid'
ORDER by created_at DESC
LIMIT 20;

Почему медленный:
- Подзапрос по всей таблице для поиска айдишника
- Полный просмотр таблицы ордерс при каждом обращении

### Запрос №2
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, total_amount, created_at
FROM orders
WHERE status = 'paid'
    AND created_at >= '2025-01-01'::timestamptz
    AND created_at < '2026-01-01'::timestamptz;

Почему медленный:
- Целый год запросов. Очень много строк

### Запрос №3
EXPLAIN (ANALYZE, BUFFERS)
SELECT oi.product_name, 
       COUNT(DISTINCT o.id) as order_count,
       SUM(oi.quantity) as sum_quantity,
       SUM(oi.price * oi.quantity) as sum_revenue 
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.created_at >= '2025-01-01'::timestamptz
  AND o.created_at < '2026-01-01'::timestamptz
GROUP BY oi.product_name
ORDER BY sum_revenue DESC
LIMIT 30;

Почему медленный:
- Целый год запросов. Очень много строк.
- Требуется агрегация всего результата джойна

## 3. Добавленные индексы и обоснование типа
_TODO: Для каждого добавленного индекса опишите, почему выбран именно этот тип (`BTREE`, `BRIN`, `GIN`, partial и т.д.)._

### Индекс №1
- SQL: CREATE INDEX IF NOT EXISTS idx_orders_user_id_created_at ON orders USING BTREE(user_id, status, created_at DESC);
- Какой запрос ускоряет: Q1
- Почему выбран тип: Упорядоченная структура для created_at

### Индекс №2
- SQL: CREATE INDEX idx_orders_paid_created ON orders USING BTREE(created_at) WHERE status = 'paid';
- Какой запрос ускоряет: Q2 & Q3 из-за фильтрации
- Почему выбран тип: Требуется упорядоченная структура для created_at.

### Индекс №3
- SQL: CREATE INDEX idx_order_items_order_id ON order_items USING BTREE(order_id);
- Какой запрос ускоряет: Q3
- Почему выбран тип: С этим индексом Q3 не будет перечитывать всю таблицу order_items каждый раз

## 4. Замеры до/после индексов
_TODO: Заполните таблицу или список сравнений._

Пример формата:
- Query 1: до 10.921 ms, после 3.394 ms, ускорение x 3.218
- Query 2: до 17.475 ms, после 14.662 ms, ускорение x 1.192
- Query 3: до 1249.854 ms, после 405.661 ms, ускорение x 3.081

## 5. Партиционирование `orders` по дате
### 5.1 Выбранная стратегия
Разбили на range по кварталям (потому что так меньше копировать)

### 5.2 Реализация
Создали
CREATE TABLE orders_partitioned (
    id UUID,
    user_id UUID,
    status VARCHAR(15), 
    total_amount NUMERIC(15,2),
    created_at TIMESTAMPTZ 
)
PARTITION BY RANGE (created_at);

И дальше просто
CREATE TABLE orders_2024_q1
    PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
И так далее

### 5.3 Проверка эффекта
Немного изменились Q2 и Q3 в лучшую сторону, Q1 хуже чем на индексах (но лучше чем без всего)

## 6. Итоговые замеры (после партиционирования)
- Query 1: до 10.921 ms, после индексов 3.394 ms, после партиции 4.588
- Query 2: до 17.475 ms, после индексов 14.662 ms, после партиции 13.453
- Query 3: до 1249.854 ms, после индексов 405.661 ms, после партиции 366.706

## 7. Что удалось исправить
Все три запроса улучшишлись. Заметно улучились только Q1 & Q3. Достигнуто это тем, что индексы позволили вместо полного сканирования просто пробегаться по дате и статусу. В Q3 получилось оптимизировать операцию JOIN, однако теперь ботлнек висит в SORT.

## 8 . Что не удалось исправить только индексами
Q2, значения остались примерно на том же уровне из-за большого количества строк.
Q3 все еще достаточно медленный. Для решения нужно каким-то образом избавиться от SORT, с чем вряд ли помогут индексы
Подсказки:
- full scan при высокой доле выбираемых строк;
- тяжёлые `GROUP BY`/`ORDER BY` на большом объёме;
- необходимость переписывания запроса или pre-aggregation.

## 9. Выводы
1) Для диагностики sql запросов есть очень удобная команда ANALYZE, которая выводит буквально все о query
```
 Bitmap Heap Scan on orders  (cost=853.17..3347.73 rows=25061 width=47) (actual time=3.578..12.131 rows=25157 loops=1)
   Recheck Cond: ((created_at >= '2025-01-01 00:00:00+00'::timestamp with time zone) AND (created_at < '2026-01-01 00:00:00+00'::timestamp with time zone) AND ((status)::text = 'paid'::text))
   Heap Blocks: exact=1073
   Buffers: shared hit=1224
   ->  Bitmap Index Scan on idx_orders_paid_created  (cost=0.00..846.90 rows=25061 width=0) (actual time=3.322..3.323 rows=25157 loops=1)
         Index Cond: ((created_at >= '2025-01-01 00:00:00+00'::timestamp with time zone) AND (created_at < '2026-01-01 00:00:00+00'::timestamp with time zone))
         Buffers: shared hit=151
 Planning:
   Buffers: shared hit=3
 Planning Time: 0.168 ms
 Execution Time: 13.545 ms
(11 rows)

Time: 14.662 ms
```
2) Индексы -- очень полезная вещь, позволяющая оптимизировать запросы, однако она не является таблеткой для всех прроблем. Все равно требуется оптимизировать запросы 
3) Partitioning -- полезный инструмент, однако на данных запросах он не смог показать себя полность. 

