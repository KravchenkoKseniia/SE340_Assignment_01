CREATE OR REPLACE FUNCTION protect_customer_deletion()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
    BEGIN
        IF EXISTS (
            SELECT 1 FROM accounts
            WHERE customer_id = OLD.customer_id AND status <> 'CLOSED'
        ) THEN RAISE EXCEPTION 'Cannot delete customer % — has active accounts', OLD.customer_id;
        END IF;
        RETURN OLD;
    END;
$$;

CREATE TRIGGER protect_customer_deletion
BEFORE DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION protect_customer_deletion();