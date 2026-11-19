
-- Практическая работа №7. NULL, трёхзначная логика и качество данных

SET search_path TO olist, public;


-- 1. Число NULL по потенциально необязательным столбцам

SELECT 
    'orders' AS table_name,
    count(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_delivered_date,
    count(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    count(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier_date
FROM orders
UNION ALL
SELECT 
    'products',
    count(*) FILTER (WHERE product_category_name IS NULL),
    count(*) FILTER (WHERE product_name_lenght IS NULL),
    count(*) FILTER (WHERE product_description_lenght IS NULL)
FROM products
UNION ALL
SELECT 
    'order_reviews',
    count(*) FILTER (WHERE review_comment_message IS NULL),
    count(*) FILTER (WHERE review_comment_title IS NULL),
    count(*) FILTER (WHERE review_id IS NULL)
FROM order_reviews;


-- 2. COUNT(*) vs COUNT(order_delivered_customer_date)

SELECT 
    count(*) AS total_rows,
    count(order_delivered_customer_date) AS non_null_delivered,
    count(*) - count(order_delivered_customer_date) AS null_delivered
FROM orders;


-- 3. = NULL и <> NULL не работают

-- Неправильно (вернет 0 строк):
SELECT count(*) FROM orders WHERE order_delivered_customer_date = NULL;
SELECT count(*) FROM orders WHERE order_delivered_customer_date <> NULL;

-- Правильно:
SELECT count(*) AS null_count 
FROM orders 
WHERE order_delivered_customer_date IS NULL;

SELECT count(*) AS not_null_count 
FROM orders 
WHERE order_delivered_customer_date IS NOT NULL;


-- 4. IS DISTINCT FROM

SELECT 
    NULL IS DISTINCT FROM NULL AS null_vs_null,       -- false
    NULL IS DISTINCT FROM 'X' AS null_vs_x,           -- true
    'X' IS DISTINCT FROM NULL AS x_vs_null,           -- true
    'X' IS DISTINCT FROM 'X' AS x_vs_x;               -- false


-- 5. Временная таблица temp_ids и сравнение NOT IN vs NOT EXISTS

CREATE TEMP TABLE temp_ids(id text);
INSERT INTO temp_ids(id)
SELECT order_id FROM orders LIMIT 1;   -- существующий
INSERT INTO temp_ids(id) VALUES (NULL); -- NULL

-- NOT IN: вернет 0 строк из-за NULL в подзапросе!
SELECT count(*) AS not_in_result
FROM orders
WHERE order_id NOT IN (SELECT id FROM temp_ids);

-- NOT EXISTS: корректно работает с NULL
SELECT count(*) AS not_exists_result
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM temp_ids t WHERE t.id = o.order_id);

DROP TABLE temp_ids;


-- 6. LEFT JOIN с фильтром в ON vs WHERE

-- Фильтр в ON: сохраняются все заказы, но review_score = NULL
-- для тех, у кого нет отзывов >= 4
SELECT count(*) AS filter_in_on
FROM orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id AND r.review_score >= 4;

-- Фильтр в WHERE: LEFT JOIN превращается в INNER JOIN
SELECT count(*) AS filter_in_where
FROM orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE r.review_score >= 4;


-- 7. COALESCE и NULLIF

-- COALESCE: заменяем NULL-комментарий на '(нет комментария)'
SELECT order_id, 
       COALESCE(review_comment_message, '(нет комментария)') AS safe_comment
FROM order_reviews
LIMIT 5;

-- NULLIF: безопасное деление (защита от деления на 0)
SELECT 
    sum(price) / NULLIF(sum(freight_value), 0) AS safe_ratio
FROM order_items;


-- 8. Мини-профиль качества

SELECT
    round(100.0 * count(*) FILTER (WHERE order_delivered_customer_date IS NULL) / count(*), 2) 
        AS pct_orders_without_delivery,
    (SELECT round(100.0 * count(*) FILTER (WHERE product_category_name IS NULL) / count(*), 2)
     FROM products) 
        AS pct_products_without_category,
    (SELECT round(100.0 * count(*) FILTER (WHERE review_comment_message IS NULL) / count(*), 2)
     FROM order_reviews) 
        AS pct_reviews_without_text
FROM orders;


-- 9. Столбцы с естественным NULL vs проблемой качества

-- Естественный NULL: order_delivered_customer_date (заказ может быть ещё не доставлен)
-- Проблема качества: product_category_name (отсутствие категории у товара — 
--   это скорее ошибка каталога, чем норма)
