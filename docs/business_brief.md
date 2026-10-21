# Business brief

The merchandising and growth teams at a fictional retailer want to decide where to investigate revenue leakage and customer retention before planning the next quarter.

## Decisions

1. Identify categories with high refund exposure; propose an operational experiment.
2. Compare channels on repeat purchasing and observed customer value; identify missing information before reallocating spend.
3. Assess mature first-purchase cohorts fairly before claiming retention improved.
4. Produce a customer shortlist for a potential loyalty campaign using transparent RFM rules.

## Scope

Orders: 2024-01-01 through 2025-12-31. Returns: observed through 2026-01-31, allowing every generated order its full 30-day return window. Revenue is attributed to the original order month, including later observed refunds. Retention and RFM snapshots stop at 2026-01-01.

Primary success criteria: reconciled financial measures, defensible denominators, explicit observation windows, reproducible SQL, and recommendations supported by the outputs. Business success of any proposed intervention requires a real experiment and cost data.

## Acceptance criteria

- A reviewer can rebuild the dataset and results with two commands.
- Every item contributes once to booked revenue even if it has multiple returns.
- Eleven SQL assertions pass and cause execution to fail if violated.
- All 24 reporting months appear; future cohort ages do not appear.
- The findings distinguish observed results, assumptions, and proposed actions.
- Index discussion includes actual before/after plans and performance limitations.
