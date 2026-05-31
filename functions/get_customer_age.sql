CREATE OR REPLACE FUNCTION get_customer_age(p_customer_id BIGINT) RETURNS INT
AS $$
    DECLARE
        v_birth_date DATE;
        v_age INT;
    BEGIN
        SELECT c.birth_date INTO v_birth_date
        FROM customers c
        WHERE c.customer_id = p_customer_id;

        IF v_birth_date IS NULL THEN
            RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
        END IF;

        v_age := EXTRACT(YEAR FROM AGE(CURRENT_DATE, v_birth_date));
        RETURN v_age;
    END;
$$ LANGUAGE plpgsql STABLE STRICT;

-- Example usage:
SELECT get_customer_age(1) AS customer_age;
SELECT get_customer_age(999) AS customer_age; -- Exception
