CREATE OR REPLACE PROCEDURE process_transaction(
    p_transaction_id BIGINT
)
LANGUAGE plpgsql
AS $$
    DECLARE
        v_risk_score INT;
        v_account_id BIGINT;
        v_old_status TEXT;
    BEGIN

        IF p_transaction_id IS NULL THEN
            RAISE EXCEPTION 'Transaction ID cannot be null';
        END IF;

        PERFORM 1 FROM transactions WHERE transaction_id = p_transaction_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Transaction with ID % does not exist', p_transaction_id;
        END IF;

        SELECT status INTO v_old_status
        FROM transactions
        WHERE transaction_id = p_transaction_id;
        IF v_old_status IN ('APPROVED', 'DECLINED', 'FLAGGED') THEN
            RAISE EXCEPTION 'Only transactions with PENDING status can be processed. Current status: %', v_old_status;
        END IF;


        SELECT account_id INTO v_account_id
        FROM transactions
        WHERE transaction_id = p_transaction_id;

        v_risk_score := calculate_transaction_risk_score(p_transaction_id);

        IF v_risk_score = 100 THEN
            CALL create_fraud_alert(p_transaction_id, 'Maximum risk score', v_risk_score);

            UPDATE transactions
            SET status = 'DECLINED', risk_score = v_risk_score
            WHERE transaction_id = p_transaction_id;

            CALL freeze_account(v_account_id);
        ELSIF v_risk_score >= 70 THEN
            CALL create_fraud_alert(p_transaction_id, 'Critical risk score', v_risk_score);

            UPDATE transactions
            SET status = 'FLAGGED', risk_score = v_risk_score
            WHERE transaction_id = p_transaction_id;
        ELSIF v_risk_score >= 30 THEN
            UPDATE transactions
            SET risk_score = v_risk_score
            WHERE transaction_id = p_transaction_id;
        ELSE
            UPDATE transactions
            SET status = 'APPROVED', risk_score = v_risk_score
            WHERE transaction_id = p_transaction_id;
        END IF;
    END;
$$;