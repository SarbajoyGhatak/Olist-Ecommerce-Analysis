DROP VIEW IF EXISTS radar_chart;
CREATE VIEW radar_chart AS
WITH category_base AS (
    SELECT
        category,
        COUNT(DISTINCT order_id)                            AS total_orders,
        COUNT(DISTINCT product_id)                          AS unique_products,
        ROUND(SUM(item_revenue_made), 2)                    AS revenue_made,
        ROUND(SUM(item_revenue_lost), 2)                    AS revenue_lost,
        ROUND(AVG(item_value), 2)                           AS avg_item_value,
        ROUND(AVG(is_canceled) * 100, 2)                    AS cancellation_rate_pct,
        ROUND(AVG(is_not_delivered) * 100, 2)               AS non_delivery_rate_pct,
        ROUND(SUM(CASE WHEN revenue_status = 'permanently_lost'
            THEN item_value ELSE 0 END), 2)                 AS permanently_lost
    FROM revenue_category_seller_cleaned
    WHERE category != 'uncategorized'
    GROUP BY category
    HAVING COUNT(DISTINCT order_id) >= 50
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY revenue_made DESC)            AS revenue_rank,
        RANK() OVER (ORDER BY total_orders DESC)            AS volume_rank,
        RANK() OVER (ORDER BY avg_item_value DESC)          AS price_rank,
        RANK() OVER (ORDER BY cancellation_rate_pct DESC)   AS cancel_rank
    FROM category_base
),
normalised AS (
    SELECT *,
        ROUND(100.0 * (revenue_made - MIN(revenue_made) OVER ()) /
            NULLIF(MAX(revenue_made) OVER () -
                MIN(revenue_made) OVER (), 0), 1)           AS revenue_score,
        ROUND(100.0 * (total_orders - MIN(total_orders) OVER ()) /
            NULLIF(MAX(total_orders) OVER () -
                MIN(total_orders) OVER (), 0), 1)           AS volume_score,
        ROUND(100.0 * (avg_item_value - MIN(avg_item_value) OVER ()) /
            NULLIF(MAX(avg_item_value) OVER () -
                MIN(avg_item_value) OVER (), 0), 1)         AS item_value_score,
        ROUND(100.0 - (100.0 *
            (cancellation_rate_pct - MIN(cancellation_rate_pct) OVER ()) /
            NULLIF(MAX(cancellation_rate_pct) OVER () -
                MIN(cancellation_rate_pct) OVER (), 0)), 1) AS reliability_score,
        ROUND(100.0 - (100.0 *
            (non_delivery_rate_pct - MIN(non_delivery_rate_pct) OVER ()) /
            NULLIF(MAX(non_delivery_rate_pct) OVER () -
                MIN(non_delivery_rate_pct) OVER (), 0)), 1) AS delivery_score
    FROM ranked
),
best_product AS (
    SELECT DISTINCT ON (category)
        category,
        product_id                                          AS best_product_id,
        seller_id                                           AS best_seller_id,
        COUNT(*) OVER (
            PARTITION BY category, product_id)              AS product_order_count
    FROM revenue_category_seller_cleaned
    WHERE order_status = 'delivered'
    AND category != 'uncategorized'
    ORDER BY category,
        COUNT(*) OVER (
            PARTITION BY category, product_id) DESC
)
SELECT
    n.category,
    n.total_orders,
    n.unique_products,
    n.revenue_made,
    n.revenue_lost,
    n.avg_item_value,
    n.cancellation_rate_pct,
    n.non_delivery_rate_pct,
    n.permanently_lost,
    n.revenue_rank,
    n.volume_rank,
    n.price_rank,
    n.cancel_rank,
    ROUND((n.price_rank + n.volume_rank) / 2.0, 1)         AS opportunity_score,
    n.revenue_score,
    n.volume_score,
    n.item_value_score,
    n.reliability_score,
    n.delivery_score,
    b.best_product_id,
    b.best_seller_id,
    b.product_order_count,
    CASE
        WHEN n.price_rank <= 15 AND n.volume_rank >= 30
            THEN 'high_opportunity'
        WHEN n.revenue_rank <= 10
            THEN 'top_performer'
        WHEN n.cancel_rank <= 10
            THEN 'high_risk'
        ELSE 'standard'
    END                                                     AS category_label
FROM normalised n
LEFT JOIN best_product b ON n.category = b.category
WHERE n.revenue_rank <= 10;