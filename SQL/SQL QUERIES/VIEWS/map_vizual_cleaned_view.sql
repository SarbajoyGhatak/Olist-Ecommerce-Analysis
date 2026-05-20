

CREATE VIEW map_vizual_cleaned_view AS
 WITH base AS (
         SELECT master_table_cleaned.customer_state AS state,
            count(DISTINCT master_table_cleaned.order_id) AS total_orders,
            count(DISTINCT
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = 'delivered'::text) THEN master_table_cleaned.order_id
                    ELSE NULL::character varying
                END) AS delivered_orders,
            count(DISTINCT
                CASE
                    WHEN ((master_table_cleaned.order_status)::text <> 'delivered'::text) THEN master_table_cleaned.order_id
                    ELSE NULL::character varying
                END) AS lost_orders,
            round(sum(master_table_cleaned.revenue_made), 2) AS total_revenue_made,
            round(sum(master_table_cleaned.revenue_lost), 2) AS total_revenue_lost,
            round(sum(
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = ANY ((ARRAY['canceled'::character varying, 'unavailable'::character varying])::text[])) THEN master_table_cleaned.total_order_value
                    ELSE (0)::numeric
                END), 2) AS permanently_lost,
            round(sum(
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = ANY ((ARRAY['processing'::character varying, 'invoiced'::character varying])::text[])) THEN master_table_cleaned.total_order_value
                    ELSE (0)::numeric
                END), 2) AS stuck_in_pipeline,
            round(sum(
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = 'shipped'::text) THEN master_table_cleaned.total_order_value
                    ELSE (0)::numeric
                END), 2) AS in_transit,
            round(avg(master_table_cleaned.total_order_value), 2) AS avg_order_value,
            round((sum(master_table_cleaned.revenue_made) / (NULLIF(count(DISTINCT master_table_cleaned.order_id), 0))::numeric), 2) AS revenue_per_order,
            round(((100.0 * (count(DISTINCT
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = 'canceled'::text) THEN master_table_cleaned.order_id
                    ELSE NULL::character varying
                END))::numeric) / (NULLIF(count(DISTINCT master_table_cleaned.order_id), 0))::numeric), 2) AS cancellation_rate_pct,
            round(((100.0 * (count(DISTINCT
                CASE
                    WHEN ((master_table_cleaned.order_status)::text = 'delivered'::text) THEN master_table_cleaned.order_id
                    ELSE NULL::character varying
                END))::numeric) / (NULLIF(count(DISTINCT master_table_cleaned.order_id), 0))::numeric), 2) AS delivery_success_rate_pct,
            round(((100.0 * sum(master_table_cleaned.revenue_lost)) / NULLIF((sum(master_table_cleaned.revenue_made) + sum(master_table_cleaned.revenue_lost)), (0)::numeric)), 2) AS loss_rate_pct
           FROM master_table_cleaned
          GROUP BY master_table_cleaned.customer_state
        ), loss_thresholds AS (
         SELECT percentile_cont((0.33)::double precision) WITHIN GROUP (ORDER BY ((base.loss_rate_pct)::double precision)) AS p33,
            percentile_cont((0.66)::double precision) WITHIN GROUP (ORDER BY ((base.loss_rate_pct)::double precision)) AS p66
           FROM base
        ), ranked AS (
         SELECT base.state,
            base.total_orders,
            base.delivered_orders,
            base.lost_orders,
            base.total_revenue_made,
            base.total_revenue_lost,
            base.permanently_lost,
            base.stuck_in_pipeline,
            base.in_transit,
            base.avg_order_value,
            base.revenue_per_order,
            base.cancellation_rate_pct,
            base.delivery_success_rate_pct,
            base.loss_rate_pct,
            rank() OVER (ORDER BY base.total_revenue_made DESC) AS revenue_rank,
            rank() OVER (ORDER BY base.total_revenue_lost DESC) AS loss_rank,
            rank() OVER (ORDER BY base.loss_rate_pct DESC) AS loss_rate_rank,
            count(*) OVER () AS total_states
           FROM base
        ), with_tiers AS (
         SELECT r.state,
            r.total_orders,
            r.delivered_orders,
            r.lost_orders,
            r.total_revenue_made,
            r.total_revenue_lost,
            r.permanently_lost,
            r.stuck_in_pipeline,
            r.in_transit,
            r.avg_order_value,
            r.revenue_per_order,
            r.cancellation_rate_pct,
            r.delivery_success_rate_pct,
            r.loss_rate_pct,
            r.revenue_rank,
            r.loss_rank,
            r.loss_rate_rank,
            r.total_states,
                CASE
                    WHEN (r.revenue_rank <= 7) THEN 3
                    WHEN (r.revenue_rank <= 17) THEN 2
                    ELSE 1
                END AS colour_score,
                CASE
                    WHEN (r.revenue_rank <= 7) THEN 'top_performer'::text
                    WHEN (r.revenue_rank <= 17) THEN 'average'::text
                    ELSE 'worst_performer'::text
                END AS performance_tier,
                CASE
                    WHEN ((r.loss_rate_pct)::double precision >= t.p66) THEN 'high_loss'::text
                    WHEN ((r.loss_rate_pct)::double precision >= t.p33) THEN 'medium_loss'::text
                    ELSE 'low_loss'::text
                END AS loss_tier,
                CASE
                    WHEN ((r.loss_rate_pct)::double precision >= t.p66) THEN 3
                    WHEN ((r.loss_rate_pct)::double precision >= t.p33) THEN 2
                    ELSE 1
                END AS loss_colour_score
           FROM (ranked r
             CROSS JOIN loss_thresholds t)
        )
 SELECT state,
    'Brazil'::text AS country,
        CASE state
            WHEN 'SP'::text THEN 'Sao Paulo'::text
            WHEN 'RJ'::text THEN 'Rio de Janeiro'::text
            WHEN 'MG'::text THEN 'Minas Gerais'::text
            WHEN 'BA'::text THEN 'Bahia'::text
            WHEN 'RS'::text THEN 'Rio Grande do Sul'::text
            WHEN 'PR'::text THEN 'Parana'::text
            WHEN 'SC'::text THEN 'Santa Catarina'::text
            WHEN 'GO'::text THEN 'Goias'::text
            WHEN 'PE'::text THEN 'Pernambuco'::text
            WHEN 'CE'::text THEN 'Ceara'::text
            WHEN 'PA'::text THEN 'Para'::text
            WHEN 'MA'::text THEN 'Maranhao'::text
            WHEN 'MT'::text THEN 'Mato Grosso'::text
            WHEN 'MS'::text THEN 'Mato Grosso do Sul'::text
            WHEN 'PB'::text THEN 'Paraiba'::text
            WHEN 'RN'::text THEN 'Rio Grande do Norte'::text
            WHEN 'AL'::text THEN 'Alagoas'::text
            WHEN 'PI'::text THEN 'Piaui'::text
            WHEN 'ES'::text THEN 'Espirito Santo'::text
            WHEN 'DF'::text THEN 'Distrito Federal'::text
            WHEN 'SE'::text THEN 'Sergipe'::text
            WHEN 'AM'::text THEN 'Amazonas'::text
            WHEN 'RO'::text THEN 'Rondonia'::text
            WHEN 'TO'::text THEN 'Tocantins'::text
            WHEN 'AC'::text THEN 'Acre'::text
            WHEN 'AP'::text THEN 'Amapa'::text
            WHEN 'RR'::text THEN 'Roraima'::text
            ELSE NULL::text
        END AS state_full_name,
        CASE state
            WHEN 'SP'::text THEN '-23.5505'::numeric
            WHEN 'RJ'::text THEN '-22.9068'::numeric
            WHEN 'MG'::text THEN '-19.9167'::numeric
            WHEN 'BA'::text THEN '-12.9714'::numeric
            WHEN 'RS'::text THEN '-30.0346'::numeric
            WHEN 'PR'::text THEN '-25.4284'::numeric
            WHEN 'SC'::text THEN '-27.5954'::numeric
            WHEN 'GO'::text THEN '-16.6869'::numeric
            WHEN 'PE'::text THEN '-8.0539'::numeric
            WHEN 'CE'::text THEN '-3.7172'::numeric
            WHEN 'PA'::text THEN '-1.4558'::numeric
            WHEN 'MA'::text THEN '-2.5297'::numeric
            WHEN 'MT'::text THEN '-15.6014'::numeric
            WHEN 'MS'::text THEN '-20.4428'::numeric
            WHEN 'PB'::text THEN '-7.1195'::numeric
            WHEN 'RN'::text THEN '-5.7945'::numeric
            WHEN 'AL'::text THEN '-9.6658'::numeric
            WHEN 'PI'::text THEN '-5.0920'::numeric
            WHEN 'ES'::text THEN '-20.3155'::numeric
            WHEN 'DF'::text THEN '-15.7801'::numeric
            WHEN 'SE'::text THEN '-10.9472'::numeric
            WHEN 'AM'::text THEN '-3.1190'::numeric
            WHEN 'RO'::text THEN '-8.7612'::numeric
            WHEN 'TO'::text THEN '-10.1753'::numeric
            WHEN 'AC'::text THEN '-9.9754'::numeric
            WHEN 'AP'::text THEN 0.0349
            WHEN 'RR'::text THEN 2.8235
            ELSE NULL::numeric
        END AS latitude,
        CASE state
            WHEN 'SP'::text THEN '-46.6333'::numeric
            WHEN 'RJ'::text THEN '-43.1729'::numeric
            WHEN 'MG'::text THEN '-43.9345'::numeric
            WHEN 'BA'::text THEN '-38.5014'::numeric
            WHEN 'RS'::text THEN '-51.2177'::numeric
            WHEN 'PR'::text THEN '-49.2733'::numeric
            WHEN 'SC'::text THEN '-48.5480'::numeric
            WHEN 'GO'::text THEN '-49.2648'::numeric
            WHEN 'PE'::text THEN '-34.8811'::numeric
            WHEN 'CE'::text THEN '-38.5434'::numeric
            WHEN 'PA'::text THEN '-48.5044'::numeric
            WHEN 'MA'::text THEN '-44.3028'::numeric
            WHEN 'MT'::text THEN '-56.0974'::numeric
            WHEN 'MS'::text THEN '-54.6462'::numeric
            WHEN 'PB'::text THEN '-34.8641'::numeric
            WHEN 'RN'::text THEN '-35.2110'::numeric
            WHEN 'AL'::text THEN '-35.7350'::numeric
            WHEN 'PI'::text THEN '-42.8019'::numeric
            WHEN 'ES'::text THEN '-40.3128'::numeric
            WHEN 'DF'::text THEN '-47.9292'::numeric
            WHEN 'SE'::text THEN '-37.0731'::numeric
            WHEN 'AM'::text THEN '-60.0212'::numeric
            WHEN 'RO'::text THEN '-63.9004'::numeric
            WHEN 'TO'::text THEN '-48.2982'::numeric
            WHEN 'AC'::text THEN '-67.8243'::numeric
            WHEN 'AP'::text THEN '-51.0694'::numeric
            WHEN 'RR'::text THEN '-60.6758'::numeric
            ELSE NULL::numeric
        END AS longitude,
    total_orders,
    delivered_orders,
    lost_orders,
    total_revenue_made,
    total_revenue_lost,
    permanently_lost,
    stuck_in_pipeline,
    in_transit,
    avg_order_value,
    revenue_per_order,
    cancellation_rate_pct,
    delivery_success_rate_pct,
    loss_rate_pct,
    revenue_rank,
    loss_rank,
    loss_rate_rank,
    colour_score,
    performance_tier,
    loss_tier,
    loss_colour_score
   FROM with_tiers
  ORDER BY total_revenue_lost DESC;