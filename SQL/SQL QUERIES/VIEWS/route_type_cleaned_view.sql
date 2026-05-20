CREATE VIEW route_type_cleaned_view AS
 SELECT delivery_route_type,
    count(*) AS total_orders,
    round(((100.0 * (count(
        CASE
            WHEN (delay_vs_estimate > (0)::numeric) THEN 1
            ELSE NULL::integer
        END))::numeric) / (NULLIF(count(*), 0))::numeric), 1) AS late_rate_pct,
    round(avg(
        CASE
            WHEN (delay_vs_estimate > (0)::numeric) THEN delay_vs_estimate
            ELSE NULL::numeric
        END), 1) AS avg_days_late,
    round(avg((review_score)::numeric), 2) AS avg_review_score,
    round(avg(days_in_transit), 1) AS avg_transit_days
   FROM vw_delivery_performance
  WHERE (delivery_route_type IS NOT NULL)
  GROUP BY delivery_route_type;