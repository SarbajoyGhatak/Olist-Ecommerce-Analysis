DROP VIEW IF EXISTS opportunity_categories;
CREATE VIEW opportunity_categories AS
WITH category_base AS (
    SELECT
        category,
        COUNT(DISTINCT order_id)                            AS total_orders,
        ROUND(AVG(item_value), 2)                           AS avg_item_value,
        ROUND(SUM(item_revenue_made), 2)                    AS revenue_made,
        ROUND(SUM(item_revenue_lost), 2)                    AS revenue_lost,
        ROUND(AVG(is_canceled) * 100, 2)                    AS cancellation_rate_pct
    FROM revenue_category_seller_cleaned
    WHERE category != 'uncategorized'
    GROUP BY category
    HAVING COUNT(DISTINCT order_id) >= 10
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY avg_item_value DESC)          AS item_value_rank,
        RANK() OVER (ORDER BY total_orders ASC)             AS low_volume_rank
    FROM category_base
),
opportunity_scored AS (
    SELECT *,
        ROUND((item_value_rank + low_volume_rank) / 2.0, 1) AS opportunity_score,
        CASE
            WHEN item_value_rank <= 15
            AND low_volume_rank <= 15
                THEN 'high_opportunity'
            WHEN item_value_rank <= 25
            AND low_volume_rank <= 25
                THEN 'medium_opportunity'
            ELSE 'monitor'
        END                                                 AS opportunity_tier
    FROM ranked
)
SELECT
    category,
    total_orders,
    avg_item_value,
    revenue_made,
    revenue_lost,
    cancellation_rate_pct,
    item_value_rank,
    low_volume_rank,
    opportunity_score,
    opportunity_tier
FROM opportunity_scored
WHERE opportunity_tier IN ('high_opportunity', 'medium_opportunity')
ORDER BY opportunity_score DESC;