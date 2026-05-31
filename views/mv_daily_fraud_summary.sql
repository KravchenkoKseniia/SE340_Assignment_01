CREATE MATERIALIZED VIEW mv_daily_fraud_summary AS
SELECT
    (t.transaction_at AT TIME ZONE 'UTC')::DATE AS transaction_date,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_amount,
    COUNT(*) FILTER (WHERE status = 'FLAGGED') AS flagged_transactions,
    COALESCE(SUM(amount) FILTER (WHERE status = 'FLAGGED'), 0) AS suspicious_amount,
    COALESCE(AVG(t.risk_score), 0) AS avg_risk_score
FROM transactions t
GROUP BY (t.transaction_at AT TIME ZONE 'UTC')::DATE
ORDER BY transaction_date DESC;