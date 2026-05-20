CREATE VIEW regions_affected_by_delays_cleaned_view AS
	 SELECT customer_state,
	    count(*) AS total_orders,
	    count(
	        CASE
	            WHEN (delay_vs_estimate > (0)::numeric) THEN 1
	            ELSE NULL::integer
	        END) AS late_orders,
	    count(
	        CASE
	            WHEN (delay_vs_estimate <= (0)::numeric) THEN 1
	            ELSE NULL::integer
	        END) AS on_time_orders,
	    round(((100.0 * (count(
	        CASE
	            WHEN (delay_vs_estimate > (0)::numeric) THEN 1
	            ELSE NULL::integer
	        END))::numeric) / (NULLIF(count(*), 0))::numeric), 1) AS late_order_rate_pct,
	    round(avg(
	        CASE
	            WHEN (delay_vs_estimate > (0)::numeric) THEN delay_vs_estimate
	            ELSE NULL::numeric
	        END), 1) AS avg_days_late_when_late,
	    round(avg((review_score)::numeric), 2) AS avg_review_score
	   FROM vw_delivery_performance
	  GROUP BY customer_state
	  ORDER BY (round(((100.0 * (count(
	        CASE
	            WHEN (delay_vs_estimate > (0)::numeric) THEN 1
	            ELSE NULL::integer
	        END))::numeric) / (NULLIF(count(*), 0))::numeric), 1)) DESC;