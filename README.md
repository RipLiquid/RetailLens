# RetailLens: Revenue, Retention & Returns

[![SQL verification](https://github.com/RipLiquid/RetailLens/actions/workflows/ci.yml/badge.svg)](https://github.com/RipLiquid/RetailLens/actions/workflows/ci.yml)

A reproducible PostgreSQL portfolio project answering a practical question:
**Which customers and products drive revenue after returns, and where should the business focus next?**

This is a fictional Canadian retailer using deterministic synthetic data. Amounts are CAD. Findings demonstrate analytical methods; they are not evidence about an actual company. All customer identifiers and transactions are generated.

## Start here

1. Read [the business brief](docs/business_brief.md) for the decision context.
2. Review [the model and metric definitions](docs/data_dictionary.md).
3. Run the project using either option below.
4. Read [the findings](docs/findings.md), inspect [analysis SQL](sql/04_analysis.sql), then review the exported evidence in `outputs/`.

### Option A: run locally without a database server

Install Node.js 20+ and run these commands **inside this directory**:

```sh
npm ci --ignore-scripts
npm run verify
```

The runner starts a fresh in-memory PGlite database (PostgreSQL compiled to WebAssembly), executes the SQL files in order, fails on quality-check errors, and exports CSV results plus query plans. It does not create a persistent server. The JavaScript file is a verification wrapper; the model, data generation, analysis, and quality rules live in SQL.

### Option B: run on PostgreSQL

Use a fresh development database with permission to create a schema and a function:

```sh
createdb commerce_portfolio
psql -d commerce_portfolio -f run.sql
```

`run.sql` is a psql script. In pgAdmin or DBeaver, run `sql/01_schema.sql` through `sql/06_performance.sql` individually in numerical order. The first file creates the dedicated `commerce` schema; it intentionally fails if the schema already exists. To rerun without deleting anything, use a new empty database. PostgreSQL server execution is a separate verification step from the included PGlite run.

Explore the outputs on either engine:

```sql
SELECT * FROM commerce.monthly_performance ORDER BY month;
SELECT * FROM commerce.category_performance ORDER BY net_sales DESC;
SELECT * FROM commerce.cohort_retention ORDER BY cohort_month, month_number;
SELECT * FROM commerce.product_ranking WHERE category_rank <= 3;
SELECT * FROM commerce.customer_rfm
WHERE recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4;
```

## What this demonstrates

| Business question | SQL techniques | Important analytical judgment |
|---|---|---|
| Is revenue growing after returns? | Date spine, CTEs, LAG | Sales-month restatement versus cash flow |
| Which categories lose value to returns? | Conditional metrics, joins, aggregation | Units returned versus orders returned |
| Which channels attract repeat buyers? | FILTER, customer-level aggregation | Include signups with no purchase; no CAC claim |
| Does retention differ by cohort? | Lateral date spine, distinct counts | Unobserved months differ from observed zeroes |
| Which products drive each category? | DENSE_RANK, cumulative window SUM | Define grain before applying windows |
| Which customers are most valuable? | NTILE, fixed snapshot | RFM tie handling and historical exposure |
| Can a customer history query be improved? | Composite index, EXPLAIN ANALYZE | Plan evidence, caching and write costs |

## Repository guide

```text
sql/01_schema.sql           Tables, keys and row-level constraints
sql/02_seed.sql             Deterministic synthetic data
sql/03_views.sql            Item and order economics at explicit grains
sql/04_analysis.sql         Six business analyses as reusable views
sql/05_quality_checks.sql   Eleven assertions; fail loudly on a mismatch
sql/06_performance.sql      Before/after index plans for the same query
scripts/verify.mjs          Fresh engine, checks, CSV and plan exports
docs/                      Brief, definitions, findings and interview notes
outputs/                   Reproducible evidence from the verification run
```

## Limitations and next work

- The seed deliberately raises apparel return probability. This is an engineered pattern, not a discovered real-world causal relationship.
- Acquisition costs, advertising spend, shipping, taxes and return processing costs are absent. This project cannot establish CAC, ROAS or full profitability.
- Returned items are assumed resellable at full cost. Merchandise margin is not operating profit.
- Data is synthetic and generated independently in several dimensions; it is unsuitable for forecasting validation or real customer-behavior conclusions.
- Retention uses completed purchases, including purchases ultimately fully refunded. RFM excludes customers without completed orders. Both are explicit modeling choices.
- The benchmark is small and engine-specific. No production latency or universal index speedup is claimed.

To make this your own, add a documented real dataset, adapt the model, rerun the checks, and replace the findings with your own decision memo. Never present generated transactions as real company experience.

Technical references: [PostgreSQL EXPLAIN documentation](https://www.postgresql.org/docs/current/using-explain.html), [series generation](https://www.postgresql.org/docs/current/functions-srf.html), and [window functions](https://www.postgresql.org/docs/current/tutorial-window.html).

## Continuous integration

GitHub Actions runs the SQL verification on every push and pull request, and can also be started manually from the Actions tab. Each run uses Node.js 24, installs the locked dependencies, and rebuilds the synthetic data in a fresh PGlite database. SQL errors or failing data-quality checks fail the job. Generated reports and query plans are available as a verification-results artifact for 14 days. The workflow verifies execution and correctness; it does not compare timing-sensitive query plans against committed output files.
