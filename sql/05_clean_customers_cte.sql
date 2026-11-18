-- Deliver one validated record per distinct customer ID AND distinct normalised email.
-- Business rule: latest updated_at wins; row_id is deterministic tie-breaker.
-- Rejected records stay in staging for investigation, not silently deleted.
WITH standardised AS (
  SELECT row_id, customer_id, NULLIF(BTRIM(full_name), '') AS clean_name,
         NULLIF(LOWER(BTRIM(email)), '') AS clean_email,
         NULLIF(REGEXP_REPLACE(COALESCE(phone, ''), '[^0-9+]', '', 'g'), '') AS clean_phone,
         updated_at, source_system
  FROM dq_portfolio.customers_raw
), validated AS (
  SELECT * FROM standardised
  WHERE customer_id IS NOT NULL
    AND clean_name IS NOT NULL
    AND clean_email ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+[.][a-z]{2,}$'
), one_per_id AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY customer_id ORDER BY updated_at DESC, row_id DESC
  ) AS id_rank
  FROM validated
), one_per_email AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY clean_email ORDER BY updated_at DESC, row_id DESC
  ) AS email_rank
  FROM one_per_id WHERE id_rank = 1
)
SELECT customer_id, clean_name AS full_name, clean_email AS email,
       clean_phone AS phone, updated_at, source_system
FROM one_per_email
WHERE email_rank = 1
ORDER BY customer_id;
-- Expected six valid customers: 1001, 1003, 1006, 1008, 1009, 1010.
-- The choice of 1006 rather than 1005 for Fran Hill is a stated recency rule.
-- In production, review identity collisions manually and maintain a crosswalk
-- from superseded IDs (e.g. 1005) to the survivor (1006) before downstream joins.
