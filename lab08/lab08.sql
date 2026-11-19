
-- Практическая работа №8. ER-модель и расширение предметной области
-- Вариант 6: Попытки доставки (shipments, delivery_attempts, delivery_events)

-- Создаем схему lab (если её нет)
CREATE SCHEMA IF NOT EXISTS lab;
SET search_path TO lab, olist, public;


-- 1. Таблица shipments (отправки)

DROP TABLE IF EXISTS lab.delivery_events CASCADE;
DROP TABLE IF EXISTS lab.delivery_attempts CASCADE;
DROP TABLE IF EXISTS lab.shipments CASCADE;

CREATE TABLE lab.shipments (
    shipment_id SERIAL,
    order_id VARCHAR(50) NOT NULL,
    carrier_name VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(50),
    shipped_at TIMESTAMP NOT NULL,
    estimated_delivery_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'created',
    CONSTRAINT pk_shipments PRIMARY KEY (shipment_id),
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id) 
        REFERENCES olist.orders(order_id) ON DELETE CASCADE,
    CONSTRAINT uq_shipments_tracking UNIQUE (tracking_number),
    CONSTRAINT ck_shipments_status CHECK (status IN 
        ('created', 'in_transit', 'delivered', 'failed'))
);


-- 2. Таблица delivery_attempts (попытки доставки)

CREATE TABLE lab.delivery_attempts (
    attempt_id SERIAL,
    shipment_id INT NOT NULL,
    attempt_number INT NOT NULL,
    attempted_at TIMESTAMP NOT NULL,
    result VARCHAR(20) NOT NULL,
    failure_reason VARCHAR(200),
    CONSTRAINT pk_delivery_attempts PRIMARY KEY (attempt_id),
    CONSTRAINT fk_delivery_attempts_shipment FOREIGN KEY (shipment_id) 
        REFERENCES lab.shipments(shipment_id) ON DELETE CASCADE,
    CONSTRAINT uq_delivery_attempts_shipment_number UNIQUE (shipment_id, attempt_number),
    CONSTRAINT ck_delivery_attempts_result CHECK (result IN 
        ('success', 'failed', 'rescheduled')),
    CONSTRAINT ck_delivery_attempts_attempt_number CHECK (attempt_number > 0)
);


-- 3. Таблица delivery_events (события доставки)

