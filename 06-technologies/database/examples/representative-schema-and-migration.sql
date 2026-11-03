-- ============================================================================
-- Representative PostgreSQL 16+ Database Architecture & Migration Reference
--
-- Demonstrates:
-- 1. Least privilege role separation (migration_runner vs app_user).
-- 2. 3NF normalized schema with strict declarative constraints and exact types.
-- 3. Composite indexes (Left-to-Right prefix rule), partial indexes, and GIN.
-- 4. Multi-phase Expand-and-Contract migration with defensive lock timeouts.
-- 5. Non-blocking index creation (CONCURRENTLY) and two-phase constraints.
-- 6. Optimistic concurrency control (OCC) and pessimistic row-locking queries.
-- 7. Verification and rollback queries.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECTION 1: ROLE SEPARATION & SCHEMA PROVISIONING
-- ----------------------------------------------------------------------------

-- Role 1: Migration Runner (Holds DDL permissions; used only in CI/CD pipelines)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'migration_runner') THEN
        CREATE ROLE migration_runner WITH LOGIN NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user WITH LOGIN NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'readonly_analyst') THEN
        CREATE ROLE readonly_analyst WITH LOGIN NOINHERIT;
    END IF;
END $$;

-- Enable standard UUID and cryptographic extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Grant schema permissions
GRANT USAGE, CREATE ON SCHEMA public TO migration_runner;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT USAGE ON SCHEMA public TO readonly_analyst;

-- Set session defaults for migration script
SET lock_timeout = '2s';
SET statement_timeout = '10s';
SET client_encoding = 'UTF8';
SET timezone = 'UTC';

-- ----------------------------------------------------------------------------
-- SECTION 2: 3NF NORMALIZED BASELINE SCHEMA
-- ----------------------------------------------------------------------------

-- Custom Status Enums
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE order_status AS ENUM ('PENDING', 'CONFIRMED', 'SHIPPED', 'CANCELLED');
    END IF;
END $$;

-- Table 1: Accounts (System of Record for Identities)
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_accounts_org_email UNIQUE (organization_id, email),
    CONSTRAINT chk_accounts_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_accounts_name_non_empty CHECK (length(trim(full_name)) > 0)
);

-- Partial index for active account lookup (zero index bloat for deactivated rows)
CREATE INDEX IF NOT EXISTS idx_accounts_active_email ON accounts (organization_id, email)
WHERE is_active = TRUE;

-- Table 2: Inventory Items (Stock Tracking)
CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    available_stock INT NOT NULL,
    unit_price_cents BIGINT NOT NULL,
    version INT NOT NULL DEFAULT 1, -- Optimistic Concurrency Control (OCC)
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_inventory_stock_non_negative CHECK (available_stock >= 0),
    CONSTRAINT chk_inventory_price_non_negative CHECK (unit_price_cents >= 0)
);

-- Table 3: Orders (Core Transactional Entity)
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL,
    organization_id UUID NOT NULL,
    status order_status NOT NULL DEFAULT 'PENDING',
    -- Monetary representation: stored as exact integer minor units (BIGINT).
    -- Currency scale is determined by currency column (e.g. 2 for USD, 0 for JPY, 3 for KWD).
    -- For fractional rates, interest, or exchange rates, use NUMERIC(p,s) with Banker's Rounding.
    total_amount_cents BIGINT NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    idempotency_key TEXT NOT NULL,
    idempotency_payload_hash CHAR(64) NOT NULL, -- SHA-256 fingerprint
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    version INT NOT NULL DEFAULT 1, -- OCC version column
    -- Temporal representation: TIMESTAMPTZ records absolute UTC instants for system events and audit trails.
    -- (Real-world calendar appointments would store wall-clock TIMESTAMP WITHOUT TIME ZONE + IANA timezone name).
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign key to Accounts
    CONSTRAINT fk_orders_account FOREIGN KEY (account_id)
        REFERENCES accounts (id) ON DELETE RESTRICT,

    -- Enforce exact monetary and ISO invariants
    CONSTRAINT chk_orders_amount_positive CHECK (total_amount_cents >= 0),
    CONSTRAINT chk_orders_currency_iso CHECK (currency ~ '^[A-Z]{3}$'),
    CONSTRAINT chk_orders_metadata_object CHECK (jsonb_typeof(metadata) = 'object'),

    -- Durable foundation for Effectively-Once Idempotency
    CONSTRAINT uq_orders_org_idempotency_key UNIQUE (organization_id, idempotency_key)
);

-- Composite B-Tree Index following Left-to-Right prefix rule:
-- Equality (organization_id, status) -> Sort (created_at DESC) -> Covering (total_amount_cents)
CREATE INDEX IF NOT EXISTS idx_orders_org_status_created ON orders (
    organization_id,
    status,
    created_at DESC
) INCLUDE (total_amount_cents);

-- GIN Index for fast JSONB metadata querying
CREATE INDEX IF NOT EXISTS idx_orders_metadata_gin ON orders USING GIN (metadata jsonb_path_ops);

-- Table 4: Order Line Items (Relational Detail Table)
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    inventory_item_id UUID NOT NULL,
    quantity INT NOT NULL,
    unit_price_cents BIGINT NOT NULL,

    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_inventory FOREIGN KEY (inventory_item_id)
        REFERENCES inventory_items (id) ON DELETE RESTRICT,
    CONSTRAINT chk_order_items_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price_non_negative CHECK (unit_price_cents >= 0),
    CONSTRAINT uq_order_items_order_item UNIQUE (order_id, inventory_item_id)
);

-- Foreign key lookup index on order line items
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items (order_id);

