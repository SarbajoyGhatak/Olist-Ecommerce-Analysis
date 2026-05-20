SELECT
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT order_id)        AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM MASTER_TABLE;


SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)                    AS null_order_id,
    COUNT(*) FILTER (WHERE order_status IS NULL)                AS null_order_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL)    AS null_purchase_ts,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL)           AS null_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_delivered_date,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_date,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL)          AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_state IS NULL)              AS null_customer_state,
    COUNT(*) FILTER (WHERE customer_city IS NULL)               AS null_customer_city,
    COUNT(*) FILTER (WHERE customer_zip IS NULL)                AS null_customer_zip,
    COUNT(*) FILTER (WHERE primary_payment_type IS NULL)        AS null_payment_type,
    COUNT(*) FILTER (WHERE total_payment_value IS NULL)         AS null_payment_value,
    COUNT(*) FILTER (WHERE payment_installments IS NULL)        AS null_installments,
    COUNT(*) FILTER (WHERE primary_category IS NULL)            AS null_primary_category,
    COUNT(*) FILTER (WHERE all_categories IS NULL)              AS null_all_categories,
    COUNT(*) FILTER (WHERE total_weight_g IS NULL)              AS null_weight,
    COUNT(*) FILTER (WHERE total_order_value IS NULL)           AS null_order_value,
    COUNT(*) FILTER (WHERE primary_seller_id IS NULL)           AS null_seller_id,
    COUNT(*) FILTER (WHERE seller_state IS NULL)                AS null_seller_state,
    COUNT(*) FILTER (WHERE review_score IS NULL)                AS null_review_score,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL)        AS null_comment_title,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL)      AS null_comment_message,
    COUNT(*) FILTER (WHERE review_sentiment IS NULL)            AS null_sentiment
FROM MASTER_TABLE;


SELECT
    order_status,
    COUNT(*)                        AS total_orders,
    ROUND(100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (), 2)   AS pct_of_total
FROM MASTER_TABLE
GROUP BY order_status
ORDER BY total_orders DESC;


SELECT
    MIN(order_purchase_timestamp)   AS earliest_order,
    MAX(order_purchase_timestamp)   AS latest_order,
    MIN(order_approved_at)          AS earliest_approval,
    MAX(order_delivered_customer_date) AS latest_delivery,
    -- orders where approval came BEFORE purchase (impossible)
    COUNT(*) FILTER (
        WHERE order_approved_at < order_purchase_timestamp
    )                               AS approval_before_purchase,
    -- orders where delivery came BEFORE carrier pickup (impossible)
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date < order_delivered_carrier_date
    )                               AS delivery_before_carrier,
    -- orders where carrier pickup came BEFORE approval (impossible)
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date < order_approved_at
    )                               AS carrier_before_approval
FROM MASTER_TABLE;


SELECT
    MIN(total_weight_g)             AS min_weight,
    MAX(total_weight_g)             AS max_weight,
    AVG(total_weight_g)             AS avg_weight,
    COUNT(*) FILTER (WHERE total_weight_g <= 0)    AS zero_or_neg_weight,
	MIN(total_order_value)          AS min_order_value,
    MAX(total_order_value)          AS max_order_value,
    AVG(total_order_value)          AS avg_order_value,
    COUNT(*) FILTER (WHERE total_order_value <= 0) AS zero_or_neg_value,
	MIN(total_payment_value)        AS min_payment,
    MAX(total_payment_value)        AS max_payment,
    COUNT(*) FILTER (WHERE total_payment_value <= 0) AS zero_or_neg_payment,
 	MIN(review_score)               AS min_review,
    MAX(review_score)               AS max_review,
    COUNT(*) FILTER (WHERE review_score NOT IN (1,2,3,4,5)) AS invalid_review_score
FROM MASTER_TABLE;



SELECT
    funnel_stage_reached,
    COUNT(*)                        AS orders
FROM MASTER_TABLE
GROUP BY funnel_stage_reached;

SELECT
    basket_type,
    COUNT(*)                        AS orders
FROM MASTER_TABLE
GROUP BY basket_type;

SELECT
    weight_bucket,
    COUNT(*)                        AS orders
FROM MASTER_TABLE
GROUP BY weight_bucket;

SELECT
    delivery_route_type,
    COUNT(*)                        AS orders
FROM MASTER_TABLE
GROUP BY delivery_route_type;


SELECT
    COUNT(*) FILTER (
        WHERE total_payment_value IS NULL
    )                               AS orders_with_no_payment,
    COUNT(*) FILTER (
        WHERE ABS(total_order_value - total_payment_value) > 1
    )                               AS value_mismatch_orders,
    AVG(total_order_value - total_payment_value)
                                    AS avg_value_gap
FROM MASTER_TABLE;


SELECT
    has_comment,
    COUNT(*)                        AS orders,
    COUNT(*) FILTER (
        WHERE review_comment_message IS NOT NULL
    )                               AS has_actual_message
FROM MASTER_TABLE
GROUP BY has_comment;

SELECT
    order_id,
    COUNT(*)                    AS row_count,
    COUNT(DISTINCT review_score) AS distinct_scores,
    COUNT(DISTINCT review_comment_message) AS distinct_messages
FROM MASTER_TABLE
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;



