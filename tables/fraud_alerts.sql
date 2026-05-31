CREATE TABLE fraud_alerts (
    alert_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    rule_id BIGINT,
    reason TEXT NOT NULL CHECK (LENGTH(TRIM(reason)) > 0),
    risk_score INT NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
    alert_status TEXT NOT NULL CHECK (alert_status IN ('OPEN', 'INVESTIGATING', 'CONFIRMED_FRAUD', 'FALSE_POSITIVE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE RESTRICT,
    FOREIGN KEY (rule_id) REFERENCES fraud_rules(rule_id) ON DELETE RESTRICT
);

CREATE INDEX idx_fraud_alerts_transaction_id ON fraud_alerts(transaction_id);
CREATE INDEX idx_fraud_alerts_rule_id ON fraud_alerts(rule_id);