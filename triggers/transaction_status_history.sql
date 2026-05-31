CREATE OR REPLACE FUNCTION log_transaction_status_change() RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
    BEGIN
        INSERT INTO transaction_status_history (transaction_id, old_status, new_status, changed_by)
        VALUES (NEW.transaction_id, OLD.status, NEW.status, current_user);
        RETURN NEW;
    END;
$$;

CREATE OR REPLACE TRIGGER log_transaction_status_change
AFTER UPDATE ON transactions
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION log_transaction_status_change();