CREATE OR REPLACE FUNCTION transaction_risk_evaluation() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
    DECLARE
        v_risk_score INT;
    BEGIN
        v_risk_score := calculate_transaction_risk_score(NEW.transaction_id);

        UPDATE transactions
        SET risk_score = v_risk_score
        WHERE transaction_id = NEW.transaction_id;

        IF v_risk_score >= 70 THEN
            UPDATE transactions
            SET status = 'FLAGGED'
            WHERE transaction_id = NEW.transaction_id;

            CALL create_fraud_alert(NEW.transaction_id, 'Automated risk evaluation exceeds threshold 70', v_risk_score);
        END IF;
        RETURN NEW;
    END;
$$;

CREATE OR REPLACE TRIGGER transaction_risk_evaluation
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION transaction_risk_evaluation();