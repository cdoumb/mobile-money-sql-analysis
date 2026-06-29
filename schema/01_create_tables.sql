-- ============================================================
-- Mobile Money Transactions Database
-- Schema: 5 tables relationnelles inspirées du dataset PaySim
-- Compatible: PostgreSQL 13+
-- ============================================================

-- 1. Clients
CREATE TABLE clients (
    client_id       SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    account_number  VARCHAR(20)  UNIQUE NOT NULL,
    account_type    VARCHAR(20)  NOT NULL CHECK (account_type IN ('PERSONAL', 'MERCHANT', 'AGENT')),
    region          VARCHAR(50),
    registered_at   DATE         NOT NULL
);

-- 2. Marchands
CREATE TABLE merchants (
    merchant_id     SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    category        VARCHAR(50)  NOT NULL,  -- ex: RETAIL, TELECOM, UTILITY
    region          VARCHAR(50),
    registered_at   DATE         NOT NULL
);

-- 3. Types de transactions
CREATE TABLE transaction_types (
    type_id         SERIAL PRIMARY KEY,
    type_name       VARCHAR(30)  UNIQUE NOT NULL,  -- CASH_IN, CASH_OUT, TRANSFER, PAYMENT, DEBIT
    description     TEXT
);

-- 4. Transactions (table principale)
CREATE TABLE transactions (
    transaction_id  SERIAL PRIMARY KEY,
    type_id         INT          NOT NULL REFERENCES transaction_types(type_id),
    client_id       INT          NOT NULL REFERENCES clients(client_id),
    merchant_id     INT          REFERENCES merchants(merchant_id),  -- NULL si pas de marchand
    amount          NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    old_balance     NUMERIC(15,2) NOT NULL,
    new_balance     NUMERIC(15,2) NOT NULL,
    is_fraud        BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP    NOT NULL
);

-- 5. Alertes fraude
CREATE TABLE fraud_alerts (
    alert_id        SERIAL PRIMARY KEY,
    transaction_id  INT          NOT NULL REFERENCES transactions(transaction_id),
    alert_type      VARCHAR(50)  NOT NULL,  -- ex: HIGH_AMOUNT, RAPID_SUCCESSION, BALANCE_DRAIN
    severity        VARCHAR(10)  NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH')),
    reviewed        BOOLEAN      NOT NULL DEFAULT FALSE,
    flagged_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Index pour les requêtes fréquentes
CREATE INDEX idx_transactions_client    ON transactions(client_id);
CREATE INDEX idx_transactions_type      ON transactions(type_id);
CREATE INDEX idx_transactions_date      ON transactions(created_at);
CREATE INDEX idx_transactions_fraud     ON transactions(is_fraud);
CREATE INDEX idx_alerts_transaction     ON fraud_alerts(transaction_id);
