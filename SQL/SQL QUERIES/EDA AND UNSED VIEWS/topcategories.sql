DROP VIEW IF EXISTS top_categories;
CREATE VIEW top_categories AS
WITH category_metrics AS (
    SELECT
        category,
        COUNT(DISTINCT order_id)                            AS total_orders,
        ROUND(SUM(item_revenue_made), 2)                    AS revenue_made,
        ROUND(SUM(item_revenue_lost), 2)                    AS revenue_lost,
        ROUND(AVG(item_value), 2)                           AS avg_order_value,
        ROUND(AVG(is_canceled) * 100, 2)                    AS cancellation_rate_pct,
        ROUND(100.0 -
            AVG(is_not_delivered) * 100, 2)                 AS avg_delivery_rate_pct,
        RANK() OVER (ORDER BY SUM(item_revenue_made) DESC)  AS revenue_rank
    FROM revenue_category_seller_cleaned
    WHERE category != 'uncategorized'
    GROUP BY category
    HAVING COUNT(DISTINCT order_id) >= 50
),
most_ordered_product AS (
    SELECT DISTINCT ON (category)
        category,
        product_id                                          AS top_product_id,
        COUNT(*) OVER (
            PARTITION BY category, product_id)              AS product_order_count
    FROM revenue_category_seller_cleaned
    WHERE category != 'uncategorized'
    AND order_status = 'delivered'
    ORDER BY category,
        COUNT(*) OVER (
            PARTITION BY category, product_id) DESC
),
top_seller AS (
    SELECT DISTINCT ON (category)
        category,
        seller_id                                           AS top_seller_id,
        SUM(item_revenue_made) OVER (
            PARTITION BY category, seller_id)               AS seller_revenue
    FROM revenue_category_seller_cleaned
    WHERE category != 'uncategorized'
    AND order_status = 'delivered'
    ORDER BY category,
        SUM(item_revenue_made) OVER (
            PARTITION BY category, seller_id) DESC
)
SELECT
    c.category,
    c.total_orders,
    c.revenue_made,
    c.revenue_lost,
    c.avg_order_value,
    c.cancellation_rate_pct,
    c.avg_delivery_rate_pct,
    c.revenue_rank,
    m.top_product_id,
    m.product_order_count               AS top_product_times_ordered,
    t.top_seller_id,
    t.seller_revenue                    AS top_seller_revenue
FROM category_metrics c
LEFT JOIN most_ordered_product m
    ON c.category = m.category
LEFT JOIN top_seller t
    ON c.category = t.category
WHERE c.revenue_rank <= 10
ORDER BY c.revenue_rank;