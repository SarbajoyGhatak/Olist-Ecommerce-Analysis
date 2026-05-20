-- how big is the dataset, what time period does it cover
SELECT
    COUNT(DISTINCT order_id)                               AS total_orders,
    COUNT(DISTINCT customer_unique_id)                     AS unique_customers,
    COUNT(DISTINCT primary_seller_id)                      AS unique_sellers,
    COUNT(DISTINCT primary_category)                       AS unique_categories,
    COUNT(DISTINCT customer_state)                         AS unique_states,
    MIN(order_purchase_timestamp)                          AS first_order_date,
    MAX(order_purchase_timestamp)                          AS last_order_date,
    EXTRACT(DAY FROM MAX(order_purchase_timestamp)
        - MIN(order_purchase_timestamp))                   AS dataset_span_days,
    ROUND(COUNT(DISTINCT order_id) /
        (EXTRACT(DAY FROM MAX(order_purchase_timestamp)
        - MIN(order_purchase_timestamp)) / 30.0), 0)      AS avg_orders_per_month
FROM funnel_master_clean;
-- what proportion of orders are in each status
SELECT
    order_status,
    COUNT(*)                                               AS total_orders,
    ROUND(100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (), 2)                          AS pct_of_total,
    ROUND(SUM(total_order_value), 2)                       AS total_value,
    ROUND(AVG(total_order_value), 2)                       AS avg_order_value,
    ROUND(MIN(total_order_value), 2)                       AS min_order_value,
    ROUND(MAX(total_order_value), 2)                       AS max_order_value
FROM funnel_master_clean
GROUP BY order_status
ORDER BY total_orders DESC;
-- understand the shape of order values before any analysis
SELECT
    -- central tendency
    ROUND(AVG(total_order_value), 2)                       AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY total_order_value)                       AS median,

    -- spread
    ROUND(STDDEV(total_order_value), 2)                    AS std_dev,
    ROUND(VARIANCE(total_order_value), 2)                  AS variance,

    -- percentiles
    PERCENTILE_CONT(0.10) WITHIN GROUP
        (ORDER BY total_order_value)                       AS p10,
    PERCENTILE_CONT(0.25) WITHIN GROUP
        (ORDER BY total_order_value)                       AS p25,
    PERCENTILE_CONT(0.75) WITHIN GROUP
        (ORDER BY total_order_value)                       AS p75,
    PERCENTILE_CONT(0.90) WITHIN GROUP
        (ORDER BY total_order_value)                       AS p90,
    PERCENTILE_CONT(0.99) WITHIN GROUP
        (ORDER BY total_order_value)                       AS p99,

    -- range
    MIN(total_order_value)                                 AS min_value,
    MAX(total_order_value)                                 AS max_value,
    MAX(total_order_value) - MIN(total_order_value)        AS range,

    -- skew indicator: if mean >> median, data is right skewed
    ROUND(AVG(total_order_value) -
        PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY total_order_value)::NUMERIC, 2)          AS mean_median_gap,

    -- outlier count: orders above p99
    COUNT(*) FILTER (WHERE total_order_value >
        PERCENTILE_CONT(0.99) WITHIN GROUP
        (ORDER BY total_order_value)
        OVER ())                                           AS outlier_orders_above_p99

FROM funnel_master_clean
WHERE order_status = 'delivered';
-- how many items do customers typically buy per order
SELECT
    ROUND(AVG(total_items), 2)                             AS avg_items_per_order,
    PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY total_items)                             AS median_items,
    MAX(total_items)                                       AS max_items_in_one_order,
    MIN(total_items)                                       AS min_items,

    -- basket size distribution
    COUNT(*) FILTER (WHERE total_items = 1)                AS single_item_orders,
    COUNT(*) FILTER (WHERE total_items = 2)                AS two_item_orders,
    COUNT(*) FILTER (WHERE total_items BETWEEN 3 AND 5)    AS three_to_five_items,
    COUNT(*) FILTER (WHERE total_items > 5)                AS more_than_five_items,

    -- as percentages
    ROUND(100.0 * COUNT(*) FILTER (WHERE total_items = 1) /
        COUNT(*), 2)                                       AS pct_single_item,
    ROUND(100.0 * COUNT(*) FILTER (WHERE total_items > 1) /
        COUNT(*), 2)                                       AS pct_multi_item
