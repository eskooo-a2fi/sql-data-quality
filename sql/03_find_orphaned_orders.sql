-- Use NOT EXISTS to avoid multiplying an order when the staging customers table has duplicates.
-- A NULL customer_id and a non-matching ID are two distinct failure modes.
SELECT o.order_id, o.customer_id, o.total_gbp,
       CASE WHEN o.customer_id IS NULL THEN 'MISSING_CUSTOMER_ID'
            ELSE 'UNKNOWN_CUSTOMER_ID' END AS issue
FROM dq_portfolio.orders_raw AS o
WHERE o.customer_id IS NULL
   OR NOT EXISTS (
       SELECT 1 FROM dq_portfolio.customers_raw AS c
       WHERE c.customer_id = o.customer_id
   )
ORDER BY o.order_id;
-- Expected: order 5003 UNKNOWN_CUSTOMER_ID; order 5004 MISSING_CUSTOMER_ID.
