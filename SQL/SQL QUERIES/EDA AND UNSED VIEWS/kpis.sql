CREATE OR REPLACE VIEW kpis AS
SELECT
    ROUND(SUM(CASE WHEN revenue_status != 'collected'
        THEN item_value ELSE 0 END), 2)                    AS total_amount_stuck,
    ROUND(AVG(CASE WHEN order_status = 'delivered'
        THEN item_value END), 2)                           AS avg_item_value,
    COUNT(DISTINCT CASE WHEN category != 'uncategorized'
        THEN category END)                                 AS unique_categories,
    ROUND(100.0 *
        COUNT(DISTINCT CASE WHEN order_status = 'delivered'
            THEN order_id END) /
        NULLIF(COUNT(DISTINCT order_id), 0), 2)            AS delivery_success_rate_pct
FROM revenue_category_seller_cleaned;