WITH duplicate_orders AS (
    SELECT
        order_id,
        COUNT(*)                            AS row_count,
        COUNT(DISTINCT review_score)        AS distinct_scores,
        COUNT(DISTINCT review_comment_message) AS distinct_messages
    FROM MASTER_TABLE
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
SELECT
    -- Type 1: pure duplicates (same score, no messages)
    COUNT(*) FILTER (
        WHERE distinct_scores = 1
        AND distinct_messages <= 1
    )                                       AS type1_pure_duplicates,
	-- Type 2: conflicting scores
    COUNT(*) FILTER (
        WHERE distinct_scores > 1
    )                                       AS type2_conflicting_scores,
	-- Type 3: same score, different messages
    COUNT(*) FILTER (
        WHERE distinct_scores = 1
        AND distinct_messages > 1
    )                                       AS type3_different_messages,
	SUM(row_count) - COUNT(*)               AS total_extra_rows
FROM duplicate_orders;



CREATE TABLE reviews_deduped_type3 AS
SELECT DISTINCT ON (order_id)
    order_id,
    review_score,
    review_comment_title,
    -- concatenate all distinct non-null messages with separator
    STRING_AGG(
        review_comment_message, ' | '
        ORDER BY review_creation_date
    ) FILTER (WHERE review_comment_message IS NOT NULL)
                                    AS review_comment_message,
    review_creation_date,
    review_sentiment,
    has_comment
FROM MASTER_TABLE
GROUP BY
    order_id,
    review_score,
    review_comment_title,
    review_creation_date,
    review_sentiment,
    has_comment
ORDER BY order_id, review_creation_date DESC;
CREATE TABLE reviews_deduped_final AS
SELECT DISTINCT ON (order_id) *
FROM reviews_deduped_type3
ORDER BY order_id, review_creation_date DESC NULLS LAST;
SELECT
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT order_id)        AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS remaining_duplicates
FROM reviews_deduped_final;


CREATE TABLE MASTER_TABLE_CLEANED AS
WITH deduplicated AS (
    SELECT DISTINCT ON (order_id) *
    FROM MASTER_TABLE
    ORDER BY order_id, review_creation_date DESC NULLS LAST
)
SELECT
    -- all original columns
    order_id, order_status, order_purchase_timestamp,
    order_approved_at, order_delivered_carrier_date,
    order_delivered_customer_date, order_estimated_delivery_date,
    customer_unique_id, customer_state, customer_city, customer_zip,
    primary_payment_type, total_payment_value, payment_installments,
    primary_category, all_categories, category_count,
    total_items, total_order_value, shipping_limit_date,
    primary_seller_id, seller_state, seller_city, seller_zip,
    delay_vs_estimate, seller_delay_days,
    delivery_route_type, basket_type, weight_bucket,
    revenue_made, revenue_lost, funnel_stage_reached,
    review_score, review_comment_title,
    review_comment_message, review_creation_date,
    review_sentiment, has_comment,
	CASE
        WHEN order_delivered_carrier_date < order_approved_at
        THEN NULL ELSE days_to_approve
    END                             AS days_to_approve,
	CASE
        WHEN order_delivered_carrier_date < order_approved_at
        THEN NULL ELSE days_to_ship
    END                             AS days_to_ship_clean,
	CASE
        WHEN order_delivered_customer_date < order_delivered_carrier_date
        THEN NULL ELSE days_in_transit
    END                             AS days_in_transit_clean,
	-- fix zero weights
    CASE
        WHEN total_weight_g = 0 THEN NULL
        ELSE total_weight_g
    END                             AS total_weight_g_clean,
	-- fix unknown basket type
    CASE
        WHEN basket_type = 'unknown' THEN 'single_category'
        ELSE basket_type
    END                             AS basket_type_clean,
	-- fix null primary category
    COALESCE(primary_category, 'uncategorized')
                                    AS primary_category_clean,
	-- payment gap flag
    ROUND(
        COALESCE(total_payment_value, 0) - total_order_value
    , 2)                            AS value_gap,
	CASE
        WHEN total_payment_value IS NULL
          OR total_payment_value = 0
        THEN TRUE ELSE FALSE
    END                             AS is_payment_missing,
	-- impossible timestamp flags (keep for documentation)
    CASE
        WHEN order_delivered_carrier_date < order_approved_at
        THEN TRUE ELSE FALSE
    END                             AS flag_carrier_before_approval,
	CASE
        WHEN order_delivered_customer_date < order_delivered_carrier_date
        THEN TRUE ELSE FALSE
    END                             AS flag_delivery_before_carrier
FROM deduplicated;

SELECT
    COUNT(*)                        AS total_rows,
    COUNT(DISTINCT order_id)        AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS remaining_duplicates,
    COUNT(*) FILTER (
        WHERE flag_carrier_before_approval = TRUE
    )                               AS flagged_carrier_issues,
    COUNT(*) FILTER (
        WHERE flag_delivery_before_carrier = TRUE
    )                               AS flagged_delivery_issues,
    COUNT(*) FILTER (
        WHERE total_weight_g_clean IS NULL
    )                               AS null_weights,
    COUNT(*) FILTER (
        WHERE basket_type_clean = 'unknown'
    )                               AS unknown_baskets,
    COUNT(*) FILTER (
        WHERE primary_category_clean = 'uncategorized'
    )                               AS uncategorized_products,
    COUNT(*) FILTER (
        WHERE is_payment_missing = TRUE
    )                               AS missing_payments,
    COUNT(*) FILTER (
        WHERE days_to_ship_clean IS NULL
        AND order_approved_at IS NOT NULL
        AND order_delivered_carrier_date IS NOT NULL
    )                               AS nulled_ship_days,
    COUNT(*) FILTER (
        WHERE days_in_transit_clean IS NULL
        AND order_delivered_carrier_date IS NOT NULL
        AND order_delivered_customer_date IS NOT NULL
    )                               AS nulled_transit_days
FROM MASTER_TABLE_CLEANED;