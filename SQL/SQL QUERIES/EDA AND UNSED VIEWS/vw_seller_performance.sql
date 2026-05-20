CREATE OR REPLACE VIEW vw_seller_performance AS
SELECT
    seller_id,
    total_orders,
    revenue_made,
    revenue_lost,
    permanently_lost,
    stuck_in_transit,
    cancellation_rate_pct,
    non_delivery_rate_pct,
    avg_item_price,
    categories_sold,
    revenue_rank,
    CASE
        WHEN revenue_rank <= 10   THEN 'top_10_sellers'
        WHEN revenue_rank <= 100  THEN 'next_90_sellers'
        WHEN revenue_rank <= 500  THEN 'mid_tier_sellers'
        ELSE                           'long_tail_sellers'
    END                                                    AS seller_tier,
    CASE
        WHEN cancellation_rate_pct >= 10
            THEN 'high_risk'
        WHEN revenue_made >= 50000
        AND  cancellation_rate_pct <= 2
            THEN 'star_seller'
        WHEN stuck_in_transit > revenue_made * 0.2
            THEN 'delivery_risk'
        ELSE 'standard'
    END                                                    AS seller_label
FROM (
    SELECT
        seller_id,
        COUNT(DISTINCT order_id)                           AS total_orders,
        ROUND(SUM(item_revenue_made), 2)                   AS revenue_made,
        ROUND(SUM(item_revenue_lost), 2)                   AS revenue_lost,
        ROUND(SUM(CASE WHEN revenue_status = 'permanently_lost'
            THEN item_value ELSE 0 END), 2)                AS permanently_lost,
        ROUND(SUM(CASE WHEN revenue_status = 'in_transit'
            THEN item_value ELSE 0 END), 2)                AS stuck_in_transit,
        ROUND(AVG(is_canceled) * 100, 2)                   AS cancellation_rate_pct,
        ROUND(AVG(is_not_delivered) * 100, 2)              AS non_delivery_rate_pct,
        ROUND(AVG(item_value), 2)                          AS avg_item_price,
        COUNT(DISTINCT category)                           AS categories_sold,
        RANK() OVER (ORDER BY SUM(item_revenue_made) DESC) AS revenue_rank
    FROM revenue_category_seller_cleaned
    GROUP BY seller_id
    HAVING COUNT(DISTINCT order_id) >= 10
) ranked
ORDER BY revenue_rank;