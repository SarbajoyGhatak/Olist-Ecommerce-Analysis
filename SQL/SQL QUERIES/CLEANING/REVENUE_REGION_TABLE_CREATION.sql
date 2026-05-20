CREATE VIEW REVENUE_REGION_TABLE AS
WITH item_summary AS (
    SELECT
        order_id,
        SUM(price + freight_value)  AS total_order_value
    FROM order_items
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.order_status,
    c.customer_city,
    c.customer_state,
    i.total_order_value,
    o.order_purchase_timestamp
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN item_summary i
    ON o.order_id = i.order_id;



SELECT *
from REVENUE_REGION_TABLE;