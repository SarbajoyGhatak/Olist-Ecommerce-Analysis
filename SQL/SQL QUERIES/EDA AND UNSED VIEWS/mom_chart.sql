CREATE OR REPLACE VIEW mom_chart AS
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp)      AS month,
        ROUND(SUM(revenue_made), 2)                        AS revenue_collected,
        ROUND(SUM(revenue_made) +
            SUM(CASE WHEN order_status IN
                ('canceled','unavailable','processing','invoiced')
                THEN total_order_value ELSE 0 END), 2)     AS revenue_possible,
        ROUND(SUM(CASE WHEN order_status IN
            ('canceled','unavailable','processing','invoiced')
            THEN total_order_value ELSE 0 END), 2)         AS real_revenue_lost,
        COUNT(DISTINCT order_id)                           AS total_orders,
        COUNT(DISTINCT CASE WHEN order_status = 'delivered'
            THEN order_id END)                             AS delivered_orders
    FROM master_table_cleaned
    WHERE order_purchase_timestamp >= '2017-01-01'
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
)
SELECT
    month,
    revenue_collected,
    revenue_possible,
    real_revenue_lost,
    total_orders,
    delivered_orders,
    ROUND(100.0 * (revenue_collected -
        LAG(revenue_collected) OVER (ORDER BY month)) /
        NULLIF(LAG(revenue_collected) OVER (ORDER BY month), 0), 2)
                                                           AS mom_collected_pct,
    ROUND(100.0 * (real_revenue_lost -
        LAG(real_revenue_lost) OVER (ORDER BY month)) /
        NULLIF(LAG(real_revenue_lost) OVER (ORDER BY month), 0), 2)
                                                           AS mom_loss_pct,
    ROUND(100.0 * real_revenue_lost /
        NULLIF(revenue_possible, 0), 2)                    AS monthly_loss_rate_pct
FROM monthly
ORDER BY month;