FROM funnel_master_clean;
-- how long does delivery actually take
SELECT
    -- purchase to delivery (full journey)
    ROUND(AVG(DATE_PART('day',
        order_delivered_customer_date -
        order_purchase_timestamp)), 2)                     AS avg_days_purchase_to_delivery,
    PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY DATE_PART('day',
        order_delivered_customer_date -
        order_purchase_timestamp))                         AS median_days_to_delivery,
    PERCENTILE_CONT(0.90) WITHIN GROUP
        (ORDER BY DATE_PART('day',
        order_delivered_customer_date -
        order_purchase_timestamp))                         AS p90_days_to_delivery,

    -- each funnel stage average
    ROUND(AVG(days_to_approve), 2)                         AS avg_days_to_approve,
    ROUND(AVG(days_to_ship_clean), 2)                      AS avg_days_to_ship,
    ROUND(AVG(days_in_transit_clean), 2)                   AS avg_days_in_transit,

    -- delay stats
    ROUND(AVG(delay_vs_estimate), 2)                       AS avg_delay_vs_estimate,
    COUNT(*) FILTER (WHERE delay_vs_estimate > 0)          AS orders_delivered_late,
    COUNT(*) FILTER (WHERE delay_vs_estimate <= 0)         AS orders_delivered_ontime,
    ROUND(100.0 * COUNT(*) FILTER
        (WHERE delay_vs_estimate > 0) /
        NULLIF(COUNT(*) FILTER
        (WHERE delay_vs_estimate IS NOT NULL), 0), 2)      AS late_delivery_rate_pct,

    -- worst delays
    MAX(delay_vs_estimate)                                 AS worst_delay_days,
    PERCENTILE_CONT(0.95) WITHIN GROUP
        (ORDER BY delay_vs_estimate)                       AS p95_delay_days

FROM funnel_master_clean
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL;
-- how do customers pay
SELECT
    primary_payment_type,
    COUNT(DISTINCT order_id)                               AS total_orders,
    ROUND(100.0 * COUNT(DISTINCT order_id) /
        SUM(COUNT(DISTINCT order_id)) OVER (), 2)          AS pct_of_orders,
    ROUND(AVG(total_order_value), 2)                       AS avg_order_value,
    ROUND(AVG(payment_installments), 2)                    AS avg_installments,
    ROUND(SUM(total_order_value), 2)                       AS total_revenue,
    ROUND(MIN(total_order_value), 2)                       AS min_order_value,
    ROUND(MAX(total_order_value), 2)                       AS max_order_value
FROM funnel_master_clean
GROUP BY primary_payment_type
ORDER BY total_orders DESC;

-- installment behaviour
SELECT
    payment_installments,
    COUNT(DISTINCT order_id)                               AS total_orders,
    ROUND(AVG(total_order_value), 2)                       AS avg_order_value,
    ROUND(100.0 * COUNT(DISTINCT order_id) /
        SUM(COUNT(DISTINCT order_id)) OVER (), 2)          AS pct_of_orders
FROM funnel_master_clean
WHERE payment_installments IS NOT NULL
GROUP BY payment_installments
ORDER BY payment_installments;
-- repeat vs one time customers
WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id)                           AS order_count,
        ROUND(SUM(total_order_value), 2)                   AS lifetime_value,
        ROUND(AVG(total_order_value), 2)                   AS avg_order_value,
        MIN(order_purchase_timestamp)                      AS first_order,
        MAX(order_purchase_timestamp)                      AS last_order
    FROM funnel_master_clean
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*)                                               AS total_customers,
    COUNT(*) FILTER (WHERE order_count = 1)                AS one_time_customers,
    COUNT(*) FILTER (WHERE order_count = 2)                AS two_time_customers,
    COUNT(*) FILTER (WHERE order_count >= 3)               AS loyal_customers,
    ROUND(100.0 * COUNT(*) FILTER
        (WHERE order_count = 1) /
        COUNT(*), 2)                                       AS one_time_pct,
    ROUND(100.0 * COUNT(*) FILTER
        (WHERE order_count >= 2) /
        COUNT(*), 2)                                       AS repeat_customer_pct,
    ROUND(AVG(lifetime_value), 2)                          AS avg_customer_ltv,
    ROUND(AVG(order_count), 2)                             AS avg_orders_per_customer,
    MAX(order_count)                                       AS most_orders_by_one_customer
