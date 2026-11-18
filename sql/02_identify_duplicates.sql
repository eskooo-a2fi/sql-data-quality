-- Flag both repeated business IDs and emails that become equal after trimming/case-folding.
-- NULL email is NOT treated as an email duplicate; nulls require a separate quality rule.
WITH standardised AS (
  SELECT row_id, customer_id, full_name, email,
         NULLIF(LOWER(BTRIM(email)), '') AS normalised_email
  FROM dq_portfolio.customers_raw
), indicators AS (
  SELECT *,
         COUNT(*) OVER (PARTITION BY customer_id) AS rows_with_same_id,
         COUNT(*) OVER (PARTITION BY normalised_email) AS rows_with_same_email
  FROM standardised
)
SELECT row_id, customer_id, full_name, email, normalised_email,
       (customer_id IS NOT NULL AND rows_with_same_id > 1) AS duplicate_customer_id,
       (normalised_email IS NOT NULL AND rows_with_same_email > 1) AS duplicate_email
FROM indicators
WHERE (customer_id IS NOT NULL AND rows_with_same_id > 1)
   OR (normalised_email IS NOT NULL AND rows_with_same_email > 1)
ORDER BY COALESCE(normalised_email, ''), customer_id, row_id;
-- Expected rows: 1, 2 (same ID/email), 7, 8 (same normalised email).
