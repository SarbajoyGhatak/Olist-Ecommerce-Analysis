CREATE VIEW seller_delivery_delays_cleaned_view AS
	 SELECT order_id,
	    order_status,
	    customer_state,
	    primary_seller_id AS seller_id,
	    seller_state,
	    delivery_route_type,
	    weight_bucket,
	    round((delay_vs_estimate)::numeric, 1) AS delay_vs_estimate,
	    round((days_to_ship_clean)::numeric, 1) AS days_to_ship,
	    round((days_in_transit_clean)::numeric, 1) AS days_in_transit,
	    round((seller_delay_days)::numeric, 1) AS seller_delay_days,
	        CASE
	            WHEN (delay_vs_estimate > (0)::double precision) THEN 'late'::text
	            WHEN (delay_vs_estimate <= (0)::double precision) THEN 'on_time'::text
	            ELSE 'unknown'::text
	        END AS delivery_status,
	        CASE
	            WHEN (delay_vs_estimate <= (0)::double precision) THEN 'on time or early'::text
	            WHEN (delay_vs_estimate <= (3)::double precision) THEN '1-3 days late'::text
	            WHEN (delay_vs_estimate <= (7)::double precision) THEN '4-7 days late'::text
	            WHEN (delay_vs_estimate <= (14)::double precision) THEN '8-14 days late'::text
	            ELSE '15+ days late'::text
	        END AS delay_bucket,
	        CASE
	            WHEN (seller_delay_days > (0)::double precision) THEN 'seller_fault'::text
	            WHEN ((delay_vs_estimate > (0)::double precision) AND (seller_delay_days <= (0)::double precision)) THEN 'logistics_fault'::text
	            ELSE 'no_fault'::text
	        END AS fault_type,
	    review_score,
	    review_sentiment,
	    total_order_value,
	    revenue_made,
	    revenue_lost
	   FROM master_table_cleaned
	  WHERE (((order_status)::text = 'delivered'::text) AND (order_delivered_customer_date IS NOT NULL) AND (flag_delivery_before_carrier = false) AND (flag_carrier_before_approval = false));