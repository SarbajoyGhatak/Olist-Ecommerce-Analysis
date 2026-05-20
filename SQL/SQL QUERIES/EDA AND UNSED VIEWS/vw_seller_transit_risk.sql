CREATE OR REPLACE VIEW vw_seller_transit_risk AS
SELECT
    seller_id,
    COUNT(DISTINCT order_id)                               AS orders_stuck,
    ROUND(SUM(item_value), 2)                              AS value_at_risk,
    ROUND(SUM(item_value) /
        NULLIF(SUM(SUM(item_value)) OVER (), 0) * 100, 2) AS pct_of_total_stuck
FROM revenue_category_seller_cleaned
WHERE revenue_status = 'in_transit'
GROUP BY seller_id
ORDER BY value_at_risk DESC;