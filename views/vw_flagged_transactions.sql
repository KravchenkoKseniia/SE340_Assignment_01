CREATE OR REPLACE VIEW vw_flagged_transactions AS
SELECT
    t.transaction_id,
    t.account_id,
    t.amount,
    t.currency,
    t.merchant_category,
    t.merchant_country,
    t.risk_score,
    t.transaction_at,
    a.account_number,
    a.currency AS account_currency,
    ca.card_id,
    ca.card_type,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email AS customer_email
FROM transactions t
INNER JOIN accounts a ON t.account_id = a.account_id
INNER JOIN customers c ON a.customer_id = c.customer_id
INNER JOIN cards ca ON t.card_id = ca.card_id
WHERE c.is_active = TRUE AND t.status = 'FLAGGED';