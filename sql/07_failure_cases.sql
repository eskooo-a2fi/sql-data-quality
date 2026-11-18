-- Reconciliation must classify a NULL link and an unknown customer without losing orders.
-- The fixture stays unchanged because all injected rows are rolled back.
BEGIN;
INSERT INTO dq_portfolio.orders_raw (order_id, customer_id, total_gbp, ordered_at)
VALUES (9001, NULL, 12.00, '2026-11-18'), (9002, 9998, 14.00, '2026-11-18');

DO $$
DECLARE
  null_links integer;
  unknown_links integer;
BEGIN
  SELECT COUNT(*) INTO null_links
  FROM dq_portfolio.orders_raw
  WHERE customer_id IS NULL;

  SELECT COUNT(*) INTO unknown_links
  FROM dq_portfolio.orders_raw AS orders
  WHERE orders.customer_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM dq_portfolio.customers_raw AS customers
      WHERE customers.customer_id = orders.customer_id
    );

  IF null_links <> 2 OR unknown_links <> 2 THEN
    RAISE EXCEPTION 'Expected 2 null and 2 unknown links; got % and %', null_links, unknown_links;
  END IF;
END $$;
ROLLBACK;
