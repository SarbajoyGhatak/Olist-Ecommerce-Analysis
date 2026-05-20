CREATE VIEW opportunity_categories_vizual_cleaned_view AS
 WITH category_base AS (
         SELECT revenue_category_seller_cleaned.category,
            count(DISTINCT revenue_category_seller_cleaned.order_id) AS total_orders,
            round(avg(revenue_category_seller_cleaned.item_value), 2) AS avg_price,
            round(sum(revenue_category_seller_cleaned.item_revenue_made), 2) AS revenue_made,
            round(sum(revenue_category_seller_cleaned.item_revenue_lost), 2) AS revenue_lost,
            round((avg(revenue_category_seller_cleaned.is_canceled) * (100)::numeric), 2) AS cancellation_rate_pct
           FROM revenue_category_seller_cleaned
          WHERE ((revenue_category_seller_cleaned.category)::text <> 'uncategorized'::text)
          GROUP BY revenue_category_seller_cleaned.category
         HAVING (count(DISTINCT revenue_category_seller_cleaned.order_id) >= 10)
        ), ranked AS (
         SELECT category_base.category,
            category_base.total_orders,
            category_base.avg_price,
            category_base.revenue_made,
            category_base.revenue_lost,
            category_base.cancellation_rate_pct,
            count(*) OVER () AS total_categories,
            rank() OVER (ORDER BY category_base.avg_price DESC) AS price_rank,
            rank() OVER (ORDER BY category_base.total_orders) AS low_volume_rank
           FROM category_base
        ), with_tier AS (
         SELECT ranked.category,
            ranked.total_orders,
            ranked.avg_price,
            ranked.revenue_made,
            ranked.revenue_lost,
            ranked.cancellation_rate_pct,
            ranked.total_categories,
            ranked.price_rank,
            ranked.low_volume_rank,
            round((((ranked.price_rank + ranked.low_volume_rank))::numeric / 2.0), 1) AS opportunity_score,
                CASE
                    WHEN (((ranked.price_rank)::numeric <= round(((ranked.total_categories)::numeric * 0.33))) AND ((ranked.low_volume_rank)::numeric <= round(((ranked.total_categories)::numeric * 0.33)))) THEN 'high_opportunity'::text
                    WHEN (((ranked.price_rank)::numeric <= round(((ranked.total_categories)::numeric * 0.50))) AND ((ranked.low_volume_rank)::numeric <= round(((ranked.total_categories)::numeric * 0.50)))) THEN 'medium_opportunity'::text
                    ELSE 'monitor'::text
                END AS opportunity_tier
           FROM ranked
        )
 SELECT category,
    total_orders,
    avg_price,
    revenue_made,
    revenue_lost,
    cancellation_rate_pct,
    price_rank,
    low_volume_rank,
    opportunity_score,
    opportunity_tier,
    total_categories
   FROM with_tier
  WHERE (opportunity_tier = ANY (ARRAY['high_opportunity'::text, 'medium_opportunity'::text]))
  ORDER BY opportunity_tier, opportunity_score DESC;