-- Практическая работа №4. Соединения отношений и сложные JOIN
-- Вариант 6: Повторные покупатели

SET search_path TO olist, public;


-- 1. Основной запрос (минимум 3 таблицы)
-- Показываем количество заказов у каждого уникального клиента
-- и даты его первой и последней покупки.
SELECT 
    c.customer_unique_id,
    count(o.order_id) AS total_orders,
    min(o.order_purchase_timestamp) AS first_purchase,
    max(o.order_purchase_timestamp) AS last_purchase
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING count(o.order_id) > 1  -- Оставляем только тех, кто покупал больше 1 раза
ORDER BY total_orders DESC
LIMIT 10;

-- 2. Кратность связей для каждого JOIN
-- customers → orders: 1 : N (у одного customer_id может быть только один заказ, 
-- но у одного customer_unique_id может быть несколько customer_id, 
-- каждый из которых ссылается на свой заказ).
-- Значит, customers (по customer_unique_id) 1 : N orders.

-- 3. Добавление LEFT JOIN (объекты без связанных строк)
-- Найдем всех клиентов, даже если у них нет заказов (в Olist таких нет, 
-- но для демонстрации LEFT JOIN это сработает).

SELECT 
    c.customer_unique_id,
    count(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_orders ASC
LIMIT 5;

-- 4. Антисоединение: найти объекты, для которых нет связанной строки
-- Например, клиентов, у которых вообще нет ни одного заказа.

SELECT 
    c.customer_id,
    c.customer_unique_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
LIMIT 10;


-- 5. Намеренно ошибочный JOIN (размножение строк)
-- Если мы попытаемся соединить customers с orders и order_items напрямую,
-- то для каждого заказа с несколькими товарами строка клиента размножится.

SELECT 
    c.customer_unique_id,
    count(oi.order_id) AS total_items_in_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY total_items_in_orders DESC
LIMIT 10;

-- Ошибка здесь: count(oi.order_id) считает не количество заказов, 
-- а количество позиций (товаров) во всех заказах клиента! 
-- Это завышает счетчик.

-- 6. Исправление ошибки (предварительная агрегация)
-- Сначала агрегируем order_items до уровня заказа, 
-- а потом соединяем с клиентами.
WITH order_sums AS (
    SELECT 
        order_id, 
        count(*) AS items_in_order
    FROM order_items
    GROUP BY order_id
)
SELECT 
    c.customer_unique_id,
    count(o.order_id) AS total_orders,
    sum(os.items_in_order) AS total_items
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_sums os ON o.order_id = os.order_id
GROUP BY c.customer_unique_id
ORDER BY total_items DESC
LIMIT 10;
-- Теперь мы корректно получаем количество заказов и сумму товаров, 
-- размножения строк нет.


-- 7. Реляционная алгебра

-- Основной запрос:
-- 1. ρ(c)(customers)
-- 2. ρ(o)(orders)
-- 3. customers ⋈_{customer_id} orders
-- 4. π(customer_unique_id, order_id, order_purchase_timestamp)
-- 5. γ_{customer_unique_id}(count(order_id) → total_orders,
--                          min(order_purchase_timestamp) → first_purchase,
--                          max(order_purchase_timestamp) → last_purchase)
-- 6. σ_{total_orders > 1}
