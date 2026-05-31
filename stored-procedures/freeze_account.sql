CREATE OR REPLACE PROCEDURE freeze_account(p_account_id BIGINT)
LANGUAGE plpgsql
AS $$
    DECLARE
        v_old_status TEXT;
    BEGIN
        SELECT status INTO v_old_status
        FROM accounts
        WHERE account_id = p_account_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Account with ID % does not exist', p_account_id;
        END IF;

        IF v_old_status = 'CLOSED' THEN
            RAISE EXCEPTION 'Cannot freeze a closed account with ID %', p_account_id;
        END IF;

        UPDATE accounts
        SET status = 'FROZEN'
        WHERE account_id = p_account_id;

        UPDATE cards
        SET status = 'INACTIVE'
        WHERE account_id = p_account_id;
    END;
$$;