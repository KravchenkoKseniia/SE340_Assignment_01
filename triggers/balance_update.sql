CREATE OR REPLACE FUNCTION balance_update() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
    BEGIN
        IF OLD.status <> 'APPROVED' AND NEW.status = 'APPROVED' THEN
            UPDATE accounts
            SET balance = balance - NEW.amount
            WHERE account_id = NEW.account_id;
        END IF;
        RETURN NEW;
    END;
$$;

CREATE OR REPLACE TRIGGER balance_update
AFTER UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION balance_update();