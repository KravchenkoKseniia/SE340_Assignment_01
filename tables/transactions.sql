CREATE TABLE transactions (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL,
    card_id BIGINT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL CHECK (currency IN ('UAH', 'USD', 'EUR')),
    merchant_category TEXT NOT NULL CHECK (LENGTH(TRIM(merchant_category)) > 0),
    merchant_country CHAR(2) NOT NULL CHECK (merchant_country ~ '^[A-Z]{2}$'),
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED')),
    risk_score INT NOT NULL DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    transaction_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE RESTRICT,
    FOREIGN KEY (card_id) REFERENCES cards(card_id) ON DELETE RESTRICT
);

CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_card_id ON transactions(card_id);
CREATE INDEX idx_transactions_status ON transactions(status);

CREATE INDEX idx_transactions_daily_volume ON transactions(account_id, transaction_at DESC);