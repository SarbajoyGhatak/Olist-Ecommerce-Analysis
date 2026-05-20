CREATE VIEW mom_chart_vizual_cleaned_view AS
 WITH monthly AS (
         SELECT date_trunc('month'::text, master_table_cleaned.order_purchase_timestamp) AS month,
            round(sum(master_table_cleaned.revenue_made), 2) AS revenue_collected,
            round((sum(master_table_cleaned.revenue_made) + sum(
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = ANY ((ARRAY['canceled'::character varying, 'unavailable'::character varying, 'processing'::character varying, 'invoiced'::character varying])::text[])) THEN master_table_cleaned.total_order_value
                    ELSE (0)::numeric
                END)), 2) AS revenue_possible,
            round(sum(
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = ANY ((ARRAY['canceled'::character varying, 'unavailable'::character varying, 'processing'::character varying, 'invoiced'::character varying])::text[])) THEN master_table_cleaned.total_order_value
                    ELSE (0)::numeric
                END), 2) AS real_revenue_lost,
            count(DISTINCT master_table_cleaned.order_id) AS total_orders,
            count(DISTINCT
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = 'delivered'::text) THEN master_table_cleaned.order_id
                    ELSE NULL::character varying
                END) AS delivered_orders
           FROM master_table_cleaned
          WHERE (master_table_cleaned.order_purchase_timestamp >= '2017-01-01 00:00:00'::timestamp without time zone)
          GROUP BY (date_trunc('month'::text, master_table_cleaned.order_purchase_timestamp))
        )
 SELECT month,
    revenue_collected,
    revenue_possible,
    real_revenue_lost,
    total_orders,
    delivered_orders,
    round(((100.0 * (revenue_collected - lag(revenue_collected) OVER (ORDER BY month))) / NULLIF(lag(revenue_collected) OVER (ORDER BY month), (0)::numeric)), 2) AS mom_collected_pct,
    round(((100.0 * (real_revenue_lost - lag(real_revenue_lost) OVER (ORDER BY month))) / NULLIF(lag(real_revenue_lost) OVER (ORDER BY month), (0)::numeric)), 2) AS mom_loss_pct,
    round(((100.0 * real_revenue_lost) / NULLIF(revenue_possible, (0)::numeric)), 2) AS monthly_loss_rate_pct
   FROM monthly
  ORDER BY month;