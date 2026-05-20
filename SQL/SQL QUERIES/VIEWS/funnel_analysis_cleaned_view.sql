CREATE VIEW funnel_analysis_cleaned_view AS
	 SELECT 'purchased'::text AS funnel_stage,
	    1 AS stage_order,
	    count(DISTINCT master_table_cleaned.order_id) AS order_count,
	    round(sum(master_table_cleaned.total_order_value), 2) AS revenue_at_stage
	   FROM master_table_cleaned
	UNION ALL
	 SELECT 'approved'::text AS funnel_stage,
	    2 AS stage_order,
	    count(DISTINCT master_table_cleaned.order_id) AS order_count,
	    round(sum(master_table_cleaned.total_order_value), 2) AS revenue_at_stage
	   FROM master_table_cleaned
	  WHERE (master_table_cleaned.order_approved_at IS NOT NULL)
	UNION ALL
	 SELECT 'shipped'::text AS funnel_stage,
	    3 AS stage_order,
	    count(DISTINCT master_table_cleaned.order_id) AS order_count,
	    round(sum(master_table_cleaned.total_order_value), 2) AS revenue_at_stage
	   FROM master_table_cleaned
	  WHERE (master_table_cleaned.order_delivered_carrier_date IS NOT NULL)
	UNION ALL
	 SELECT 'delivered'::text AS funnel_stage,
	    4 AS stage_order,
	    count(DISTINCT master_table_cleaned.order_id) AS order_count,
	    round(sum(master_table_cleaned.total_order_value), 2) AS revenue_at_stage
	   FROM master_table_cleaned
	  WHERE (master_table_cleaned.order_delivered_customer_date IS NOT NULL)
	  ORDER BY 2;