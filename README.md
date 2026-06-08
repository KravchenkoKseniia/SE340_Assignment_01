# Banking Fraud Monitoring System

An advanced PostgreSQL database solution that simulates a production-grade
fraud monitoring system for a bank. The project implements a complete data
layer — tables, constraints, functions, stored procedures, triggers, views,
and a materialized view — to support automated detection of suspicious
transactions, audit logging, and analytical reporting.

## Project Overview

The system models the core entities of a modern bank (customers, accounts,
cards, transactions) and layers fraud detection logic on top:

- Every new transaction is automatically scored against a configurable set
  of fraud rules.
- Transactions exceeding the risk threshold are flagged and an alert is
  raised for review.
- Status transitions, balance changes, and structural modifications are
  logged for audit and compliance.
- Aggregated analytics are exposed through views and a materialized view
  refreshed on demand.

The implementation emphasises *data-driven* design: detection rules and
their thresholds live in a configuration table (`fraud_rules`) rather than
hard-coded inside functions, so analysts can tune the system without
re-deploying code.

## Project Structure

```
Assignment1/
├── tables/                       DDL for all base tables and indexes
├── functions/                    Reusable PL/pgSQL and SQL functions
├── stored-procedures/            Business-operation procedures
├── triggers/                     Trigger functions and bindings
├── views/                        Analytical views and the materialized view
└── README.md
```

## Setup Instructions

### Prerequisites

- PostgreSQL 16 or newer (uses `GENERATED ALWAYS AS IDENTITY`,
  `CREATE OR REPLACE TRIGGER`, and other modern features)
- `psql` command-line tool

### Load Order

The objects must be created in dependency order. From the project root:

```bash
psql -d <your_database> -f tables/customers.sql
psql -d <your_database> -f tables/accounts.sql
psql -d <your_database> -f tables/cards.sql
psql -d <your_database> -f tables/transactions.sql
psql -d <your_database> -f tables/transaction_status_history.sql
psql -d <your_database> -f tables/fraud_rules.sql
psql -d <your_database> -f tables/fraud_alerts.sql
psql -d <your_database> -f tables/audit_log.sql
psql -d <your_database> -f tables/high_risk_countries.sql

psql -d <your_database> -f functions/mask_card_number.sql
psql -d <your_database> -f functions/get_customer_age.sql
psql -d <your_database> -f functions/is_high_risk_country.sql
psql -d <your_database> -f functions/calculate_customer_daily_volume.sql
psql -d <your_database> -f functions/has_high_velocity_transactions.sql
psql -d <your_database> -f functions/calculate_transaction_risk_score.sql

psql -d <your_database> -f stored-procedures/freeze_account.sql
psql -d <your_database> -f stored-procedures/create_fraud_alert.sql
psql -d <your_database> -f stored-procedures/approve_pending_transactions.sql
psql -d <your_database> -f stored-procedures/process_transaction.sql
psql -d <your_database> -f stored-procedures/refresh_fraud_dashboard.sql

psql -d <your_database> -f triggers/customer_deletion_protection.sql
psql -d <your_database> -f triggers/transaction_status_history.sql
psql -d <your_database> -f triggers/balance_update.sql
psql -d <your_database> -f triggers/transaction_risk_evaluation.sql
psql -d <your_database> -f triggers/audit_logging.sql

psql -d <your_database> -f views/vw_customer_accounts.sql
psql -d <your_database> -f views/vw_recent_transactions.sql
psql -d <your_database> -f views/vw_flagged_transactions.sql
psql -d <your_database> -f views/vw_customer_risk_profile.sql
psql -d <your_database> -f views/mv_daily_fraud_summary.sql
```

## Database Schema

Nine tables form the core schema. Foreign keys preserve referential
integrity while delete actions are chosen to match the operational
semantics of each relationship.

| Table | Purpose |
|---|---|
| `customers` | Bank clients with identity attributes and country |
| `accounts` | Bank accounts owned by customers (one-to-many) |
| `cards` | Cards issued against accounts |
| `transactions` | Payment transactions tied to an account and a card |
| `transaction_status_history` | Append-only log of status changes |
| `fraud_rules` | Configurable detection rules with thresholds |
| `fraud_alerts` | Alerts generated when rules trigger |
| `audit_log` | Generic INSERT/UPDATE/DELETE audit trail |
| `high_risk_countries` | Reference list of countries flagged as risky |

### Key Constraints

- Customer email is `UNIQUE`; country codes match `^[A-Z]{2}$` (ISO 3166-1
  alpha-2).
- Monetary values use `NUMERIC(15, 2)`; balances cannot be negative.
- Currencies are constrained to `('UAH', 'USD', 'EUR')`.
- Transaction statuses are constrained to
  `('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED')`.
- `accounts.customer_id` uses `ON DELETE CASCADE` so a customer can be
  deleted while they still have accounts; the `BEFORE DELETE` trigger on
  `customers` raises a domain-friendly error before the FK fires.
