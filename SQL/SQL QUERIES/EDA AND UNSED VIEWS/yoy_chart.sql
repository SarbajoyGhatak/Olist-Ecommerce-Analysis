
CREATE OR REPLACE VIEW yoy_chart AS
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp)      AS month,
        EXTRACT(YEAR FROM order_purchase_timestamp)        AS yr,
        EXTRACT(MONTH FROM order_purchase_timestamp)       AS mo,
        ROUND(SUM(revenue_made), 2)                        AS revenue_collected,
        ROUND(SUM(CASE WHEN order_status IN
            ('canceled','unavailable','processing','invoiced')
            THEN total_order_value ELSE 0 END), 2)         AS real_revenue_lost,
        COUNT(DISTINCT order_id)                           AS total_orders
    FROM master_table_cleaned
    WHERE order_purchase_timestamp >= '2017-01-01'
    GROUP BY
        DATE_TRUNC('month', order_purchase_timestamp),
        EXTRACT(YEAR FROM order_purchase_timestamp),
        EXTRACT(MONTH FROM order_purchase_timestamp)
)
SELECT
    mo                                                     AS month_number,
    MAX(CASE WHEN yr = 2017 THEN revenue_collected END)    AS collected_2017,
    MAX(CASE WHEN yr = 2018 THEN revenue_collected END)    AS collected_2018,
    MAX(CASE WHEN yr = 2017 THEN real_revenue_lost END)    AS lost_2017,
    MAX(CASE WHEN yr = 2018 THEN real_revenue_lost END)    AS lost_2018,
    MAX(CASE WHEN yr = 2017 THEN total_orders END)         AS orders_2017,
    MAX(CASE WHEN yr = 2018 THEN total_orders END)         AS orders_2018,
    ROUND(100.0 * (
        MAX(CASE WHEN yr = 2018 THEN revenue_collected END) -
        MAX(CASE WHEN yr = 2017 THEN revenue_collected END)) /
        NULLIF(MAX(CASE WHEN yr = 2017
            THEN revenue_collected END), 0), 2)            AS yoy_collected_growth_pct,
    ROUND(100.0 * (
        MAX(CASE WHEN yr = 2018 THEN real_revenue_lost END) -
        MAX(CASE WHEN yr = 2017 THEN real_revenue_lost END)) /
        NULLIF(MAX(CASE WHEN yr = 2017
            THEN real_revenue_lost END), 0), 2)            AS yoy_loss_change_pct
FROM monthly
GROUP BY mo
ORDER BY mo;