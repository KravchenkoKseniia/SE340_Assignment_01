CREATE TABLE accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    account_number TEXT NOT NULL UNIQUE CHECK (account_number ~ '^[A-Z0-9]{10}$'),
    currency CHAR(3) NOT NULL CHECK (currency IN ('UAH', 'USD', 'EUR')),
    balance DECIMAL(15, 2) NOT NULL CHECK (balance >= 0),
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
);

CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);