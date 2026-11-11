
-- Практическая работа №3. Выборка, проекция, переименование
-- Вариант 6: order_reviews

SET search_path TO olist, public;

-- 1-3. Исходное выражение реляционной алгебры в SQL

SELECT order_id, 
       review_score, 
       review_comment_message
FROM order_reviews
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL
LIMIT 5;

-- Проверяем общее количество строк в исходном запросе
SELECT count(*) AS cnt_original
FROM order_reviews
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL;

-- 4. Разбиение сложного предиката на две последовательные выборки
SELECT order_id, 
       review_score, 
       review_comment_message
FROM (
    SELECT order_id, 
           review_score, 
           review_comment_message
    FROM order_reviews
    WHERE review_score <= 2
) AS step1
WHERE review_comment_message IS NOT NULL
LIMIT 5;

-- Сравниваем количество строк (должно совпадать с cnt_original)
SELECT count(*) AS cnt_split
FROM (
    SELECT order_id, 
           review_score, 
           review_comment_message
    FROM order_reviews
    WHERE review_score <= 2
) AS step1
WHERE review_comment_message IS NOT NULL;

-- 5. Второй вариант: исключение ненужных столбцов раньше
SELECT order_id, 
       review_score, 
       review_comment_message
FROM (
    SELECT order_id, 
           review_score, 
           review_comment_message
    FROM order_reviews
) AS projected
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL
LIMIT 5;

-- Сравниваем количество строк (должно совпадать с cnt_original)
SELECT count(*) AS cnt_early_projection
FROM (
    SELECT order_id, 
           review_score, 
           review_comment_message
    FROM order_reviews
) AS projected
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL;

-- 6. Проверка на дубликаты (Сводка)
-- Выводим 4 числа:
-- total_rows - сколько строк вернул бы обычный SELECT
-- distinct_rows - сколько уникальных строк (эквивалент математической проекции)
-- has_duplicates - если total > distinct, то дубликаты есть
SELECT 
    count(*) AS total_rows,
    count(DISTINCT (order_id, review_score, review_comment_message)) AS distinct_rows,
    CASE 
        WHEN count(*) > count(DISTINCT (order_id, review_score, review_comment_message)) 
        THEN 'YES' ELSE 'NO' 
    END AS has_duplicates
FROM order_reviews
WHERE review_score <= 2 
  AND review_comment_message IS NOT NULL;