CREATE EXTENSION pg_cron;

SELECT cron.schedule('refresh','0 0 * * *', 'CALL refresh_fraud_dashboard()');
SELECT cron.unschedule('refresh');

-- Will not work on Windows