CREATE TABLE fraud_rules (
    rule_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rule_name TEXT NOT NULL UNIQUE CHECK (LENGTH(TRIM(rule_name)) > 0),
    rule_type TEXT NOT NULL CHECK (rule_type IN ('HIGH_AMOUNT', 'HIGH_RISK_COUNTRY', 'VELOCITY', 'DAILY_VOLUME', 'FOREIGN_LARGE_TXN')),
    threshold_value DECIMAL(15, 2) NOT NULL CHECK (threshold_value >= 0),
    time_window_minutes INT CHECK (time_window_minutes >= 0),
    score INT NOT NULL DEFAULT 10 CHECK (score >= 0 AND score <= 100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);