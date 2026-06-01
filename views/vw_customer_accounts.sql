CREATE OR REPLACE VIEW vw_customer_accounts AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.email,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    a.status AS account_status
FROM customers c
INNER JOIN accounts a ON c.customer_id = a.customer_id
WHERE c.is_active = TRUE;