CREATE TABLE lab.delivery_events (
    event_id SERIAL,
    shipment_id INT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_time TIMESTAMP NOT NULL,
    location VARCHAR(200),
    notes TEXT,
    CONSTRAINT pk_delivery_events PRIMARY KEY (event_id),
    CONSTRAINT fk_delivery_events_shipment FOREIGN KEY (shipment_id) 
        REFERENCES lab.shipments(shipment_id) ON DELETE CASCADE,
    CONSTRAINT ck_delivery_events_type CHECK (event_type IN 
        ('picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'failed'))
);


-- 4. Тестовые данные (5 строк в каждой таблице)
-- Берем реальные order_id из Olist

INSERT INTO lab.shipments (order_id, carrier_name, tracking_number, shipped_at, estimated_delivery_date, status)
SELECT order_id, 'Carrier A', 'TRK001', '2018-01-01 10:00:00', '2018-01-10', 'delivered'
FROM olist.orders LIMIT 1;

INSERT INTO lab.shipments (order_id, carrier_name, tracking_number, shipped_at, estimated_delivery_date, status)
SELECT order_id, 'Carrier B', 'TRK002', '2018-02-01 11:00:00', '2018-02-15', 'in_transit'
FROM olist.orders OFFSET 1 LIMIT 1;

INSERT INTO lab.shipments (order_id, carrier_name, tracking_number, shipped_at, estimated_delivery_date, status)
SELECT order_id, 'Carrier C', 'TRK003', '2018-03-01 12:00:00', '2018-03-20', 'failed'
FROM olist.orders OFFSET 2 LIMIT 1;

INSERT INTO lab.shipments (order_id, carrier_name, tracking_number, shipped_at, estimated_delivery_date, status)
SELECT order_id, 'Carrier A', 'TRK004', '2018-04-01 13:00:00', '2018-04-10', 'delivered'
FROM olist.orders OFFSET 3 LIMIT 1;

INSERT INTO lab.shipments (order_id, carrier_name, tracking_number, shipped_at, estimated_delivery_date, status)
SELECT order_id, 'Carrier B', 'TRK005', '2018-05-01 14:00:00', '2018-05-25', 'created'
FROM olist.orders OFFSET 4 LIMIT 1;

INSERT INTO lab.delivery_attempts (shipment_id, attempt_number, attempted_at, result, failure_reason)
VALUES 
    (1, 1, '2018-01-05 10:00:00', 'success', NULL),
    (2, 1, '2018-02-05 11:00:00', 'failed', 'Nobody at home'),
    (2, 2, '2018-02-06 11:00:00', 'rescheduled', 'Nobody at home'),
    (3, 1, '2018-03-05 12:00:00', 'failed', 'Wrong address'),
    (4, 1, '2018-04-05 13:00:00', 'success', NULL);

INSERT INTO lab.delivery_events (shipment_id, event_type, event_time, location, notes)
VALUES 
    (1, 'picked_up', '2018-01-02 09:00:00', 'Warehouse A', 'Picked up'),
    (1, 'delivered', '2018-01-05 10:00:00', 'Customer address', 'Delivered'),
    (2, 'in_transit', '2018-02-03 09:00:00', 'Hub B', 'In transit'),
    (3, 'failed', '2018-03-05 12:00:00', 'Wrong address', 'Returned to sender'),
    (4, 'out_for_delivery', '2018-04-05 08:00:00', 'Local hub', 'Out for delivery');


-- 5. Демонстрация отклонения ошибочных INSERT
-- (используем DO-блок для перехвата исключений)

DO $$
BEGIN
    -- 1) Некорректный статус (нарушение ck_shipments_status)
    BEGIN
        INSERT INTO lab.shipments (order_id, carrier_name, shipped_at, status)
        SELECT order_id, 'X', now(), 'invalid_status' FROM olist.orders LIMIT 1;
        RAISE NOTICE 'Ошибка: INSERT с неверным статусом прошёл!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: ck_shipments_status отклонил неверный статус';
    END;

    -- 2) Дубликат tracking_number (нарушение uq_shipments_tracking)
    BEGIN
        INSERT INTO lab.shipments (order_id, carrier_name, tracking_number, shipped_at)
        SELECT order_id, 'X', 'TRK001', now() FROM olist.orders LIMIT 1;
        RAISE NOTICE 'Ошибка: дубликат tracking_number прошёл!';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'OK: uq_shipments_tracking отклонил дубликат tracking_number';
    END;

    -- 3) Дубликат (shipment_id, attempt_number) в delivery_attempts
    BEGIN
        INSERT INTO lab.delivery_attempts (shipment_id, attempt_number, attempted_at, result)
        VALUES (1, 1, now(), 'success');
        RAISE NOTICE 'Ошибка: дубликат attempt_number прошёл!';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'OK: uq_delivery_attempts_shipment_number отклонил дубликат';
    END;

    -- 4) Негативный attempt_number (нарушение ck_delivery_attempts_attempt_number)
    BEGIN
        INSERT INTO lab.delivery_attempts (shipment_id, attempt_number, attempted_at, result)
        VALUES (1, -1, now(), 'failed');
        RAISE NOTICE 'Ошибка: отрицательный attempt_number прошёл!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: ck_delivery_attempts_attempt_number отклонил негативное значение';
    END;

    -- 5) Некорректный event_type (нарушение ck_delivery_events_type)
    BEGIN
        INSERT INTO lab.delivery_events (shipment_id, event_type, event_time)
        VALUES (1, 'unknown_event', now());
        RAISE NOTICE 'Ошибка: неверный event_type прошёл!';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: ck_delivery_events_type отклонил неверный тип';
    END;
END $$;


-- 6. Проверка схемы через information_schema

SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'lab'
ORDER BY table_name, ordinal_position;


-- 7. Проверка ограничений через pg_catalog

SELECT 
    conrelid::regclass AS table_name,
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE connamespace = 'lab'::regnamespace
ORDER BY table_name, constraint_name;