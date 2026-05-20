DROP VIEW IF EXISTS worst_categories;
CREATE VIEW worst_categories AS
WITH category_base AS (
    SELECT
        category,
        COUNT(DISTINCT order_id)                            AS total_orders,
        COUNT(DISTINCT product_id)                          AS unique_products,
        ROUND(SUM(item_revenue_made), 2)                    AS revenue_made,
        ROUND(SUM(item_revenue_lost), 2)                    AS revenue_lost,
        ROUND(AVG(item_value), 2)                           AS avg_item_value,
        ROUND(AVG(is_canceled) * 100, 2)                    AS cancellation_rate_pct,
        ROUND(AVG(is_not_delivered) * 100, 2)               AS non_delivery_rate_pct
    FROM revenue_category_seller_cleaned
    WHERE category != 'uncategorized'
    GROUP BY category
    HAVING COUNT(DISTINCT order_id) >= 10
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY revenue_made ASC)             AS worst_rank
    FROM category_base
),
worst_product AS (
    SELECT DISTINCT ON (category)
        category,
        product_id                                          AS worst_product_id,
        seller_id                                           AS worst_seller_id,
        COUNT(*) OVER (
            PARTITION BY category, product_id)              AS product_order_count
    FROM revenue_category_seller_cleaned
    WHERE category != 'uncategorized'
    ORDER BY category,
        COUNT(*) OVER (
            PARTITION BY category, product_id) ASC
)
SELECT
    r.category,
    r.total_orders,
    r.unique_products,
    r.revenue_made,
    r.revenue_lost,
    r.avg_item_value,
    r.cancellation_rate_pct,
    r.non_delivery_rate_pct,
    r.worst_rank,
    w.worst_product_id,
    w.worst_seller_id,
    w.product_order_count
FROM ranked r
LEFT JOIN worst_product w ON r.category = w.category
WHERE r.worst_rank <= 10
ORDER BY r.worst_rank;
