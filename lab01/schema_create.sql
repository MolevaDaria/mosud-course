-- МОСУД. Практическая работа №1
-- Молева Дарья Андреевна
-- ИНБО-20-23


-- Создание схем.
CREATE SCHEMA IF NOT EXISTS olist;
CREATE SCHEMA IF NOT EXISTS lab;

-- Исходные таблицы набора Olist.
CREATE TABLE IF NOT EXISTS olist.customers (
    customer_id text NOT NULL,
    customer_unique_id text,
    customer_zip_code_prefix integer,
    customer_city text,
    customer_state text
);

CREATE TABLE IF NOT EXISTS olist.geolocation (
    geolocation_zip_code_prefix integer,
    geolocation_lat numeric(12,8),
    geolocation_lng numeric(12,8),
    geolocation_city text,
    geolocation_state text
);

CREATE TABLE IF NOT EXISTS olist.orders (
    order_id text NOT NULL,
    customer_id text NOT NULL,
    order_status text,
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);

CREATE TABLE IF NOT EXISTS olist.order_items (
    order_id text NOT NULL,
    order_item_id integer NOT NULL,
    product_id text NOT NULL,
    seller_id text NOT NULL,
    shipping_limit_date timestamp,
    price numeric(10,2),
    freight_value numeric(10,2)
);

CREATE TABLE IF NOT EXISTS olist.order_payments (
    order_id text NOT NULL,
    payment_sequential integer NOT NULL,
    payment_type text,
    payment_installments integer,
    payment_value numeric(10,2)
);

CREATE TABLE IF NOT EXISTS olist.order_reviews (
    review_id text NOT NULL,
    order_id text NOT NULL,
    review_score smallint,
    review_comment_title text,
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp
);

CREATE TABLE IF NOT EXISTS olist.products (
    product_id text NOT NULL,
    product_category_name text,
    product_name_lenght integer,
    product_description_lenght integer,
    product_photos_qty integer,
    product_weight_g integer,
    product_length_cm integer,
    product_height_cm integer,
    product_width_cm integer
);

CREATE TABLE IF NOT EXISTS olist.sellers (
    seller_id text NOT NULL,
    seller_zip_code_prefix integer,
    seller_city text,
    seller_state text
);

CREATE TABLE IF NOT EXISTS olist.product_category_name_translation (
    product_category_name text NOT NULL,
    product_category_name_english text
);

