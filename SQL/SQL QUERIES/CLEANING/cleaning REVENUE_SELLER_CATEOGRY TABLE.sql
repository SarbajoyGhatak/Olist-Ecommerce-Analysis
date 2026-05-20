CREATE TABLE revenue_category_seller (
    order_id        VARCHAR(50),
    product_id      VARCHAR(50),
    seller_id       VARCHAR(50),
    category        VARCHAR(100),
    item_value      NUMERIC(10,2),
    order_status    VARCHAR(20)
);

COPY revenue_category_seller (
    order_id,
    product_id,
    seller_id,
    category,
    item_value,
    order_status
)
FROM 'C:/WORK/PROJECTS/OLIST_SQL ANALYSIS AND PBI DASHBOARD/DATA_CLEANED/revenue_category_seller.csv'
DELIMITER ','
CSV HEADER;

select * from revenue_category_seller

-- grain check and duplicates
SELECT
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT order_id)        AS unique_orders,
    COUNT(DISTINCT product_id)      AS unique_products,
    COUNT(DISTINCT seller_id)       AS unique_sellers,
    COUNT(DISTINCT category)        AS unique_categories
FROM REVENUE_CATEGORY_SELLER;

--  null check
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)     AS null_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL)   AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL)    AS null_seller_id,
    COUNT(*) FILTER (WHERE category IS NULL)     AS null_category,
    COUNT(*) FILTER (WHERE item_value IS NULL)   AS null_price,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_status
FROM revenue_category_seller;

--  price sanity check
SELECT
    MIN(item_value)                      AS min_price,
    MAX(item_value)                      AS max_price,
    AVG(item_value)                      AS avg_price,
    COUNT(*) FILTER (WHERE item_value <= 0) AS zero_or_neg_price
FROM revenue_category_seller;

--  order status distribution
SELECT
    order_status,
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT order_id)        AS unique_orders,
    ROUND(SUM(item_value), 2)            AS total_revenue
FROM revenue_category_seller
GROUP BY order_status
ORDER BY total_rows DESC;
-- null category check
-- these are the uncategorized products
SELECT
    COUNT(*) FILTER (WHERE category IS NULL
        OR category = 'uncategorized') AS uncategorized_items,
    COUNT(*) FILTER (WHERE category IS NOT NULL
        AND category != 'uncategorized') AS categorized_items
FROM revenue_category_seller;


-- drop and recreate with the revenue_status column added
CREATE TABLE revenue_category_seller_cleaned AS
SELECT
    order_id,
    product_id,
    seller_id,
    COALESCE(category, 'uncategorized')     AS category,
    item_value,
    order_status,
	-- revenue buckets
    CASE
        WHEN order_status = 'delivered'
        THEN item_value ELSE 0
    END                                     AS item_revenue_made,
	CASE
        WHEN order_status != 'delivered'
        THEN item_value ELSE 0
    END                                     AS item_revenue_lost,
	-- refined revenue status
    CASE
        WHEN order_status = 'delivered'
            THEN 'collected'
        WHEN order_status IN ('canceled', 'unavailable')
            THEN 'permanently_lost'
        WHEN order_status IN ('processing', 'invoiced')
            THEN 'stuck_in_pipeline'
        WHEN order_status IN ('shipped', 'approved')
            THEN 'in_transit'
        ELSE 'unknown'
    END                                     AS revenue_status,
	-- flags
    CASE
        WHEN order_status = 'canceled'
        THEN 1 ELSE 0
    END                                     AS is_canceled,
	CASE
        WHEN order_status != 'delivered'
        THEN 1 ELSE 0
    END                                     AS is_not_delivered
FROM revenue_category_seller;

SELECT * FROM revenue_category_seller_cleaned