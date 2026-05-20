select*(5) from vw_funnel_master 

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value)                               AS total_payment_value,
        MAX(payment_installments)                        AS payment_installments,
        (ARRAY_AGG(payment_type ORDER BY payment_value DESC))[1]
                                                         AS primary_payment_type
    FROM order_payments
    GROUP BY order_id
),

item_summary AS (
    SELECT
        oi.order_id,
        COUNT(*)                                         AS total_items,
        SUM(oi.price + oi.freight_value)                 AS total_order_value,
        SUM(p.product_weight_g)                          AS total_weight_g,
        MIN(oi.shipping_limit_date)                      AS shipping_limit_date,

        STRING_AGG(
            DISTINCT COALESCE(ct.product_category_name_english, 'uncategorized'),
            ', '
        )                                                AS all_categories,

        COUNT(DISTINCT ct.product_category_name_english) AS category_count,

        (ARRAY_AGG(
            COALESCE(ct.product_category_name_english, 'uncategorized')
            ORDER BY oi.price DESC
        ))[1]                                            AS primary_category,

        (ARRAY_AGG(oi.seller_id ORDER BY oi.price DESC))[1]
                                                         AS primary_seller_id

    FROM order_items oi
    LEFT JOIN products p
        ON oi.product_id           = p.product_id
    LEFT JOIN product_category_name_translation ct
        ON p.product_category_name = ct.product_category_name
    GROUP BY oi.order_id
),

seller_info AS (
    SELECT
        seller_id,
        seller_state,
        seller_city,
        seller_zip_code_prefix     AS seller_zip
    FROM sellers
)

SELECT
    -- orders (spine)
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- customer
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    c.customer_zip_code_prefix     AS customer_zip,

    -- payment
    ps.primary_payment_type,
    ps.total_payment_value,
    ps.payment_installments,

    -- items / product
    i.primary_category,
    i.all_categories,
    i.category_count,
    i.total_items,
    i.total_weight_g,
    i.total_order_value,
    i.shipping_limit_date,

    -- seller
    i.primary_seller_id,
    s.seller_state,
    s.seller_city,
    s.seller_zip,

    -- derived: funnel time gaps
    DATE_PART('day', o.order_approved_at - o.order_purchase_timestamp)
                                                         AS days_to_approve,

    DATE_PART('day', o.order_delivered_carrier_date - o.order_approved_at)
                                                         AS days_to_ship,

    DATE_PART('day', o.order_delivered_customer_date - o.order_delivered_carrier_date)
                                                         AS days_in_transit,

    DATE_PART('day', o.order_delivered_customer_date - o.order_estimated_delivery_date)
                                                         AS delay_vs_estimate,

    -- derived: seller late flag
    DATE_PART('day', o.order_delivered_carrier_date - i.shipping_limit_date)
                                                         AS seller_delay_days,

    -- derived: inter-state flag
    CASE
        WHEN c.customer_state = s.seller_state
        THEN 'intra_state'
        ELSE 'inter_state'
    END                                                  AS delivery_route_type,

    -- derived: basket type
    CASE
        WHEN i.category_count = 1  THEN 'single_category'
        WHEN i.category_count = 2  THEN 'mixed_2'
        WHEN i.category_count >= 3 THEN 'mixed_3_plus'
        ELSE 'unknown'
    END                                                  AS basket_type,

    -- derived: weight bucket
    CASE
        WHEN i.total_weight_g < 500   THEN 'light (<500g)'
        WHEN i.total_weight_g < 2000  THEN 'medium (500g-2kg)'
        WHEN i.total_weight_g < 10000 THEN 'heavy (2kg-10kg)'
        ELSE                               'very heavy (>10kg)'
    END                                                  AS weight_bucket,

    -- derived: revenue tags
    CASE
        WHEN o.order_status = 'delivered'
        THEN i.total_order_value ELSE 0
    END                                                  AS revenue_made,

    CASE
        WHEN o.order_status != 'delivered'
        THEN i.total_order_value ELSE 0
    END                                                  AS revenue_lost,

    -- derived: funnel stage reached
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL THEN 'delivered'
        WHEN o.order_delivered_carrier_date  IS NOT NULL THEN 'shipped'
        WHEN o.order_approved_at             IS NOT NULL THEN 'approved'
        ELSE                                                  'purchased_only'
    END                                                  AS funnel_stage_reached

FROM orders o
LEFT JOIN customers c
    ON o.customer_id       = c.customer_id
LEFT JOIN payment_summary ps
    ON o.order_id          = ps.order_id
LEFT JOIN item_summary i
    ON o.order_id          = i.order_id
LEFT JOIN seller_info s
    ON i.primary_seller_id = s.seller_id

ORDER BY o.order_purchase_timestamp;