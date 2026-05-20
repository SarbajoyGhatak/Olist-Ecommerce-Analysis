CREATE OR REPLACE VIEW scatter_chart AS
WITH base AS (
    SELECT
        category,
        COUNT(DISTINCT order_id)                           AS total_orders,
        ROUND(AVG(item_value), 2)                          AS avg_price,
        ROUND(AVG(is_canceled) * 100, 2)                   AS cancellation_rate_pct,
        ROUND(SUM(item_revenue_made), 2)                   AS revenue_made,
        ROUND(SUM(item_revenue_lost), 2)                   AS revenue_lost,
        AVG(item_value)                                    AS avg_price_raw,
        AVG(is_canceled)                                   AS avg_canceled_raw
    FROM revenue_category_seller_cleaned
    WHERE category != 'uncategorized'
    GROUP BY category
    HAVING COUNT(DISTINCT order_id) >= 30
),
thresholds AS (
    SELECT
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_price_raw)    AS p75_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_orders)     AS p25_orders,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_canceled_raw) AS p75_canceled
    FROM base
)
SELECT
    b.category,
    b.total_orders,
    b.avg_price,
    b.cancellation_rate_pct,
    b.revenue_made,
    b.revenue_lost,
    CASE
        WHEN b.avg_price_raw >= t.p75_price
         AND b.total_orders  <= t.p25_orders   THEN 'high_price_low_volume'
        WHEN b.avg_price_raw >= t.p75_price
         AND b.avg_canceled_raw <= 0.03        THEN 'high_price_low_risk'
        WHEN b.avg_canceled_raw >= t.p75_canceled THEN 'high_risk'
        ELSE 'standard'
    END                                                    AS quadrant
FROM base b
CROSS JOIN thresholds t
ORDER BY avg_price DESC;