CREATE OR REPLACE VIEW vw_category_top_product AS
SELECT DISTINCT ON (category)
    category,
    product_id                                             AS top_selling_product_id,
    COUNT(*)                                               AS times_ordered,
    ROUND(AVG(item_value), 2)                              AS avg_price
FROM revenue_category_seller_cleaned
WHERE category != 'uncategorized'
AND   order_status = 'delivered'
GROUP BY category, product_id
ORDER BY category, COUNT(*) DESC;