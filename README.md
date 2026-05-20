# Olist E-Commerce — End to End Data Analysis Project

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql)
![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-yellow?logo=powerbi)
![Status](https://img.shields.io/badge/Status-Complete-green)

## Overview

End-to-end data analysis project built on the
Olist Brazilian E-commerce public dataset.
The project simulates a real business brief
from a CEO and delivers a complete analytical
response — from raw data to executive summary.

**99,441 orders · 8 source tables · 27 Brazilian states
· 2016 – 2018**

---

## The Business Brief

> *"We are losing revenue we should be collecting.
> Orders are getting canceled, going undelivered,
> or sitting in processing for days. We don't know
> how much money this represents or which categories
> and regions are worst affected.*
>
> *Our delivery estimates are also wrong. Late delivery
> is our number one driver of 1-star reviews. I need
> a clear picture: where is the money going, who is
> responsible for delivery failures, and what should
> we fix first."*
>
> — Olist CEO

Three questions drive the entire analysis:
1. Where is the revenue going and which categories
   and regions are most affected?
2. Who is responsible for delivery failures?
3. What should be fixed first?

---

## Key Findings

### Revenue Leakage
- **R$ 423,780** in total uncollected revenue
- **R$ 108,026** permanently lost to cancellations
  and unavailable orders — never recoverable
- **R$ 138,382** stuck in pipeline — operationally
  blocked but potentially recoverable
- **R$ 177,370** in transit — healthy pipeline,
  no action needed
- Top 10 revenue losing categories combined cost
  Olist **R$ 254,627** in lifetime losses
- **watches gifts** leads at R$ 41,208 (16.2%)
- **cool stuff** has the highest cancellation rate
  on the platform at R$ 27,649 (10.9%)

### Regional Performance
- **Roraima (RR)** records the highest revenue
  loss rate of any state in Brazil at **10%**
- AL, MA, AP, AC, AM all show elevated loss rates
- The northern and northeastern corridor shows
  consistent logistics infrastructure failure
- November 2017 recorded the largest single
  monthly revenue gap — **R$ 17,000** between
  actual and possible revenue

### Delivery Accountability
- **6,510 orders** arrived after the promised date
  — a **6.5% late delivery rate**
- **79.7%** of all late deliveries caused by
  **logistics partners** — not sellers
- **20.2%** caused by sellers missing their
  shipping handover deadline
- The courier network causes **4x more delivery
  failures** than sellers
- Inter-state orders are **1.76x more likely**
  to arrive late (8.1% vs 4.6%)
- AL and MA record the highest late delivery
  rates of any state

### Customer Satisfaction
- Early delivery → average review score **4.2 stars**
- Late delivery → average review score **2.8 stars**
- **1.4 star difference** driven entirely by
  delivery timing
- Logistics fault orders dominate the low score
  cluster — courier failures are the primary
  driver of 1-star reviews

### Market Opportunity
- 4 high-price, low-volume categories represent
  **R$ 500,000+** in untapped annual revenue
  at a 20% volume increase:

| Category | Avg Order Value |
|---|---|
| Small Home Appliances | R$ 660.44 |
| Furniture and Bedroom | R$ 226.45 |
| Construction Safety | R$ 229.15 |
| Construction Tools | R$ 174.00 |

---

## Project Structure
```
olist-analysis/
├── README.md
├── sql/
│   ├── 01_master_tables.sql
│   ├── 02_cleaning.sql
│   ├── 03_eda_queries.sql
│   └── 04_views.sql
├── dashboard/
│   └── olist_dashboard.pbix
└── report/
└── olist_executive_summary.pdf
```
---

## Tech Stack

| Tool | Purpose |
|---|---|
| PostgreSQL 16 | Data modelling, cleaning, EDA |
| Power BI | Interactive dashboard |
| SQL (Advanced) | CTEs, window functions, aggregation |

---

## Dashboard Pages

### Page 1 — Revenue Overview
- 4 KPI cards: total stuck, delivery rate,
  avg order value, unique categories
- Actual vs possible revenue MoM area chart
- Regional performance map (red/yellow/green
  by revenue loss rate)

### Page 2 — Category and Product Analysis
- Revenue loss breakdown (permanently lost
  vs in transit vs stuck in pipeline)
- Top 10 revenue losing categories bar chart
- Market opportunity scatter plot
  (high price vs low volume categories)

### Page 3 — Delivery Performance
- Order delivery funnel (4 stages)
- Late vs on time orders by state
  (100% stacked bar)
- Top 10 worst sellers by shipping delay
- Customer rating vs fault type scatter
- Fault type donut (courier vs seller split)
- Inter-state vs intra-state comparison
## Dashboard Preview

```
![Revenue Overview](screenshots/Screenshot%20(165).png)
![Category Analysis](screenshots/Screenshot%20(166).png)
![Delivery Performance](screenshots/Screenshot%20(167).png)
![Courier Performance](screenshots/Screenshot%20(168).png)
```
---

## Data Cleaning Summary

| Issue | Count | Action |
|---|---|---|
| Duplicate rows | 551 | Kept most recent review per order |
| Carrier before approval | 1,362 | Flagged + nulled derived columns |
| Delivery before carrier | 23 | Flagged + nulled derived columns |
| Zero weight values | 6 | Set to NULL |
| Unknown basket type | 2,197 | Reclassified to single category |
| Null primary category | 778 | Coalesced to uncategorized |
| Missing payment record | 4 | Flagged is_payment_missing |

Raw tables were never modified.
All cleaning was applied inside views
and the cleaned master table.

---

## SQL Architecture

Three master tables power the entire analysis:

**master_table_cleaned**
- Grain: one row per order
- Spine: orders table
- Joins: customers, order_items (aggregated),
  payments (aggregated)
- Used for: revenue, regional, MoM analysis

**revenue_category_seller_cleaned**
- Grain: one row per item
- Spine: order_items table
- Joins: products, category_translation, orders
- Used for: category, seller, opportunity analysis

**vw_funnel_master**
- Grain: one row per order
- Spine: orders table
- Joins: customers, payments, order_items,
  sellers, products, category_translation
- Used for: funnel, delivery, review analysis

Key SQL concepts applied:
- **Grain and fanout** — aggregation timing
  decisions driven by business question
- **CTEs** — multi-step aggregation chains
- **Window functions** — RANK, ROW_NUMBER,
  LAG, PERCENTILE_CONT, FIRST_VALUE
- **Conditional aggregation** — CASE inside
  SUM and COUNT for pivot-style analysis
- **Normalisation** — 0-100 score scaling
  for radar chart comparisons

---

## Recommendations

| Priority | Action | Owner | Timeline | Expected Impact |
|---|---|---|---|---|
| 1 | Renegotiate inter-state courier contracts — focus on AL, MA, RR, AM, AP | Operations | 60-90 days | Reduce late rate from 8.1% to under 5% |
| 2 | Seller late fee structure — warning, fine, suspension within 90-day window | Seller Management | 30 days | 30-40% reduction in seller delays |
| 3 | Cancellation fee for orders above R$ 200 — 5% after 24-hour grace period | Product | 2-3 weeks | Recover R$ 20,000-R$ 30,000 annually |
| 4 | Invest in opportunity categories — prioritise November window | Marketing | 45-60 days | R$ 500,000+ additional annual revenue |

---

## Dataset

**Olist Brazilian E-Commerce Public Dataset**
Available on Kaggle:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

8 source tables:
- orders
- order_items
- order_payments
- order_reviews
- customers
- products
- sellers
- product_category_name_translation

---

## Author

**Sarbajoy Ghatak**
Aspiring Data Analyst

LinkedIn: https://www.linkedin.com/in/sarbajoy-ghatak-717465272/
GitHub: https://github.com/SarbajoyGhatak

---

## Acknowledgements

Dataset provided by Olist and Andre Sionek
via Kaggle under a Creative Commons licence.
