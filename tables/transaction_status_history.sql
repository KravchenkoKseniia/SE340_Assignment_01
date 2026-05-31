CREATE TABLE transaction_status_history (
    history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    old_status TEXT NOT NULL CHECK (old_status IN ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED')),
    new_status TEXT NOT NULL CHECK (new_status IN ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED')),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changed_by TEXT NOT NULL CHECK (LENGTH(TRIM(changed_by)) > 0),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE RESTRICT
);

CREATE INDEX idx_transaction_status_history_transaction_id ON transaction_status_history(transaction_id);
