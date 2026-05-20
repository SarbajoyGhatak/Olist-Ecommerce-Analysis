CREATE OR REPLACE VIEW vw_revenue_breakdown AS
SELECT
    revenue_status,
    COUNT(DISTINCT order_id)                               AS affected_orders,
    ROUND(SUM(item_value), 2)                              AS total_value,
    ROUND(100.0 * SUM(item_value) /
        SUM(SUM(item_value)) OVER (), 2)                   AS pct_of_total,
    ROUND(AVG(item_value), 2)                              AS avg_item_value
FROM revenue_category_seller_cleaned
GROUP BY revenue_status
ORDER BY total_value DESC;