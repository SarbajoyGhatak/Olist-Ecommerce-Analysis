CREATE VIEW MASTER_TABLE AS
SELECT
    f.*,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    r.review_creation_date,

    -- low review flag — adjust threshold after your EDA
    CASE
        WHEN r.review_score <= 2 THEN 'low'
        WHEN r.review_score = 3  THEN 'neutral'
        ELSE                          'positive'
    END                          AS review_sentiment,

    -- did they leave a comment
    CASE
        WHEN r.review_comment_message IS NOT NULL
        THEN 'yes' ELSE 'no'
    END                          AS has_comment

FROM vw_funnel_master f
LEFT JOIN order_reviews r
    ON f.order_id = r.order_id;