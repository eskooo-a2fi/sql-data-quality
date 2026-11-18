-- Reconcile every order to the latest staging row for its customer_id.
-- First choose one record per customer ID to avoid double-counting orders.
WITH latest_customer AS (
  SELECT c.*,
         ROW_NUMBER() OVER (
           PARTITION BY customer_id ORDER BY updated_at DESC, row_id DESC
         ) AS rn
  FROM dq_portfolio.customers_raw AS c
  WHERE customer_id IS NOT NULL
)
SELECT o.order_id, o.customer_id, o.total_gbp,
       c.full_name, c.email, c.source_system,
       CASE
         WHEN o.customer_id IS NULL THEN 'ORDER_MISSING_CUSTOMER_ID'
         WHEN c.customer_id IS NULL THEN 'CUSTOMER_NOT_FOUND'
         WHEN NULLIF(BTRIM(COALESCE(c.email, '')), '') IS NULL THEN 'CUSTOMER_EMAIL_MISSING'
         WHEN NULLIF(BTRIM(COALESCE(c.full_name, '')), '') IS NULL THEN 'CUSTOMER_NAME_MISSING'
         ELSE 'MATCHED'
       END AS reconciliation_status
FROM dq_portfolio.orders_raw AS o
LEFT JOIN latest_customer AS c
  ON c.customer_id = o.customer_id AND c.rn = 1
ORDER BY o.order_id;
-- LEFT JOIN keeps ALL 8 orders, including 5003 and 5004; order 5002 has a missing email.
-- Production note: an email can be invalid without being blank; check format separately.
