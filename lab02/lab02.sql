
-- Практическая работа №2. Множества и мультимножества в SQL
-- Вариант 6: X = 'ES', Y = 'RJ'

SET search_path TO olist, public;

-- 1. Мощности A и B (count(*) vs count(DISTINCT))
SELECT 'A (count *)' AS metric, count(*) AS val
FROM order_items oi
JOIN orders o    ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND c.customer_state = 'ES'
UNION ALL
SELECT 'A (count DISTINCT)', count(DISTINCT oi.product_id)
FROM order_items oi
JOIN orders o    ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND c.customer_state = 'ES'
UNION ALL
SELECT 'B (count *)', count(*)
FROM order_items oi
JOIN orders o    ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ'
UNION ALL
SELECT 'B (count DISTINCT)', count(DISTINCT oi.product_id)
FROM order_items oi
JOIN orders o    ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ';

-- 2. A ∪ B: UNION vs UNION ALL
SELECT 'A U B (UNION)' AS metric, count(*) AS val
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'ES'
  UNION
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ'
) t
UNION ALL
SELECT 'A U B (UNION ALL)', count(*)
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'ES'
  UNION ALL
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ'
) t;

--  3. A ∩ B: INTERSECT
SELECT 'A n B (INTERSECT)' AS metric, count(*) AS val
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'ES'
  INTERSECT
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ'
) t;

-- 4. A − B и B − A: EXCEPT
SELECT 'A - B (EXCEPT)' AS metric, count(*) AS val
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'ES'
  EXCEPT
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ'
) t
UNION ALL
SELECT 'B - A (EXCEPT)', count(*)
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ'
  EXCEPT
  SELECT oi.product_id FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'ES'
) t;

-- 5. Коммутативность
SELECT 'A U B' AS metric, count(*) AS val
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='ES'
  UNION
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='RJ'
) t
UNION ALL
SELECT 'B U A', count(*)
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='RJ'
  UNION
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='ES'
) t
UNION ALL
SELECT 'A n B', count(*)
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='ES'
  INTERSECT
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='RJ'
) t
UNION ALL
SELECT 'B n A', count(*)
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='RJ'
  INTERSECT
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='ES'
) t;

-- 6. Некоммутативность разности (A-B и B-A)
SELECT 'A - B' AS metric, count(*) AS val
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='ES'
  EXCEPT
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='RJ'
) t
UNION ALL
SELECT 'B - A', count(*)
FROM (
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='RJ'
  EXCEPT
  SELECT oi.product_id FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status='delivered' AND c.customer_state='ES'
) t;

-- 7. Пересечение через EXISTS
SELECT 'A n B (EXISTS)' AS metric, count(*) AS val
FROM (
  SELECT DISTINCT a.product_id
  FROM order_items a
  JOIN orders oa    ON oa.order_id = a.order_id
  JOIN customers ca ON ca.customer_id = oa.customer_id
  WHERE oa.order_status = 'delivered' AND ca.customer_state = 'ES'
    AND EXISTS (
      SELECT 1
      FROM order_items b
      JOIN orders ob    ON ob.order_id = b.order_id
      JOIN customers cb ON cb.customer_id = ob.customer_id
      WHERE ob.order_status = 'delivered'
        AND cb.customer_state = 'RJ'
        AND b.product_id = a.product_id
    )
) t;

-- 8. Дубликаты (UNION ALL)
SELECT 'A U B (UNION ALL) с дубликатами' AS metric, count(*) AS val
FROM (
  SELECT oi.product_id
  FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'ES'
  UNION ALL
  SELECT oi.product_id
  FROM order_items oi
  JOIN orders o    ON o.order_id = oi.order_id
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered' AND c.customer_state = 'RJ'
) t;