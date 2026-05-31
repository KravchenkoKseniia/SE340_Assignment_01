CREATE OR REPLACE FUNCTION audit_logging() RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
DECLARE
    v_old_data JSONB;
    v_new_data JSONB;
    v_customer_id BIGINT;
BEGIN

    IF TG_OP = 'INSERT' THEN
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
    ELSE
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
    END IF;

    CASE TG_TABLE_NAME
        WHEN 'customers' THEN
            v_customer_id := COALESCE((v_new_data->>'customer_id')::BIGINT,
                                      (v_old_data->>'customer_id')::BIGINT
            );
        WHEN 'accounts' THEN
            v_customer_id := COALESCE((v_new_data->>'customer_id')::BIGINT,
                                      (v_old_data->>'customer_id')::BIGINT
            );
        WHEN 'cards' THEN
            SELECT a.customer_id INTO v_customer_id
            FROM accounts a
            WHERE a.account_id = COALESCE((v_new_data->>'account_id')::BIGINT,
                                          (v_old_data->>'account_id')::BIGINT
            );
        WHEN 'transactions' THEN
            SELECT a.customer_id INTO v_customer_id
            FROM accounts a
            WHERE a.account_id = COALESCE((v_new_data->>'account_id')::BIGINT,
                                          (v_old_data->>'account_id')::BIGINT
            );
        WHEN 'fraud_alerts' THEN
            SELECT a.customer_id INTO v_customer_id
            FROM accounts a
            JOIN transactions t ON t.account_id = a.account_id
            WHERE t.transaction_id = COALESCE((v_new_data->>'transaction_id')::BIGINT,
                                              (v_old_data->>'transaction_id')::BIGINT
            );
        ELSE
            v_customer_id := NULL;
        END CASE;

    INSERT INTO audit_log (customer_id, table_name, operation, old_data, new_data)
    VALUES (v_customer_id, TG_TABLE_NAME, TG_OP, v_old_data, v_new_data);

    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE TRIGGER audit_logging_customers
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION audit_logging();

CREATE OR REPLACE TRIGGER audit_logging_accounts
AFTER INSERT OR UPDATE OR DELETE ON accounts
FOR EACH ROW
EXECUTE FUNCTION audit_logging();

CREATE OR REPLACE TRIGGER audit_logging_transactions
AFTER INSERT OR UPDATE OR DELETE ON transactions
FOR EACH ROW
EXECUTE FUNCTION audit_logging();

CREATE OR REPLACE TRIGGER audit_logging_fraud_alerts
AFTER INSERT OR UPDATE OR DELETE ON fraud_alerts
FOR EACH ROW
EXECUTE FUNCTION audit_logging();

CREATE OR REPLACE TRIGGER audit_logging_cards
AFTER INSERT OR UPDATE OR DELETE ON cards
FOR EACH ROW
EXECUTE FUNCTION audit_logging();