CREATE VIEW revenue_status_vizual_cleaned_view AS
 SELECT revenue_status,
    count(DISTINCT order_id) AS affected_orders,
    round(sum(item_value), 2) AS total_value,
    round(((100.0 * sum(item_value)) / sum(sum(item_value)) OVER ()), 2) AS pct_of_total,
    round(avg(item_value), 2) AS avg_item_value
   FROM revenue_category_seller_cleaned
  GROUP BY revenue_status
  ORDER BY (round(sum(item_value), 2)) DESC;