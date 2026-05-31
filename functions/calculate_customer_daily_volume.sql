CREATE OR REPLACE FUNCTION calculate_customer_daily_volume(
    p_customer_id BIGINT,
    p_target_date DATE
) RETURNS NUMERIC
AS $$
    DECLARE
        v_total_volume NUMERIC := 0;
    BEGIN

        IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
            RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
        END IF;

        IF p_target_date > CURRENT_DATE THEN
            RAISE EXCEPTION 'Target date cannot be in the future';
        END IF;

        WITH customer_accounts AS (
            SELECT account_id FROM accounts WHERE customer_id = p_customer_id
        )
        SELECT COALESCE(SUM(t.amount), 0) INTO v_total_volume
        FROM transactions t
        INNER JOIN customer_accounts ca ON ca.account_id = t.account_id
        WHERE t.transaction_at::DATE = p_target_date;

        RETURN v_total_volume;
    END;
$$ LANGUAGE plpgsql STABLE STRICT;

-- Example usage:
SELECT calculate_customer_daily_volume(1, '2026-05-30') AS daily_volume;
SELECT calculate_customer_daily_volume(999, '2026-05-30') AS daily_volume; -- Exception if customer_id 999 does not exist