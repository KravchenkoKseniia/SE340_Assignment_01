CREATE OR REPLACE FUNCTION calculate_transaction_risk_score(
    p_transaction_id BIGINT
) RETURNS INT
AS $$
    DECLARE
        v_risk_score INT := 0;
        v_transaction RECORD;
        v_customer_id BIGINT;
        v_rule RECORD;
        v_daily_volume NUMERIC;
        v_customer_country CHAR(2);
    BEGIN
        SELECT * INTO v_transaction
        FROM transactions t
        WHERE t.transaction_id = p_transaction_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Transaction with ID % not found', p_transaction_id;
        END IF;

        SELECT a.customer_id INTO v_customer_id
        FROM accounts a
        WHERE a.account_id = v_transaction.account_id;

        FOR v_rule IN
            SELECT * FROM fraud_rules WHERE is_active
        LOOP
            CASE v_rule.rule_type
                WHEN 'HIGH_AMOUNT' THEN
                    IF v_transaction.amount > v_rule.threshold_value THEN
                        v_risk_score := v_risk_score + v_rule.score;
                    END IF;
                WHEN 'HIGH_RISK_COUNTRY' THEN
                    IF is_high_risk_country(v_transaction.merchant_country) THEN
                        v_risk_score := v_risk_score + v_rule.score;
                    END IF;
                WHEN 'DAILY_VOLUME' THEN
                    v_daily_volume := calculate_customer_daily_volume(v_customer_id, v_transaction.transaction_at::DATE);
                    IF v_daily_volume > v_rule.threshold_value THEN
                        v_risk_score := v_risk_score + v_rule.score;
                    END IF;
                WHEN 'VELOCITY' THEN
                    IF has_high_velocity_transactions(v_customer_id) THEN
                        v_risk_score := v_risk_score + v_rule.score;
                    END IF;
                WHEN 'FOREIGN_LARGE_TXN' THEN
                    SELECT country_code INTO v_customer_country
                    FROM customers
                    WHERE customer_id = v_customer_id;

                    IF v_transaction.merchant_country <> v_customer_country
                        AND v_transaction.amount > v_rule.threshold_value THEN
                        v_risk_score := v_risk_score + v_rule.score;
                    END IF;
            END CASE;
        END LOOP;

        RETURN LEAST(v_risk_score, 100);
    END;
$$ LANGUAGE plpgsql STABLE STRICT;