- `transactions.account_id` and `transactions.card_id` use
  `ON DELETE RESTRICT` to preserve transaction history (banking systems
  must retain records for compliance windows).
- `audit_log.customer_id` uses `ON DELETE SET NULL` so the audit row
  outlives the entity it references.
- `card_number_hash` enforces a SHA-256 hex shape via regex
  (`^[a-f0-9]{64}$`) — the system never stores raw PANs.

Indexes are placed on foreign-key columns and on
`transactions(account_id, transaction_at DESC)` to support fraud-query
patterns such as customer daily volume and velocity checks.

## Functions

| Function | Purpose |
|---|---|
| `mask_card_number(text)` | Pure string masking that keeps only the last four characters. Declared `IMMUTABLE STRICT`. |
| `get_customer_age(bigint)` | Returns customer age in years using `AGE()` and `EXTRACT`. `STABLE` because it reads a table. |
| `is_high_risk_country(char)` | Existence check against the `high_risk_countries` reference table. |
| `calculate_customer_daily_volume(bigint, date)` | Aggregates transaction amounts for a customer on a specific date by joining accounts and transactions. |
| `has_high_velocity_transactions(bigint)` | Looks up the active `VELOCITY` rule from `fraud_rules` and counts recent transactions within its time window. |
| `calculate_transaction_risk_score(bigint)` | Iterates active rules from `fraud_rules`, dispatches on `rule_type`, accumulates points using each rule's `threshold_value` and `score`, and caps at 100. |

The risk-score function is the core of the system: it transforms a single
transaction into an integer score by applying every active rule. Adding a
new rule type means adding one branch to the `CASE` statement and one row
in `fraud_rules`.

## Stored Procedures

| Procedure | Purpose |
|---|---|
| `freeze_account(bigint)` | Validates account existence and lifecycle, transitions status to `FROZEN`, and cascades to deactivate cards. |
| `create_fraud_alert(bigint, text, int)` | Validates parameters, ensures the transaction exists, prevents duplicate alerts with the same reason, and inserts an `OPEN` alert. |
| `approve_pending_transactions()` | Bulk-approves PENDING transactions with risk score below the auto-approval threshold using `UPDATE ... RETURNING` and a chained `INSERT ... SELECT` into the status history. Reports the count via `RAISE NOTICE`. |
| `process_transaction(bigint)` | Coordinates per-transaction processing: validates status, computes risk score, persists score and resulting status, raises an alert for high-risk cases. |
| `refresh_fraud_dashboard()` | Refreshes the materialized view `mv_daily_fraud_summary`. |

All procedures avoid duplicating logic that triggers handle automatically
(status history, audit log). Manual logging was removed once the
corresponding triggers were added.

## Triggers

| Trigger                        | Event | Purpose |
|--------------------------------|---|---|
| `customer_deletion_protection` | `BEFORE DELETE ON customers` | Blocks deletion when active accounts exist, providing a domain-friendly error before the FK refuses the operation. |
| `transaction_status_history`   | `AFTER UPDATE OF status ON transactions` | Records every status transition into the history table. Uses `WHEN (OLD.status IS DISTINCT FROM NEW.status)` for NULL-safe filtering. |
| `balance_update`               | `AFTER UPDATE ON transactions` | Decrements the account balance the moment a transaction transitions into `APPROVED`. |
| `transaction_risk_evaluation`  | `AFTER INSERT ON transactions` | Calls `calculate_transaction_risk_score`, persists the score, sets `FLAGGED` status above the threshold, and creates a fraud alert in the same flow. |
| `audit_logging`                | `AFTER INSERT OR UPDATE OR DELETE` on seven domain tables | Single generic trigger function attached to multiple tables. Converts `OLD`/`NEW` to JSONB and resolves the affected `customer_id` via `CASE TG_TABLE_NAME`. Not installed on `audit_log` itself to prevent recursion. |

Combining risk scoring with alert creation in a single trigger is a
deliberate design choice (see *Design Decisions*).

## Views

| View | Purpose |
|---|---|
| `vw_customer_accounts` | Operational view of active customers with their accounts. Filters `is_active = TRUE`. |
| `vw_recent_transactions` | Last 30 days of transactions with customer, account, and card context. |
| `vw_flagged_transactions` | All FLAGGED transactions without a time horizon — fraud investigations may span months. |
| `vw_customer_risk_profile` | Per-customer aggregates: total transactions, flagged count, high-risk count, max and average risk score, plus a categorical `risk_profile` (`No Transactions` / `Low Risk` / `Medium Risk` / `High Risk`). |

## Materialized View

`mv_daily_fraud_summary` aggregates transactions by day using
`(transaction_at AT TIME ZONE 'UTC')::DATE` to keep grouping
timezone-independent. Columns include:

