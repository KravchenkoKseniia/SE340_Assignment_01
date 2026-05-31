CREATE TABLE cards (
    card_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL,
    card_number_hash TEXT NOT NULL UNIQUE CHECK (card_number_hash ~ '^[a-f0-9]{64}$'),
    card_type TEXT NOT NULL CHECK (card_type IN ('VISA', 'MASTERCARD')),
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE', 'BLOCKED')),
    expiration_date DATE NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE CASCADE
);

CREATE INDEX idx_cards_account_id ON cards(account_id);