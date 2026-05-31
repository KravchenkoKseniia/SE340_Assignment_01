CREATE TABLE customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name TEXT NOT NULL CHECK (LENGTH(TRIM(first_name)) >= 2),
    last_name TEXT NOT NULL CHECK (LENGTH(TRIM(last_name)) >= 2),
    email TEXT NOT NULL UNIQUE CHECK (email ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'),
    birth_date DATE NOT NULL CHECK (birth_date <= CURRENT_DATE AND birth_date >= '1900-01-01'),
    country_code CHAR(2) NOT NULL CHECK (country_code ~ '^[A-Z]{2}$'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);