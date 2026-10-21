# Walk-through and personal extensions

## A 90-second explanation

“I built a reproducible PostgreSQL analytics project for a fictional retailer to investigate revenue quality and retention. I modeled customers, orders, products, order lines and return events, then created item-level and order-level financial views. The key correctness issue was that multiple returns can duplicate sales in a naive join. I aggregated returns before joining and checked that revenue reconciled back to the source. I also used calendar spines and fixed observation windows so recent cohorts were not penalized for months that had not happened. I benchmarked a customer-history query before and after a composite index and documented what the plan could and could not prove.”

Use this only after running the project and understanding every query. Describe it as a personal synthetic-data project.

## Questions to prepare for

- Why is an order count from item rows incorrect without DISTINCT?
- How does a two-event return inflate revenue in a naive join?
- Why does net sales differ from refund cash flow by month?
- Why is return rate weighted by units rather than averaged across products?
- Why do recent cohorts have fewer observable months?
- Can the top channel by customer value be called the best marketing investment? What is missing?
- What does the index key order help with? What are the storage and write tradeoffs?
- Why do quantile ties and customer tenure matter for RFM?

## Extensions that show your own judgment

1. Add a 90-day customer value analysis restricted to customers whose first purchase is at least 90 days before the observation cutoff. Compare channels on equal exposure.
2. Add marketing spend and compute CAC with explicit attribution assumptions. Show how the answer changes under different attribution rules.
3. Build an event-based revenue ledger: a positive sale event and negative refund events in their actual event months. Reconcile its total to the current restated revenue.
4. Introduce a deliberately invalid return inside a transaction, demonstrate a failing quality check, and roll back.
5. Repeat the query benchmark on a PostgreSQL server at larger scale. Report actual plans, warm-cache medians, variability, version and machine details.

## Honest resume phrasing

“Built a PostgreSQL e-commerce analytics portfolio using synthetic transactions, cohort retention, RFM segmentation and revenue reconciliation; implemented 11 SQL quality checks and evaluated a composite index using execution plans.”

Add verified scale numbers from `outputs/totals.csv`. Do not claim revenue improvement, production deployment or business impact that this project has not measured.
