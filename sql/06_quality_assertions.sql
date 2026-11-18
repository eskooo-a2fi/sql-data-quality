-- Assertions fail loudly if the mock dataset has been accidentally changed.
DO $$
DECLARE
  n_customers INTEGER;
  n_orders INTEGER;
  n_missing_id INTEGER;
  n_unknown_id INTEGER;
BEGIN
  SELECT COUNT(*) INTO n_customers FROM dq_portfolio.customers_raw;
  SELECT COUNT(*) INTO n_orders FROM dq_portfolio.orders_raw;
  SELECT COUNT(*) INTO n_missing_id FROM dq_portfolio.orders_raw WHERE customer_id IS NULL;
  SELECT COUNT(*) INTO n_unknown_id
  FROM dq_portfolio.orders_raw o
  WHERE o.customer_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM dq_portfolio.customers_raw c WHERE c.customer_id = o.customer_id);
  IF n_customers <> 12 OR n_orders <> 8 OR n_missing_id <> 1 OR n_unknown_id <> 1 THEN
    RAISE EXCEPTION 'Unexpected test data: customers %, orders %, missing FK %, orphan %',
      n_customers, n_orders, n_missing_id, n_unknown_id;
  END IF;
  RAISE NOTICE 'Data quality fixture validated: 12 customers / 8 orders / 2 invalid links';
END $$;
