CREATE OR REPLACE PROCEDURE refresh_fraud_dashboard()
LANGUAGE plpgsql
AS $$
    BEGIN
        REFRESH MATERIALIZED VIEW mv_daily_fraud_summary;;
    END;
$$;