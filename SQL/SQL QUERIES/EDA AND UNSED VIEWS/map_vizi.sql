DROP VIEW IF EXISTS map_viz_v2;
DROP VIEW IF EXISTS map_viz;

CREATE VIEW map_viz AS
WITH base AS (
    SELECT
        customer_state                                          AS state,
        COUNT(DISTINCT order_id)                               AS total_orders,
        COUNT(DISTINCT CASE WHEN order_status = 'delivered'
            THEN order_id END)                                 AS delivered_orders,
        COUNT(DISTINCT CASE WHEN order_status != 'delivered'
            THEN order_id END)                                 AS lost_orders,
        ROUND(SUM(revenue_made), 2)                            AS total_revenue_made,
        ROUND(SUM(revenue_lost), 2)                            AS total_revenue_lost,
        ROUND(SUM(CASE WHEN order_status IN
            ('canceled','unavailable','processing','invoiced')
            THEN total_order_value ELSE 0 END), 2)             AS money_stuck,
        ROUND(AVG(total_order_value), 2)                       AS avg_order_value,
        ROUND(SUM(revenue_made) /
            NULLIF(COUNT(DISTINCT order_id), 0), 2)            AS revenue_per_order,
        ROUND(100.0 *
            COUNT(DISTINCT CASE WHEN order_status = 'canceled'
                THEN order_id END) /
            NULLIF(COUNT(DISTINCT order_id), 0), 2)            AS cancellation_rate_pct,
        ROUND(100.0 *
            COUNT(DISTINCT CASE WHEN order_status = 'delivered'
                THEN order_id END) /
            NULLIF(COUNT(DISTINCT order_id), 0), 2)            AS delivery_success_rate_pct,
        ROUND(100.0 * SUM(revenue_lost) /
            NULLIF(SUM(revenue_made) +
                SUM(revenue_lost), 0), 2)                      AS loss_rate_pct
    FROM master_table_cleaned
    GROUP BY customer_state
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY total_revenue_made DESC)         AS revenue_rank
    FROM base
)
SELECT
    r.state,
    'Brazil'                                                   AS country,
    CASE r.state
        WHEN 'SP' THEN 'São Paulo'        WHEN 'RJ' THEN 'Rio de Janeiro'
        WHEN 'MG' THEN 'Minas Gerais'     WHEN 'BA' THEN 'Bahia'
        WHEN 'RS' THEN 'Rio Grande do Sul' WHEN 'PR' THEN 'Paraná'
        WHEN 'SC' THEN 'Santa Catarina'   WHEN 'GO' THEN 'Goiás'
        WHEN 'PE' THEN 'Pernambuco'       WHEN 'CE' THEN 'Ceará'
        WHEN 'PA' THEN 'Pará'             WHEN 'MA' THEN 'Maranhão'
        WHEN 'MT' THEN 'Mato Grosso'      WHEN 'MS' THEN 'Mato Grosso do Sul'
        WHEN 'PB' THEN 'Paraíba'          WHEN 'RN' THEN 'Rio Grande do Norte'
        WHEN 'AL' THEN 'Alagoas'          WHEN 'PI' THEN 'Piauí'
        WHEN 'ES' THEN 'Espírito Santo'   WHEN 'DF' THEN 'Distrito Federal'
        WHEN 'SE' THEN 'Sergipe'          WHEN 'AM' THEN 'Amazonas'
        WHEN 'RO' THEN 'Rondônia'         WHEN 'TO' THEN 'Tocantins'
        WHEN 'AC' THEN 'Acre'             WHEN 'AP' THEN 'Amapá'
        WHEN 'RR' THEN 'Roraima'
    END                                                        AS state_full_name,
    CASE r.state
        WHEN 'SP' THEN -23.5505  WHEN 'RJ' THEN -22.9068
        WHEN 'MG' THEN -19.9167  WHEN 'BA' THEN -12.9714
        WHEN 'RS' THEN -30.0346  WHEN 'PR' THEN -25.4284
        WHEN 'SC' THEN -27.5954  WHEN 'GO' THEN -16.6869
        WHEN 'PE' THEN  -8.0539  WHEN 'CE' THEN  -3.7172
        WHEN 'PA' THEN  -1.4558  WHEN 'MA' THEN  -2.5297
        WHEN 'MT' THEN -15.6014  WHEN 'MS' THEN -20.4428
        WHEN 'PB' THEN  -7.1195  WHEN 'RN' THEN  -5.7945
        WHEN 'AL' THEN  -9.6658  WHEN 'PI' THEN  -5.0920
        WHEN 'ES' THEN -20.3155  WHEN 'DF' THEN -15.7801
        WHEN 'SE' THEN -10.9472  WHEN 'AM' THEN  -3.1190
        WHEN 'RO' THEN  -8.7612  WHEN 'TO' THEN -10.1753
        WHEN 'AC' THEN  -9.9754  WHEN 'AP' THEN   0.0349
        WHEN 'RR' THEN   2.8235
    END                                                        AS latitude,
    CASE r.state
        WHEN 'SP' THEN -46.6333  WHEN 'RJ' THEN -43.1729
        WHEN 'MG' THEN -43.9345  WHEN 'BA' THEN -38.5014
        WHEN 'RS' THEN -51.2177  WHEN 'PR' THEN -49.2733
        WHEN 'SC' THEN -48.5480  WHEN 'GO' THEN -49.2648
        WHEN 'PE' THEN -34.8811  WHEN 'CE' THEN -38.5434
        WHEN 'PA' THEN -48.5044  WHEN 'MA' THEN -44.3028
        WHEN 'MT' THEN -56.0974  WHEN 'MS' THEN -54.6462
        WHEN 'PB' THEN -34.8641  WHEN 'RN' THEN -35.2110
        WHEN 'AL' THEN -35.7350  WHEN 'PI' THEN -42.8019
        WHEN 'ES' THEN -40.3128  WHEN 'DF' THEN -47.9292
        WHEN 'SE' THEN -37.0731  WHEN 'AM' THEN -60.0212
        WHEN 'RO' THEN -63.9004  WHEN 'TO' THEN -48.2982
        WHEN 'AC' THEN -67.8243  WHEN 'AP' THEN -51.0694
        WHEN 'RR' THEN -60.6758
    END                                                        AS longitude,
    r.total_orders,
    r.delivered_orders,
    r.lost_orders,
    r.total_revenue_made,
    r.total_revenue_lost,
    r.money_stuck,
    r.avg_order_value,
    r.revenue_per_order,
    r.cancellation_rate_pct,
    r.delivery_success_rate_pct,
    r.loss_rate_pct,
    r.revenue_rank,
    CASE
        WHEN r.revenue_rank <= 7  THEN 'green'
        WHEN r.revenue_rank <= 17 THEN 'yellow'
        ELSE                           'red'
    END                                                        AS colour_tier,
    CASE
        WHEN r.revenue_rank <= 7  THEN 3
        WHEN r.revenue_rank <= 17 THEN 2
        ELSE                           1
    END                                                        AS colour_score,
    CASE
        WHEN r.revenue_rank <= 7  THEN 'top_performer'
        WHEN r.revenue_rank <= 17 THEN 'average'
        ELSE                           'worst_performer'
    END                                                        AS performance_tier
FROM ranked r;