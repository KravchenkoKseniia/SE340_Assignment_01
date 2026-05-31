CREATE OR REPLACE VIEW vw_customer_risk_profile AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.email,
    COUNT(t.transaction_id) AS total_transactions,
    COUNT(CASE WHEN t.status = 'FLAGGED' THEN 1 END) AS flagged_transactions,
    COUNT(CASE WHEN t.risk_score >= 70 THEN 1 END) AS high_risk_transactions,
    COALESCE(MAX(t.risk_score), 0) AS max_risk_score,
    COALESCE(AVG(t.risk_score), 0) AS avg_risk_score,
    CASE
        WHEN COUNT(t.transaction_id) = 0 THEN 'No Transactions'
        WHEN COUNT(CASE WHEN t.status = 'FLAGGED' THEN 1 END) > 0 THEN 'High Risk'
        WHEN COUNT(CASE WHEN t.risk_score >= 70 THEN 1 END) > 0 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_profile
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
WHERE c.is_active = TRUE
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;