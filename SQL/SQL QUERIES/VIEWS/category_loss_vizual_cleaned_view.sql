CREATE VIEW category_loss_vizual_cleaned_view AS

	WITH category_metrics AS (
	         SELECT r_1.category,
	            count(DISTINCT r_1.order_id) AS total_orders,
	            round(sum(r_1.item_revenue_lost), 2) AS revenue_lost,
	            round(sum(
	                CASE
	                    WHEN ((r_1.is_not_delivered = 1) AND (r_1.is_canceled = 0)) THEN r_1.item_revenue_lost
	                    ELSE (0)::numeric
	                END), 2) AS permanently_lost,
	            round(avg(r_1.item_value), 2) AS avg_order_value,
	            round((avg(r_1.is_canceled) * (100)::numeric), 2) AS cancellation_rate_pct,
	            round((avg(r_1.is_not_delivered) * (100)::numeric), 2) AS non_delivery_rate_pct,
	            rank() OVER (ORDER BY (sum(r_1.item_revenue_lost)) DESC) AS loss_rank
	           FROM revenue_category_seller_cleaned r_1
	          WHERE ((r_1.category)::text <> 'uncategorized'::text)
	          GROUP BY r_1.category
	         HAVING (count(DISTINCT r_1.order_id) >= 10)
	        ), top_losing_product AS (
	         SELECT DISTINCT ON (r_1.category) r_1.category,
	            r_1.product_id AS top_losing_product_id,
	            round(sum(r_1.item_revenue_lost) OVER (PARTITION BY r_1.category, r_1.product_id), 2) AS product_revenue_lost,
	            count(r_1.order_id) OVER (PARTITION BY r_1.category, r_1.product_id) AS product_lost_orders
	           FROM revenue_category_seller_cleaned r_1
	          WHERE (((r_1.category)::text <> 'uncategorized'::text) AND (r_1.is_not_delivered = 1))
	          ORDER BY r_1.category, (sum(r_1.item_revenue_lost) OVER (PARTITION BY r_1.category, r_1.product_id)) DESC
	        ), category_rating AS (
	         SELECT r_1.category,
	            round(avg((m.review_score)::numeric), 2) AS avg_review_score
	           FROM (revenue_category_seller_cleaned r_1
	             LEFT JOIN master_table_cleaned m ON (((r_1.order_id)::text = (m.order_id)::text)))
	          WHERE (((r_1.category)::text <> 'uncategorized'::text) AND (m.review_score IS NOT NULL))
	          GROUP BY r_1.category
	        )
	 SELECT c.category,
	    c.total_orders,
	    c.revenue_lost,
	    c.permanently_lost,
	    c.avg_order_value,
	    c.cancellation_rate_pct,
	    c.non_delivery_rate_pct,
	    c.loss_rank,
	    p.top_losing_product_id,
	    p.product_revenue_lost,
	    p.product_lost_orders,
	    r.avg_review_score
	   FROM ((category_metrics c
	     LEFT JOIN top_losing_product p ON (((c.category)::text = (p.category)::text)))
	     LEFT JOIN category_rating r ON (((c.category)::text = (r.category)::text)))
	  WHERE (c.loss_rank <= 10)
	  ORDER BY c.loss_rank;