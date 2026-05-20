DROP VIEW IF EXISTS opportunity_categories;
CREATE VIEW opportunity_categories AS
WITH category_base AS (
    SELECT
        category,
        COUNT(DISTINCT order_id)                            AS total_orders,
        ROUND(AVG(item_value), 2)                                AS avg_price,
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
        COUNT(*) OVER ()                                    AS total_categories,
        RANK() OVER (ORDER BY avg_price DESC)               AS price_rank,
        RANK() OVER (ORDER BY total_orders ASC)             AS low_volume_rank
    FROM category_base
),
with_tier AS (
    SELECT *,
        ROUND((price_rank + low_volume_rank) / 2.0, 1)     AS opportunity_score,
        CASE
            -- top 33% of price AND top 33% of low volume
            WHEN price_rank <= ROUND(total_categories * 0.33)
            AND  low_volume_rank <= ROUND(total_categories * 0.33)
                THEN 'high_opportunity'
            -- top 50% of price AND top 50% of low volume
            WHEN price_rank <= ROUND(total_categories * 0.50)
            AND  low_volume_rank <= ROUND(total_categories * 0.50)
                THEN 'medium_opportunity'
            ELSE 'monitor'
        END                                                 AS opportunity_tier
    FROM ranked
)
SELECT
    category,
    total_orders,
    avg_price,
    revenue_made,
    revenue_lost,
    cancellation_rate_pct,
    price_rank,
    low_volume_rank,
    opportunity_score,
    opportunity_tier,
    total_categories
FROM with_tier
WHERE opportunity_tier IN ('high_opportunity', 'medium_opportunity')
ORDER BY opportunity_tier, opportunity_score DESC;