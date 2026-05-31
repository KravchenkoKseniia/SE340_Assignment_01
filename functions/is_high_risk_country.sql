CREATE OR REPLACE FUNCTION is_high_risk_country(p_country_code CHAR(2)) RETURNS BOOLEAN
AS $$
    BEGIN
        RETURN EXISTS (SELECT 1 FROM high_risk_countries hrc WHERE hrc.country_code = p_country_code);
    END;
$$ LANGUAGE plpgsql STABLE STRICT;

-- Example usage:
SELECT is_high_risk_country('RU') AS is_risk; -- true
SELECT is_high_risk_country('FR') AS is_risk; -- false
