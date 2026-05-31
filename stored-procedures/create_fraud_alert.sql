CREATE OR REPLACE PROCEDURE create_fraud_alert(
    p_transaction_id BIGINT,
    p_reason TEXT,
    p_risk_score INT
)
LANGUAGE plpgsql
AS $$
    BEGIN
        IF p_transaction_id IS NULL THEN
            RAISE EXCEPTION 'Transaction ID cannot be null';
        END IF;

        IF p_reason IS NULL OR LENGTH(TRIM(p_reason)) = 0 THEN
            RAISE EXCEPTION 'Reason cannot be null or empty';
        END IF;

        IF p_risk_score IS NULL OR p_risk_score < 0 OR p_risk_score > 100 THEN
            RAISE EXCEPTION 'Risk score must be between 0 and 100';
        END IF;

        PERFORM 1 FROM transactions WHERE transaction_id = p_transaction_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Transaction with ID % does not exist', p_transaction_id;
        END IF;

        IF EXISTS (
            SELECT 1 FROM fraud_alerts
            WHERE transaction_id = p_transaction_id AND reason = p_reason
        ) THEN
            RAISE EXCEPTION 'A fraud alert for this transaction already exists with the same reason';
        END IF;

        INSERT INTO fraud_alerts (transaction_id, rule_id, reason, risk_score, alert_status)
        VALUES (p_transaction_id, NULL, p_reason, p_risk_score, 'OPEN');
    END;
$$;