- `transaction_date`
- `total_transactions`, `total_amount`
- `flagged_transactions`, `suspicious_amount`
- `avg_risk_score`

A `UNIQUE` index on `transaction_date` makes the view eligible for
`REFRESH MATERIALIZED VIEW CONCURRENTLY`, which keeps the view readable
during refresh.

## Fraud Detection Logic

The risk pipeline runs as follows:

1. A transaction is inserted into `transactions`.
2. The `transaction_risk_evaluation` trigger fires `AFTER INSERT` and
   invokes `calculate_transaction_risk_score`.
3. The scoring function reads every active row from `fraud_rules`, and for
   each row applies the corresponding check:

   | `rule_type` | Trigger condition | Points added |
   |---|---|---|
   | `HIGH_AMOUNT` | `amount > threshold_value` | `score` |
   | `HIGH_RISK_COUNTRY` | `is_high_risk_country(merchant_country)` | `score` |
   | `DAILY_VOLUME` | `calculate_customer_daily_volume(...) > threshold_value` | `score` |
   | `VELOCITY` | `has_high_velocity_transactions(...)` | `score` |
   | `FOREIGN_LARGE_TXN` | merchant country differs from customer country and amount exceeds threshold | `score` |

4. The accumulated score is capped at 100.
5. If the score is at or above 70 the transaction's status becomes
   `FLAGGED` and `create_fraud_alert` is invoked.
6. When an operator later approves a transaction, the
   `balance_update` trigger debits the account balance.

Every rule's threshold and score contribution live in the `fraud_rules`
table, so detection can be tuned through `UPDATE fraud_rules SET ...` with
no schema or function changes required.

## Design Decisions

- **Combined risk evaluation and fraud alert creation.** The brief lists
  these as two triggers, but both fire on the same event and represent a
  single logical flow. Combining them keeps the operation atomic; an alert
  cannot be missing for a flagged transaction.
- **Customer-centric audit log.** The audit table carries a single
  `customer_id` foreign key (with `ON DELETE SET NULL`) rather than
  polymorphic or per-entity columns. This matches the ER diagram, supports
  GDPR-style "everything we hold on customer X" queries cheaply, and keeps
  the schema flat. Object-specific identifiers remain available inside the
  `old_data` / `new_data` JSONB columns.
- **`fraud_rules` table is fully data-driven.** Each rule carries
  `threshold_value`, optional `time_window_minutes` for velocity rules,
  and a `score` contribution. Adding or tuning rules does not require
  redeploying any code.
- **Transaction history is preserved.** Foreign keys to `transactions` use
  `ON DELETE RESTRICT` because banking history must outlive the entities
  that reference it.
- **Card numbers are never stored.** Only a SHA-256 hex hash is kept; the
  regex on `card_number_hash` makes that contract explicit at the schema
  level.
- **UTC for daily aggregation.** The materialized view groups by
  `(transaction_at AT TIME ZONE 'UTC')::DATE` so the "day" boundary is
  deterministic regardless of session timezone.

## Assumptions

- Transactions are merchant purchases — they decrease the account balance.
- A single currency is assumed when summing across accounts (the daily
  volume function does not normalise currencies).
- Customers are soft-deactivated (`is_active = FALSE`) rather than removed
  in normal operation. Hard deletion is reserved for accounts with no
  history.
- `current_user` is recorded in `transaction_status_history.changed_by`.
  In production, session variables (`SET LOCAL app.current_user = ...`)
  would carry application-level identity through to the trigger.
- Auto-approval in `approve_pending_transactions` applies only when the
  transaction's `risk_score` is below 30.
- The risk threshold for flagging is 70 on the 0–100 scale.

## Demo Queries

```sql
-- Score a transaction directly
SELECT calculate_transaction_risk_score(1);

-- Process a pending transaction through the full pipeline
CALL process_transaction(1);

-- Approve all low-risk pending transactions
CALL approve_pending_transactions();

-- Freeze a suspicious account
CALL freeze_account(5);

-- Refresh the daily fraud dashboard
CALL refresh_fraud_dashboard();

-- Top 10 customers by flagged transactions
SELECT customer_id, full_name, flagged_transactions, max_risk_score
FROM vw_customer_risk_profile
ORDER BY flagged_transactions DESC, max_risk_score DESC
LIMIT 10;

-- Recent flagged transactions for review
SELECT transaction_id, amount, currency, merchant_country, risk_score, customer_name
FROM vw_flagged_transactions
ORDER BY risk_score DESC;

-- Audit trail for a single customer
SELECT changed_at, table_name, operation, old_data, new_data
FROM audit_log
WHERE customer_id = 1
ORDER BY changed_at DESC;

-- Daily fraud summary for the last 7 days
SELECT *
FROM mv_daily_fraud_summary
WHERE transaction_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY transaction_date DESC;
```
README was generated by Claude :( - he proposed to remove this line btw :D

![img.png](img.png)
