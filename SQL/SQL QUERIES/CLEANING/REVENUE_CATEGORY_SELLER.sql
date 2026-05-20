CREATE VIEW REVENUE_CATEGORY_SELLER_REVENUE AS
SELECT
    oi.order_id,
    oi.product_id,
    oi.seller_id,
    COALESCE(ct.product_category_name_english,
             'uncategorized')       AS category,
    oi.price + oi.freight_value     AS item_value,
    o.order_status
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN  product_category_name_translation ct
    ON p.product_category_name = ct.product_category_name
LEFT JOIN orders o
    ON oi.order_id = o.order_id;