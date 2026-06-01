CREATE MATERIALIZED VIEW mv_daily_fraud_summary AS
WITH daily_customer_risk AS (
    SELECT
        (t.transaction_at AT TIME ZONE 'UTC')::DATE AS transaction_date,
        a.customer_id,
        AVG(t.risk_score) AS avg_risk_score,
        COUNT(*) FILTER (WHERE t.status = 'FLAGGED') AS flagged_count
    FROM transactions t
    INNER JOIN accounts a ON t.account_id = a.account_id
    GROUP BY (t.transaction_at AT TIME ZONE 'UTC')::DATE, a.customer_id
), ranked_customers AS (
    SELECT
        transaction_date,
        customer_id,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_date
            ORDER BY avg_risk_score DESC, flagged_count DESC
        ) AS risk_rank
    FROM daily_customer_risk
), top_risky_customers AS (
    SELECT transaction_date, ARRAY_AGG(customer_id ORDER BY risk_rank) AS top_risky_customer_ids
    FROM ranked_customers
    WHERE risk_rank <= 3
    GROUP BY transaction_date
), daily_alerts AS (
    SELECT (fa.created_at AT TIME ZONE 'UTC')::DATE AS alert_date,
           COUNT(*) AS total_alerts
    FROM fraud_alerts fa
    GROUP BY (fa.created_at AT TIME ZONE 'UTC')::DATE
)
SELECT
    (t.transaction_at AT TIME ZONE 'UTC')::DATE AS transaction_date,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_amount,
    COUNT(*) FILTER (WHERE status = 'FLAGGED') AS flagged_transactions,
    COALESCE(SUM(amount) FILTER (WHERE status = 'FLAGGED'), 0) AS suspicious_amount,
    COALESCE(AVG(t.risk_score), 0) AS avg_risk_score,
    COALESCE(top_risky_customers.top_risky_customer_ids, ARRAY[]::BIGINT[]) AS top_risky_customer_ids,
    COALESCE(da.total_alerts, 0) AS total_alerts
FROM transactions t
LEFT JOIN top_risky_customers ON (t.transaction_at AT TIME ZONE 'UTC')::DATE = top_risky_customers.transaction_date
LEFT JOIN daily_alerts da ON (t.transaction_at AT TIME ZONE 'UTC')::DATE = da.alert_date
GROUP BY (t.transaction_at AT TIME ZONE 'UTC')::DATE, top_risky_customers.top_risky_customer_ids, da.total_alerts
ORDER BY transaction_date DESC;

CREATE UNIQUE INDEX idx_mv_daily_fraud_summary_date ON mv_daily_fraud_summary (transaction_date);