CREATE TABLE high_risk_countries (
    country_code CHAR(2) NOT NULL PRIMARY KEY CHECK (country_code ~ '^[A-Z]{2}$'),
    risk_level INT NOT NULL CHECK (risk_level >= 1 AND risk_level <= 10),
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO high_risk_countries (country_code, risk_level) VALUES
('RU',10),
('BY',9),
('AF',9),
('IR',8),
('KP',10),
('SY',9),
('VE',7),
('LY',8),
('SD',7),
('YE',9),
('SO',8),
('MM',7);
