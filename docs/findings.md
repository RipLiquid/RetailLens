# Findings and proposed next steps

**Scope:** deterministic synthetic transactions for a fictional retailer. Orders span 2024–2025; returns are observed through January 2026. All amounts are CAD. These findings illustrate the method; the generator intentionally includes an apparel return pattern and customer purchase-frequency differences.

## Revenue quality

Booked sales were **$14,106,927.30**, with **$951,104.75** in observed refunds, leaving **$13,155,822.55** in net sales. Refunds consumed **6.74%** of booked sales. December 2025 net sales were **$1,005,645.20**, up **2.27%** from November; that single increase does not establish a sustained trend.

Evidence: `outputs/totals.csv` and `outputs/monthly_performance.csv`. Net sales are restated to the original sales month; these are not monthly refund cash-flow figures.

## Apparel deserves a returns investigation

Apparel's unit return rate was **12.48%**, versus **4.62%–4.78%** in the other categories. Apparel accounted for **48.28%** of refund value. Accessories produced the highest net sales at **$3,664,646.95**.

Proposed action: for a real retailer with this pattern, investigate fit-related reasons by SKU and test clearer sizing information. Evaluate returned units per sold unit and merchandise margin per order together. The synthetic data does not prove that sizing information would improve either measure.

Evidence: `outputs/category_performance.csv`. Return percentages use units as the denominator, not orders or return events.

## Channel rankings depend on the metric

Paid search led total net sales at **$3,379,486.85**. Organic led observed net sales per buyer at **$1,782.45**. Social led repeat buyer rate at **87.64%**. Across channels, repeat buyer rates ranged from **84.18% to 87.64%**.

Proposed action: compare equal-length customer observation windows and obtain acquisition spend before reallocating marketing budget. Revenue per buyer and repeat rate do not establish acquisition efficiency or causation. Different customer tenure and purchase-frequency mixtures can affect the rankings.

Evidence: `outputs/channel_performance.csv`. Signups without completed purchases remain in the signup counts; repeat rate uses buyers as its denominator.

## Retention requires comparable observation windows

The weighted month-one retention rate is **25.06%** across **23 eligible cohorts** (1,889 active customers / 7,537 original cohort customers). Month-twelve retention is **20.61%** across **12 eligible cohorts** (668 / 3,241).

These percentages describe different eligible cohort sets. They cannot establish that retention has declined over time or quantify a within-customer decline. Compare the same cohort set at common ages before drawing that conclusion. Month-zero retention is 100% by construction, because a cohort is defined by a first purchase.

Evidence: `outputs/cohort_retention.csv`. Reproduce weighted summaries with:

```sql
SELECT month_number, count(*) AS eligible_cohorts,
       sum(active_customers) AS active_customers,
       sum(cohort_size) AS eligible_customers,
       round(100.0*sum(active_customers)/sum(cohort_size),2) AS weighted_retention_pct
FROM commerce.cohort_retention
WHERE month_number IN (1,3,6,12)
GROUP BY month_number ORDER BY month_number;
```

## Correct joins have a measurable impact

A deliberately unsafe join to individual return events reports **$14,439,264.95** in booked sales. The correct total is **$14,106,927.30**. The unsafe join overstates revenue by **$332,337.65** because some lines have two return events. Aggregating returns before joining eliminates the duplication.

Evidence: `outputs/fanout_demonstration.csv`, `sql/03_views.sql` and the source reconciliation checks. All **11 SQL quality assertions passed**.

## Performance evidence

The captured customer-history query changes from a sequential scan to a bitmap index scan after adding `(customer_id, order_date)`. Both plans return eight rows. The example demonstrates a different access path on 36,000 orders; it does not justify a production speedup claim. Execution times in `outputs/query_plans.txt` are single-run PGlite measurements and vary with execution environment and caching. Standard scan methods are explicitly enabled for both variants.

Evidence: `outputs/query_plans.txt` and `sql/06_performance.sql`. Repeat on a PostgreSQL server with representative scale and multiple alternating trials before reporting benchmark percentages.
