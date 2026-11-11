-- ============================================================
-- Практическая работа №5. Кванторы, EXISTS и реляционное деление
-- Вариант 6: S = {PA, AM, RO}
-- ============================================================

SET search_path TO olist, public;

-- ============================================================
-- 2. Реализация через двойной NOT EXISTS
-- ============================================================
WITH target_states AS (
    SELECT 'PA' AS state UNION ALL SELECT 'AM' UNION ALL SELECT 'RO'
)
SELECT DISTINCT '2. NOT EXISTS' AS method, p.product_category_name
FROM products p
WHERE p.product_category_name IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM target_states ts
      WHERE NOT EXISTS (
          SELECT 1 
          FROM customers c
          JOIN orders o ON c.customer_id = o.customer_id
          JOIN order_items oi ON o.order_id = oi.order_id
          JOIN products p2 ON oi.product_id = p2.product_id
          WHERE o.order_status = 'delivered'
            AND c.customer_state = ts.state
            AND p2.product_category_name = p.product_category_name
      )
  )
ORDER BY p.product_category_name
LIMIT 10;

-- ============================================================
-- 3. Реализация через GROUP BY / HAVING COUNT(DISTINCT)
-- ============================================================
WITH target_states AS (
    SELECT 'PA' AS state UNION ALL SELECT 'AM' UNION ALL SELECT 'RO'
)
SELECT DISTINCT '3. GROUP BY/HAVING' AS method, p.product_category_name
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN target_states ts ON c.customer_state = ts.state
WHERE o.order_status = 'delivered'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
HAVING count(DISTINCT c.customer_state) = (SELECT count(*) FROM target_states)
ORDER BY p.product_category_name
LIMIT 10;

-- ============================================================
-- 4. Реализация через EXCEPT
-- (Исправлено: оба SELECT возвращают ровно один столбец с одинаковым именем)
-- ============================================================
WITH target_states AS (
    SELECT 'PA' AS state UNION ALL SELECT 'AM' UNION ALL SELECT 'RO'
),
all_categories AS (
    SELECT DISTINCT p.product_category_name
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
),
bad_categories AS (
    SELECT DISTINCT p.product_category_name
    FROM products p
    WHERE p.product_category_name IS NOT NULL
      AND EXISTS (
          SELECT 1 FROM target_states ts
          WHERE NOT EXISTS (
              SELECT 1 
              FROM customers c
              JOIN orders o ON c.customer_id = o.customer_id
              JOIN order_items oi ON o.order_id = oi.order_id
              JOIN products p2 ON oi.product_id = p2.product_id
              WHERE o.order_status = 'delivered'
                AND c.customer_state = ts.state
                AND p2.product_category_name = p.product_category_name
          )
      )
)
SELECT '4. EXCEPT' AS method, product_category_name FROM (
    SELECT product_category_name FROM all_categories
    EXCEPT
    SELECT product_category_name FROM bad_categories
) result
ORDER BY product_category_name
LIMIT 10;

-- ============================================================
-- 5. Проверка эквивалентности (NOT EXISTS vs HAVING)
-- ============================================================
WITH target_states AS (
    SELECT 'PA' AS state UNION ALL SELECT 'AM' UNION ALL SELECT 'RO'
),
res_not_exists AS (
    SELECT DISTINCT p.product_category_name
    FROM products p
    WHERE p.product_category_name IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM target_states ts
          WHERE NOT EXISTS (
              SELECT 1 FROM customers c
              JOIN orders o ON c.customer_id = o.customer_id
              JOIN order_items oi ON o.order_id = oi.order_id
              JOIN products p2 ON oi.product_id = p2.product_id
              WHERE o.order_status = 'delivered'
                AND c.customer_state = ts.state
                AND p2.product_category_name = p.product_category_name
          )
      )
),
res_having AS (
    SELECT p.product_category_name
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN target_states ts ON c.customer_state = ts.state
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
    GROUP BY p.product_category_name
    HAVING count(DISTINCT c.customer_state) = (SELECT count(*) FROM target_states)
)
SELECT 'Проверка 1: NOT EXISTS EXCEPT HAVING' AS test, count(*) AS diff_rows
FROM (
    SELECT product_category_name FROM res_not_exists
    EXCEPT
    SELECT product_category_name FROM res_having
) t1
UNION ALL
SELECT 'Проверка 2: HAVING EXCEPT NOT EXISTS', count(*)
FROM (
    SELECT product_category_name FROM res_having
    EXCEPT
    SELECT product_category_name FROM res_not_exists
) t2;

-- ============================================================
-- 6. Диагностическая таблица для одной категории
-- ============================================================
WITH target_states AS (
    SELECT 'PA' AS state UNION ALL SELECT 'AM' UNION ALL SELECT 'RO'
),
one_category AS (
    SELECT 'beleza_saude'::varchar AS product_category_name
)
SELECT 
    oc.product_category_name AS category,
    ts.state,
    count(DISTINCT o.order_id) AS order_count
FROM one_category oc
CROSS JOIN target_states ts
LEFT JOIN customers c ON c.customer_state = ts.state
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status = 'delivered'
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id AND p.product_category_name = oc.product_category_name
WHERE p.product_id IS NOT NULL
GROUP BY oc.product_category_name, ts.state
ORDER BY ts.state;

-- ============================================================
-- 7. Проверка пустого делителя (Vacuous Truth)
-- Мы используем CROSS JOIN с пустым CTE, чтобы PostgreSQL не оптимизировал 
-- запрос и позволил продемонстрировать логику.
-- ============================================================
WITH empty_states AS (
    SELECT state FROM (
        SELECT 'XX' AS state UNION ALL SELECT 'YY' UNION ALL SELECT 'ZZ'
    ) AS sub
    WHERE FALSE  -- <-- Принудительно делаем множество ПУСТЫМ!
)
SELECT '7. Пустой делитель (NOT EXISTS)' AS test, count(*) AS total_categories_found
FROM products p
WHERE p.product_category_name IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM empty_states ts
      WHERE NOT EXISTS (
          SELECT 1 
          FROM customers c
          JOIN orders o ON c.customer_id = o.customer_id
          JOIN order_items oi ON o.order_id = oi.order_id
          JOIN products p2 ON oi.product_id = p2.product_id
          WHERE o.order_status = 'delivered'
            AND c.customer_state = ts.state
            AND p2.product_category_name = p.product_category_name
      )
  );

-- ============================================================
-- 8. Продавцы, продававшие товары в каждый из 3 штатов
-- ============================================================
WITH target_states AS (
    SELECT 'PA' AS state UNION ALL SELECT 'AM' UNION ALL SELECT 'RO'
)
SELECT '8. Продавцы во всех 3 штатах' AS metric, s.seller_id
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN target_states ts ON c.customer_state = ts.state
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
HAVING count(DISTINCT c.customer_state) = (SELECT count(*) FROM target_states)
ORDER BY s.seller_id
LIMIT 10;