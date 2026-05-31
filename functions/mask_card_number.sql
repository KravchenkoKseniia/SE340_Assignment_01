CREATE OR REPLACE FUNCTION mask_card_number(card_number TEXT) RETURNS TEXT
AS $$
    BEGIN
        IF LENGTH(card_number) < 4 THEN
            RAISE EXCEPTION 'Card number must be at least 4 digits long';
        END IF;

        RETURN REPEAT('*', LENGTH(card_number) - 4) || RIGHT(card_number, 4);
    END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- Example usage:
SELECT mask_card_number('1234567812345678') AS masked_card_number; -- '************5678'
SELECT mask_card_number('123') AS masked_card_number; -- Exception