-- Table 5: Transactional Audit Ledger (Append-Only Log)
CREATE TABLE IF NOT EXISTS audit_ledger (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_name TEXT NOT NULL,
    entity_id UUID NOT NULL,
    action TEXT NOT NULL,
    actor_id TEXT NOT NULL,
    payload_snapshot JSONB NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_ledger_entity ON audit_ledger (entity_name, entity_id, recorded_at DESC);

-- ----------------------------------------------------------------------------
-- SECTION 3: PERMISSION GRANTING (Least Privilege Application Access)
-- ----------------------------------------------------------------------------

-- Application worker receives DML permissions only (ZERO DDL rights)
GRANT SELECT, INSERT, UPDATE, DELETE ON accounts TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON inventory_items TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON orders TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON order_items TO app_user;
GRANT SELECT, INSERT ON audit_ledger TO app_user;

-- Read-only analyst receives SELECT permissions only
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_analyst;

-- ----------------------------------------------------------------------------
-- SECTION 4: SAFE EXPAND-AND-CONTRACT MIGRATION EXAMPLE
-- ----------------------------------------------------------------------------
-- Scenario: Safely introducing a new 'discount_amount_cents' column to 'orders'
-- without blocking production traffic or breaking version N application pods.

-- --- PHASE 1: EXPAND (Add nullable column and non-blocking constraint) ---
BEGIN;
SET LOCAL lock_timeout = '2s';

-- 1. Add column as nullable (Fast metadata update in Postgres 11+)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_amount_cents BIGINT;

-- 2. Add check constraint as NOT VALID (Zero table scan lock!)
ALTER TABLE orders 
    ADD CONSTRAINT chk_orders_discount_non_negative 
    CHECK (discount_amount_cents IS NULL OR discount_amount_cents >= 0) 
    NOT VALID;
COMMIT;

-- 3. Validate constraint in a separate non-blocking pass (Weak lock)
ALTER TABLE orders VALIDATE CONSTRAINT chk_orders_discount_non_negative;

-- 4. Create index non-blockingly (Outside transaction block)
-- Note: In automated migration tools, CONCURRENTLY statements run in standalone transactions.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_discount ON orders (discount_amount_cents)
WHERE discount_amount_cents > 0;

-- --- PHASE 2: BATCH BACKFILL (Simulated Batch Update) ---
-- In production, execute in small batches (e.g. LIMIT 1000) with sleep intervals:
UPDATE orders
SET discount_amount_cents = 0, updated_at = CURRENT_TIMESTAMP
WHERE id IN (
    SELECT id FROM orders 
    WHERE discount_amount_cents IS NULL 
    LIMIT 500
);

-- --- PHASE 3: CONTRACT (Enforce NOT NULL once backfill is 100% complete) ---
-- After version N+1 is 100% deployed and all historical rows have been backfilled:
BEGIN;
SET LOCAL lock_timeout = '2s';

-- Enforce default for future inserts
ALTER TABLE orders ALTER COLUMN discount_amount_cents SET DEFAULT 0;

-- Add NOT NULL constraint safely using a validated check constraint (Postgres best practice)
ALTER TABLE orders 
    ADD CONSTRAINT chk_orders_discount_not_null 
    CHECK (discount_amount_cents IS NOT NULL) 
    NOT VALID;
COMMIT;

ALTER TABLE orders VALIDATE CONSTRAINT chk_orders_discount_not_null;

-- ----------------------------------------------------------------------------
-- SECTION 5: REALISTIC TRANSACTIONAL QUERIES (Concurrency Demonstrations)
-- ----------------------------------------------------------------------------

-- Pattern A: Optimistic Concurrency Control (OCC) Order Status Update
-- Returns 0 rows affected if another transaction modified the row concurrently
UPDATE orders
SET status = 'CONFIRMED', version = version + 1, updated_at = CURRENT_TIMESTAMP
WHERE id = '123e4567-e89b-12d3-a456-426614174000' AND version = 1;

-- Pattern B: Pessimistic Row Locking for Inventory Deduction
-- Prevents concurrent race condition between simultaneous buyers
BEGIN;
SELECT id, available_stock, unit_price_cents
FROM inventory_items
WHERE id = 'e0000000-0000-0000-0000-000000000001'
FOR UPDATE;

UPDATE inventory_items
SET available_stock = available_stock - 2,
    version = version + 1,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 'e0000000-0000-0000-0000-000000000001' AND available_stock >= 2;
COMMIT;

-- Pattern C: High-Throughput Background Queue Worker (FOR UPDATE SKIP LOCKED)
-- Consumes unconfirmed orders without blocking other concurrent worker pods
BEGIN;
SELECT id, total_amount_cents, created_at
FROM orders
WHERE status = 'PENDING'
ORDER BY created_at ASC
LIMIT 10
FOR UPDATE SKIP LOCKED;

-- Simulated batch transition:
-- UPDATE orders SET status = 'CONFIRMED' WHERE id = ANY(:selected_ids);
COMMIT;

-- ----------------------------------------------------------------------------
-- SECTION 6: VERIFICATION & ROLLBACK STRATEGY
-- ----------------------------------------------------------------------------

-- Verification Query: Validate constraints, nullability, and index usage
SELECT 
    schemaname, tablename, indexname, tablespace
FROM pg_indexes 
WHERE tablename IN ('accounts', 'orders', 'order_items', 'inventory_items');

-- Rollback Demonstration: Reverting Phase 1 changes safely
-- ALTER TABLE orders DROP CONSTRAINT IF EXISTS chk_orders_discount_not_null;
-- ALTER TABLE orders DROP CONSTRAINT IF EXISTS chk_orders_discount_non_negative;
-- DROP INDEX CONCURRENTLY IF EXISTS idx_orders_discount;
-- ALTER TABLE orders DROP COLUMN IF EXISTS discount_amount_cents;
