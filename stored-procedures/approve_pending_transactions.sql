CREATE OR REPLACE PROCEDURE approve_pending_transactions()
LANGUAGE plpgsql
AS $$
    BEGIN
        WITH approved AS (
            UPDATE transactions
            SET status = 'APPROVED'
            WHERE status = 'PENDING' AND risk_score < 30
            RETURNING transaction_id
        )
        INSERT INTO transaction_status_history
        (transaction_id, old_status, new_status, changed_by)
        SELECT transaction_id, 'PENDING', 'APPROVED', 'SYSTEM' FROM approved;
    END;
$$;