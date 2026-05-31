CREATE TABLE audit_log (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT,
    table_name TEXT NOT NULL CHECK (LENGTH(TRIM(table_name)) > 0),
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL
);

CREATE INDEX idx_audit_log_customer_id ON audit_log(customer_id);
CREATE INDEX idx_audit_log_table_name ON audit_log(table_name);