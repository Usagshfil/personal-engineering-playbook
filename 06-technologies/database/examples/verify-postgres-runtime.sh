#!/usr/bin/env bash
# ==============================================================================
# verify-postgres-runtime.sh
# 
# Automated CI/CD & Local Runtime Verifier for PostgreSQL 16+ Architecture
# Executes representative-schema-and-migration.sql against live PostgreSQL instance
# and empirically verifies schema creation, migrations, constraints, and roles.
# ==============================================================================

set -euo pipefail

PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-postgres}"
PGPASSWORD="${PGPASSWORD:-postgres}"
PGDATABASE="${PGDATABASE:-test_playbook_db}"

export PGPASSWORD

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="${SCRIPT_DIR}/representative-schema-and-migration.sql"

echo "================================================================================"
echo "   POSTGRESQL 16+ RUNTIME VERIFICATION SUITE"
echo "================================================================================"
echo "Host       : ${PGHOST}:${PGPORT}"
echo "Database   : ${PGDATABASE}"
echo "User       : ${PGUSER}"
echo "SQL Script : ${SQL_FILE}"
echo "Time       : $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "--------------------------------------------------------------------------------"

# Step 1: Wait for PostgreSQL service readiness
echo "Waiting for PostgreSQL service at ${PGHOST}:${PGPORT}..."
MAX_ATTEMPTS=30
ATTEMPT=0
until pg_isready -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" > /dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ "${ATTEMPT}" -ge "${MAX_ATTEMPTS}" ]; then
        echo "ERROR: PostgreSQL service did not become ready within ${MAX_ATTEMPTS} seconds."
        exit 1
    fi
    sleep 1
done
echo "PASS: PostgreSQL service is ready."

# Step 2: Initialize fresh test database
echo "Creating disposable test database '${PGDATABASE}'..."
psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d postgres -c "DROP DATABASE IF EXISTS ${PGDATABASE};" > /dev/null
psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d postgres -c "CREATE DATABASE ${PGDATABASE};" > /dev/null
echo "PASS: Clean test database created."

# Step 3: Execute Schema & Migration Script
echo "Executing representative-schema-and-migration.sql..."
psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -f "${SQL_FILE}" > /dev/null
echo "PASS: Schema and migrations executed successfully."

# Step 4: Empirical Invariant Checks
echo "Running automated empirical invariant checks..."

# Check 4.1: Verify Table Existence
TABLE_COUNT=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -t -A -c \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('accounts', 'inventory_items', 'orders', 'order_items', 'audit_ledger');")
if [ "${TABLE_COUNT}" -eq 5 ]; then
    echo "PASS: All 5 required tables exist in public schema."
else
    echo "FAIL: Expected 5 tables, found ${TABLE_COUNT}."
    exit 1
fi

# Check 4.2: Verify Role Creation
ROLE_COUNT=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -t -A -c \
  "SELECT count(*) FROM pg_roles WHERE rolname IN ('migration_runner', 'app_user', 'readonly_analyst');")
if [ "${ROLE_COUNT}" -eq 3 ]; then
    echo "PASS: All 3 least-privilege roles exist."
else
    echo "FAIL: Expected 3 roles, found ${ROLE_COUNT}."
    exit 1
fi

# Check 4.3: Verify Declarative Check Constraint (Email Format)
set +e
psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -c \
  "INSERT INTO accounts (organization_id, email, full_name) VALUES (gen_random_uuid(), 'not-an-email', 'Jane Doe');" > /dev/null 2>&1
STATUS=$?
set -e
if [ "${STATUS}" -ne 0 ]; then
    echo "PASS: Declarative check constraint properly rejected invalid email."
else
    echo "FAIL: Check constraint failed to reject invalid email."
    exit 1
fi

# Check 4.4: Verify Declarative Check Constraint (Negative Inventory Stock)
set +e
psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -c \
  "INSERT INTO inventory_items (sku, name, available_stock, unit_price_cents) VALUES ('SKU-TEST', 'Widget', -5, 1000);" > /dev/null 2>&1
STATUS=$?
set -e
if [ "${STATUS}" -ne 0 ]; then
    echo "PASS: Declarative check constraint properly rejected negative inventory stock."
else
    echo "FAIL: Check constraint failed to reject negative stock."
    exit 1
fi

# Check 4.5: Verify Optimistic Concurrency Control (OCC)
psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -c \
  "INSERT INTO inventory_items (id, sku, name, available_stock, unit_price_cents, version) VALUES ('a0000000-0000-0000-0000-000000000001', 'SKU-OCC', 'OCC Item', 10, 500, 1);" > /dev/null

UPDATED_ROWS=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -t -A -c \
  "WITH update_res AS (
     UPDATE inventory_items SET available_stock = 8, version = 2 WHERE id = 'a0000000-0000-0000-0000-000000000001' AND version = 1 RETURNING id
   ) SELECT count(*) FROM update_res;")

if [ "${UPDATED_ROWS}" -eq 1 ]; then
    echo "PASS: OCC version update succeeded on matching version."
else
    echo "FAIL: OCC version update failed."
    exit 1
fi

STALE_ROWS=$(psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" -t -A -c \
  "WITH update_res AS (
     UPDATE inventory_items SET available_stock = 6, version = 3 WHERE id = 'a0000000-0000-0000-0000-000000000001' AND version = 1 RETURNING id
   ) SELECT count(*) FROM update_res;")

if [ "${STALE_ROWS}" -eq 0 ]; then
    echo "PASS: OCC update safely rejected stale version update (0 rows affected)."
else
    echo "FAIL: OCC allowed concurrent modification on stale version."
    exit 1
fi

# Clean up
psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d postgres -c "DROP DATABASE ${PGDATABASE};" > /dev/null

echo "--------------------------------------------------------------------------------"
echo "   POSTGRESQL 16+ RUNTIME VERIFICATION COMPLETE: ALL CHECKS PASSED (0 ERRORS)  "
echo "================================================================================"
exit 0
