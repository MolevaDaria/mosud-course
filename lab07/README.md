# Практическая работа № 7. NULL, трёхзначная логика и качество данных

## 1. Число NULL по столбцам
| Таблица | Столбец | Число NULL |
|---|---|---|
| orders | order_delivered_customer_date | 2965 |
| orders | order_approved_at | 160 |
| orders | order_delivered_carrier_date | 1783 |
| products | product_category_name | 610 |
| products | product_name_lenght | 610 |
| products | product_description_lenght | 610 |
| order_reviews | review_comment_message | 58247 |
| order_reviews | review_comment_title | 87656 |

## 2. COUNT(*) vs COUNT(column)
`COUNT(*)` = 99441 (все строки), `COUNT(order_delivered_customer_date)` = 96476 (только не-NULL).
Разница 2965 — это заказы без фактической даты доставки.

## 3. = NULL и <> NULL
Оба запроса вернули **0 строк**. Сравнение с NULL даёт UNKNOWN, а `WHERE` пропускает только TRUE. 
Исправление: `IS NULL` (2965) и `IS NOT NULL` (96476).

## 4. IS DISTINCT FROM
`NULL IS DISTINCT FROM NULL` → **false**; `NULL IS DISTINCT FROM 'X'` → **true**.
Это безопасный способ сравнения с NULL без трёхзначной логики.

## 5. NOT IN vs NOT EXISTS
`NOT IN` с NULL в подзапросе вернул **0 строк** (предикат стал UNKNOWN для всех строк).
`NOT EXISTS` вернул **99440** строк — корректный антисоединение. 
Вывод: для антисоединений безопаснее `NOT EXISTS`.

## 6. LEFT JOIN: фильтр в ON vs WHERE
- Фильтр в `ON`: **99791** строк — все заказы сохранены, у заказов без отзывов `review_score` = NULL.
- Фильтр в `WHERE`: **76470** строк — `LEFT JOIN` превратился в `INNER JOIN`, заказы без отзывов отсечены.

## 7. COALESCE и NULLIF
`COALESCE(review_comment_message, '(нет комментария)')` заменяет NULL на текст.
`NULLIF(sum(freight_value), 0)` защищает от деления на ноль.

## 8. Профиль качества
- Доля заказов без фактической даты доставки: **2.98%**
- Доля товаров без категории: **1.85%**
- Доля отзывов без текста: **58.70%**

## 9. Естественный NULL vs проблема качества
- **Естественный NULL**: `order_delivered_customer_date` — заказ может быть ещё не доставлен, это нормальное состояние.
- **Проблема качества**: `product_category_name` — отсутствие категории у товара скорее указывает на ошибку в каталоге, чем на естественное состояние.

## Контрольные вопросы
1. **Почему NULL = NULL не даёт TRUE?**
   NULL означает «неизвестное значение». Сравнение двух неизвестных не может быть определено как истинное — результат UNKNOWN.
2. **Как предикат в WHERE влияет на строки, созданные внешним соединением?**
   `WHERE` фильтрует строки **после** соединения. Если в `WHERE` стоит условие на правую таблицу (`r.review_score >= 4`), строки с NULL справа отбрасываются, и `LEFT JOIN` фактически становится `INNER JOIN`.
3. **Почему NOT EXISTS устойчивее NOT IN при возможных NULL?**
   `NOT IN` с NULL в подзапросе даёт UNKNOWN для всех строк (потому что `x <> NULL` = UNKNOWN), и результат становится пустым. `NOT EXISTS` проверяет наличие строк и не зависит от NULL в значениях.
