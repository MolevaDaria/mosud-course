-- Практическая работа №6. Подзапросы и логика предикатов
-- Вариант 6: Заказы, сумма платежей которых превышает сумму price+freight

SET search_path TO olist, public;


-- 1. Основное решение: скалярный подзапрос + коррелированный EXISTS
SELECT o.order_id
FROM orders o
WHERE EXISTS (
    -- Коррелированный подзапрос: есть ли у заказа платежи
    SELECT 1 FROM order_payments op WHERE op.order_id = o.order_id
)
AND (
    -- Скалярный подзапрос: сумма платежей
    SELECT sum(op.payment_value) 
    FROM order_payments op 
    WHERE op.order_id = o.order_id
) > (
    -- Скалярный подзапрос: сумма price+freight по позициям
    SELECT sum(oi.price + oi.freight_value) 
    FROM order_items oi 
    WHERE oi.order_id = o.order_id
)
ORDER BY o.order_id
LIMIT 10;


-- 2. Альтернатива через CTE с предварительной агрегацией

WITH payments_sum AS (
    SELECT order_id, sum(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
),
items_sum AS (
    SELECT order_id, sum(price + freight_value) AS total_items
    FROM order_items
    GROUP BY order_id
)
SELECT o.order_id
FROM orders o
JOIN payments_sum ps ON o.order_id = ps.order_id
JOIN items_sum ism   ON o.order_id = ism.order_id
WHERE ps.total_payment > ism.total_items
ORDER BY o.order_id
LIMIT 10;


-- 3. Проверка эквивалентности через EXCEPT в обе стороны

WITH res_subquery AS (
    SELECT o.order_id
    FROM orders o
    WHERE EXISTS (SELECT 1 FROM order_payments op WHERE op.order_id = o.order_id)
      AND (SELECT sum(op.payment_value) FROM order_payments op WHERE op.order_id = o.order_id)
        > (SELECT sum(oi.price + oi.freight_value) FROM order_items oi WHERE oi.order_id = o.order_id)
),
res_cte AS (
    WITH payments_sum AS (
        SELECT order_id, sum(payment_value) AS total_payment
        FROM order_payments GROUP BY order_id
    ),
    items_sum AS (
        SELECT order_id, sum(price + freight_value) AS total_items
        FROM order_items GROUP BY order_id
    )
    SELECT o.order_id
    FROM orders o
    JOIN payments_sum ps ON o.order_id = ps.order_id
    JOIN items_sum ism   ON o.order_id = ism.order_id
    WHERE ps.total_payment > ism.total_items
)
SELECT 'Проверка 1: subquery EXCEPT cte' AS test, count(*) AS diff_rows
FROM (
    SELECT order_id FROM res_subquery
    EXCEPT
    SELECT order_id FROM res_cte
) t1
UNION ALL
SELECT 'Проверка 2: cte EXCEPT subquery', count(*)
FROM (
    SELECT order_id FROM res_cte
    EXCEPT
    SELECT order_id FROM res_subquery
) t2;


-- 4. Демонстрация ANY / ALL
-- ANY: заказы, где хотя бы одна позиция дороже 1000
-- ALL: заказы, где все позиции дороже 10 (пример)

-- ANY: заказы, в которых есть позиция дороже 1000
SELECT o.order_id
FROM orders o
WHERE o.order_id = ANY (
    SELECT oi.order_id FROM order_items oi WHERE oi.price > 1000
)
LIMIT 5;

-- ALL: заказы, где минимальная позиция дороже 10 (все позиции > 10)
SELECT o.order_id
FROM orders o
WHERE 10 < ALL (
    SELECT oi.price FROM order_items oi WHERE oi.order_id = o.order_id
)
LIMIT 5;
