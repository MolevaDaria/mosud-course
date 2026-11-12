-- Практическая работа №4. Соединения отношений и сложные JOIN
-- Вариант 6: Повторные покупатели

SET search_path TO olist, public;

-- 1. Основной запрос (минимум 3 таблицы)
-- customers -> orders -> order_items
-- Показываем количество заказов, общее количество купленных товаров
-- и даты первой/последней покупки для каждого уникального клиента.

SELECT 
    c.customer_unique_id,
    count(DISTINCT o.order_id) AS total_orders,       -- уникальные заказы
    count(oi.order_item_id)    AS total_items,        -- общее кол-во товаров
    min(o.order_purchase_timestamp) AS first_purchase,
    max(o.order_purchase_timestamp) AS last_purchase
FROM customers c
JOIN orders o      ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
HAVING count(DISTINCT o.order_id) > 1                 -- только повторные покупатели
ORDER BY total_orders DESC
LIMIT 10;


-- 2. Кратность связей

-- customers -> orders: 1:N (у одного customer_unique_id может быть несколько
--   customer_id, каждый из которых ссылается на заказ; у одного customer_id
--   в Olist обычно один заказ).
-- orders -> order_items: 1:N (в одном заказе несколько позиций).
-- Итоговая связь customers -> order_items через orders: 1:N.


-- 3. LEFT JOIN: сохраняем клиентов без заказов

SELECT 
    c.customer_unique_id,
    count(DISTINCT o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_orders ASC
LIMIT 5;


-- 4. Антисоединение: клиенты без единого заказа

SELECT 
    c.customer_id,
    c.customer_unique_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
LIMIT 10;


-- 5. Намеренно ошибочный JOIN (размножение строк)
-- Прямое соединение orders и order_items без DISTINCT/агрегации
-- завышает count: считаются не заказы, а позиции в заказах.

SELECT 
    c.customer_unique_id,
    count(oi.order_id) AS total_items_in_orders
FROM customers c
JOIN orders o      ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY total_items_in_orders DESC
LIMIT 10;
-- Здесь count(oi.order_id) считает позиции, а не заказы => завышение.


-- 6. Исправление ошибки: предварительная агрегация order_items
-- Сначала агрегируем позиции до уровня заказа, затем соединяем.

WITH order_sums AS (
    SELECT 
        order_id, 
        count(*) AS items_in_order
    FROM order_items
    GROUP BY order_id
)
SELECT 
    c.customer_unique_id,
    count(DISTINCT o.order_id) AS total_orders,
    sum(os.items_in_order)     AS total_items
FROM customers c
JOIN orders o      ON c.customer_id = o.customer_id
JOIN order_sums os ON o.order_id = os.order_id
GROUP BY c.customer_unique_id
ORDER BY total_items DESC
LIMIT 10;
-- Теперь total_orders — реальное число заказов, total_items — сумма позиций.
-- Размножения строк нет.


-- 7. Реляционная алгебра для основного запроса (пункт 1)

-- 1. ρ(c)(customers), ρ(o)(orders), ρ(oi)(order_items)
-- 2. customers ⋈_{customer_id} orders ⋈_{order_id} order_items
-- 3. π(customer_unique_id, order_id, order_item_id,
--      order_purchase_timestamp)
-- 4. γ_{customer_unique_id}(
--      count(DISTINCT order_id) -> total_orders,
--      count(order_item_id)     -> total_items,
--      min(order_purchase_timestamp) -> first_purchase,
--      max(order_purchase_timestamp) -> last_purchase)
-- 5. σ_{total_orders > 1}