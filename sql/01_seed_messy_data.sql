-- PostgreSQL 15+ | Demo schema only. Re-runnable and intentionally unconstrained.
-- No production data: all names and contacts are fictional.
BEGIN;
DROP SCHEMA IF EXISTS dq_portfolio CASCADE;
CREATE SCHEMA dq_portfolio;
SET search_path TO dq_portfolio;

-- row_id is a staging/import identifier, not the customer's business key.
-- Do NOT add a UNIQUE/NOT NULL constraint to customer_id or email here:
-- preserving bad source records is necessary for profiling and audit.
CREATE TABLE customers_raw (
    row_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    updated_at TIMESTAMPTZ NOT NULL,
    source_system TEXT NOT NULL
);
CREATE TABLE orders_raw (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    total_gbp NUMERIC(10, 2) NOT NULL CHECK (total_gbp >= 0),
    ordered_at DATE NOT NULL
    -- No FK in raw staging: otherwise we could not demonstrate orphaned imports.
);

INSERT INTO customers_raw VALUES
(1,1001,'  Amina Yusuf  ','AMINA@EXAMPLE.COM ','07111 222 333','2026-11-01 09:00+00','CRM'),
(2,1001,'Amina Yusuf','amina@example.com','07111222333','2026-11-05 09:00+00','Billing'),
(3,1002,'Ben Carter',NULL,'07111 222 334','2026-11-03 09:00+00','CRM'),
(4,1003,'Cleo Ng','cleo@example.com',NULL,'2026-11-07 09:00+00','CRM'),
(5,1004,'    ','DAN@EXAMPLE.COM','07111 222 335','2026-11-08 09:00+00','Legacy'),
(6,NULL,'Ellie Watts','ellie@example.com',NULL,'2026-11-09 09:00+00','Legacy'),
(7,1005,'Fran Hill','fran@example.com','07111 222 336','2026-11-02 09:00+00','CRM'),
(8,1006,'Fran Hill',' FRAN@EXAMPLE.COM ','07111 222 336','2026-11-10 09:00+00','Billing'),
(9,1007,'Gus Li','not-an-email','07111 222 337','2026-11-06 09:00+00','CRM'),
(10,1008,'Hana Reed','hana@example.com','07111 222 338','2026-11-11 09:00+00','CRM'),
(11,1009,'Ibrahim Khan','ibrahim@example.com',NULL,'2026-11-12 09:00+00','CRM'),
(12,1010,'Iris Moore','iris@example.com','07111 222 339','2026-11-13 09:00+00','CRM');

INSERT INTO orders_raw VALUES
(5001,1001,120.00,'2026-11-04'),
(5002,1002, 52.50,'2026-11-05'),
(5003,9999, 99.00,'2026-11-06'),  -- references a non-existent customer
(5004,NULL, 27.99,'2026-11-07'),  -- missing foreign key
(5005,1003, 78.20,'2026-11-08'),
(5006,1005, 15.00,'2026-11-09'),
(5007,1006, 41.00,'2026-11-10'),
(5008,1010,210.00,'2026-11-11');
COMMIT;