FROM customer_orders;
-- review score central tendency and spread
SELECT
    ROUND(AVG(review_score), 2)                            AS mean_score,
    PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY review_score)                            AS median_score,
    ROUND(STDDEV(review_score), 2)                         AS std_dev,
    MIN(review_score)                                      AS min_score,
    MAX(review_score)                                      AS max_score,

    -- score buckets
    COUNT(*) FILTER (WHERE review_score = 5)               AS five_star,
    COUNT(*) FILTER (WHERE review_score = 4)               AS four_star,
    COUNT(*) FILTER (WHERE review_score = 3)               AS three_star,
    COUNT(*) FILTER (WHERE review_score = 2)               AS two_star,
    COUNT(*) FILTER (WHERE review_score = 1)               AS one_star,

    -- sentiment split
    COUNT(*) FILTER (WHERE review_score <= 2)              AS negative_reviews,
    COUNT(*) FILTER (WHERE review_score = 3)               AS neutral_reviews,
    COUNT(*) FILTER (WHERE review_score >= 4)              AS positive_reviews,
    ROUND(100.0 * COUNT(*) FILTER
        (WHERE review_score <= 2) /
        NULLIF(COUNT(*) FILTER
        (WHERE review_score IS NOT NULL), 0), 2)           AS negative_review_rate_pct

FROM funnel_master_clean
WHERE review_score IS NOT NULL;

-- avg review score by order status
SELECT
    order_status,
    COUNT(*)                                               AS total_orders,
    ROUND(AVG(review_score), 2)                            AS avg_review_score,
    COUNT(*) FILTER (WHERE review_score <= 2)              AS negative_reviews,
    ROUND(100.0 * COUNT(*) FILTER
        (WHERE review_score <= 2) /
        NULLIF(COUNT(*) FILTER
        (WHERE review_score IS NOT NULL), 0), 2)           AS negative_review_rate_pct
FROM funnel_master_clean
WHERE review_score IS NOT NULL
GROUP BY order_status
ORDER BY avg_review_score DESC;
-- product weight distribution
SELECT
    weight_bucket,
    COUNT(DISTINCT order_id)                               AS total_orders,
    ROUND(100.0 * COUNT(DISTINCT order_id) /
        SUM(COUNT(DISTINCT order_id)) OVER (), 2)          AS pct_of_orders,
    ROUND(AVG(total_order_value), 2)                       AS avg_order_value,
    ROUND(AVG(days_in_transit_clean), 2)                   AS avg_transit_days,
    ROUND(AVG(delay_vs_estimate), 2)                       AS avg_delay_days,
    ROUND(100.0 * COUNT(*) FILTER
        (WHERE delay_vs_estimate > 0) /
        NULLIF(COUNT(*) FILTER
        (WHERE delay_vs_estimate IS NOT NULL), 0), 2)      AS late_rate_pct
FROM funnel_master_clean
WHERE order_status = 'delivered'
GROUP BY weight_bucket
ORDER BY
    CASE weight_bucket
        WHEN 'light (<500g)'      THEN 1
        WHEN 'medium (500g-2kg)'  THEN 2
        WHEN 'heavy (2kg-10kg)'   THEN 3
        WHEN 'very heavy (>10kg)' THEN 4
    END;
-- how sellers are distributed
WITH seller_summary AS (
    SELECT
        seller_id,
        COUNT(DISTINCT order_id)                           AS total_orders,
        ROUND(SUM(item_revenue_made), 2)                   AS revenue_made
    FROM revenue_category_seller_clean
    GROUP BY seller_id
)
SELECT
    COUNT(*)                                               AS total_sellers,
    ROUND(AVG(total_orders), 2)                            AS avg_orders_per_seller,
    PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY total_orders)                            AS median_orders_per_seller,
    MAX(total_orders)                                      AS max_orders_one_seller,
    MIN(total_orders)                                      AS min_orders_one_seller,

    -- revenue concentration
    ROUND(AVG(revenue_made), 2)                            AS avg_revenue_per_seller,
    PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY revenue_made)                            AS median_revenue_per_seller,
    MAX(revenue_made)                                      AS max_revenue_one_seller,

    -- long tail check: what % of sellers do < 10 orders
    COUNT(*) FILTER (WHERE total_orders < 10)              AS small_sellers,
    ROUND(100.0 * COUNT(*) FILTER
        (WHERE total_orders < 10) /
        COUNT(*), 2)                                       AS small_seller_pct,

    -- top 10 sellers revenue share
    ROUND(100.0 *
        SUM(CASE WHEN revenue_made >= PERCENTILE_CONT(0.90)
            WITHIN GROUP (ORDER BY revenue_made) OVER ()
            THEN revenue_made ELSE 0 END) /
        NULLIF(SUM(revenue_made), 0), 2)                   AS top_10pct_revenue_share

FROM seller_summary;