CREATE OR REPLACE FUNCTION has_high_velocity_transactions(
    p_customer_id BIGINT
) RETURNS BOOLEAN
AS $$
    DECLARE
        v_count INT;
        v_time_window INTERVAL;
        v_threshold_value INT;
    BEGIN

        SELECT make_interval(mins => fraud_rules.time_window_minutes), fraud_rules.threshold_value INTO v_time_window, v_threshold_value
        FROM fraud_rules
        WHERE rule_type = 'VELOCITY' AND is_active
        ORDER BY rule_id
        LIMIT 1;

        IF (v_time_window IS NULL) OR (v_threshold_value IS NULL) THEN
            RETURN FALSE;
        END IF;

        SELECT COUNT(*) INTO v_count
        FROM transactions t
        JOIN accounts a ON t.account_id = a.account_id
        WHERE a.customer_id = p_customer_id
          AND t.transaction_at >= NOW() - v_time_window;

        RETURN v_count > v_threshold_value;
    END;
$$ LANGUAGE plpgsql STABLE STRICT;

-- Example usage:
-- SELECT has_high_velocity_transactions(1) AS has_velocity; -- true or false depending on recent transactions
-- SELECT has_high_velocity_transactions(999) AS has_velocity; -- false (no transactions for non-existent customer)