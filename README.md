# SQL Data Quality & Reconciliation Portfolio

A reproducible PostgreSQL exercise for CRM / Data Quality Analyst interviews. It demonstrates **source-data profiling, duplicate detection, missing-key investigation, left-join reconciliation, and CTE-based cleansing**. All records are fictional.

## Run the scripts

Use PostgreSQL 15+ and a database you can safely modify. **`01_seed_messy_data.sql` drops/recreates the `dq_portfolio` schema** — never run it in a live database.

```bash
createdb dq_portfolio_demo
psql -X -v ON_ERROR_STOP=1 -d dq_portfolio_demo -f sql/01_seed_messy_data.sql
psql -X -v ON_ERROR_STOP=1 -d dq_portfolio_demo -f sql/02_identify_duplicates.sql
psql -X -v ON_ERROR_STOP=1 -d dq_portfolio_demo -f sql/03_find_orphaned_orders.sql
psql -X -v ON_ERROR_STOP=1 -d dq_portfolio_demo -f sql/04_reconcile_with_left_join.sql
psql -X -v ON_ERROR_STOP=1 -d dq_portfolio_demo -f sql/05_clean_customers_cte.sql
psql -X -v ON_ERROR_STOP=1 -d dq_portfolio_demo -f sql/06_quality_assertions.sql
```

Alternatively, connect with pgAdmin and execute each file in numerical order. You need not create a desktop folder manually: unzip this repository to your preferred location.

## What each query proves — interview explanation

| File | What it does | What to say |
| --- | --- | --- |
| `01_seed_messy_data.sql` | Creates unconstrained **staging** customers/orders tables with duplicates, NULL email/name/customer IDs, malformed email and orphan orders. | “I preserve defects in raw staging rather than silently discarding rows.” |
| `02_identify_duplicates.sql` | Normalises case/whitespace, uses window `COUNT(*)` to flag repeated business IDs or emails. | “I distinguish physical rows from real-world customer identity; NULL email isn't treated as a duplicate key.” |
| `03_find_orphaned_orders.sql` | Uses `NOT EXISTS` and separate reasons for missing and unknown foreign keys. | “A NULL join key and an invalid non-NULL join key need different remediation.” |
| `04_reconcile_with_left_join.sql` | Uses a window function to choose the latest record per ID, then `LEFT JOIN` to keep every order in the output. | “A direct join to duplicate staging IDs would inflate order totals. I dedupe before reconciliation.” |
| `05_clean_customers_cte.sql` | `standardised → validated → one_per_id → one_per_email`, keeping the newest valid canonical row. | “CTEs make each rule auditable. The winning record and tie-break are explicit, not arbitrary.” |
| `06_quality_assertions.sql` | A PostgreSQL DO block asserts fixture counts and invalid links. | “I convert expectations into repeatable automated quality checks.” |

## Known limitations and data governance

- These are **demo rules**, not definitive customer-mastering rules. Email matching alone can merge different people; repeated IDs can reflect source-system collisions. In a real CRM, use governed match thresholds and human review.
- The simplified email regex is a **data-quality heuristic**, not a complete RFC validation rule. An email passing the regex is not proof of deliverability or consent.
- The cleaned view outputs **six** customers (IDs 1001, 1003, 1006, 1008, 1009, 1010). In particular, customer ID 1005 is superseded by 1006 because both share the normalised email and 1006 has the later update. **Do not remove ID 1005 from an actual CRM without an audited ID crosswalk** — otherwise order 5006 would become a dangling reference.
- In the mock reconciliation, order 5002 has a missing customer email, 5003 references missing customer ID 9999, and 5004 has a NULL customer ID.
- For Excel competency, see `data_quality_review.xlsx` in this folder: it contains a formula-driven quality register, reconciliation examples, and an interview-ready KPI dashboard. The workbook is illustrative and independent of the `psql` results.

## GitHub

```bash
git init
git add .
git commit -m "Add SQL data cleaning and reconciliation exercises"
gh repo create sql-data-quality --public --source=. --remote=origin --push
```

Requires `gh auth login`; never publish real customer data.
