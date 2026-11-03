# Data Security, Backup, and Recovery Standards

> **Level 2 Technology Standard — Database & Persistence**  
> **Applicability**: Mandatory for all database security configurations, role assignments, encryption policies, and disaster recovery drills. Adheres to [Universal Core Standards](../../01-principles/README.md) and [Security & Privacy Standards](../../10-security-and-privacy/01-credential-and-secret-management.md).

---

## 1. Definition & Core Concept

**Database Security, Backup, and Disaster Recovery** is the operational discipline of protecting persistent data from unauthorized access, exfiltration, corruption, and catastrophic infrastructure loss while guaranteeing verifiable point-in-time recovery capabilities.

Core persistence security and recovery pillars include:
*   **The Principle of Least Privilege Database Roles**: Applications `MUST NEVER` connect as `postgres`, `root`, or any role with `SUPERUSER` privileges. Databases `MUST` enforce distinct, dedicated roles for:
    *   **Migration Runner Role**: Holds DDL permissions (`CREATE`, `ALTER`, `DROP`) restricted to deployment pipelines.
    *   **Application Worker Role**: Holds DML permissions (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) restricted to application tables.
    *   **Read-Only Analytics Role**: Holds `SELECT` permissions restricted to read replicas.
*   **Defense-in-Depth Encryption**:
    *   *In Transit*: TLS 1.3 encryption enforced with strict certificate validation (`sslmode = verify-full`).
    *   *At Rest*: Transparent Data Encryption (TDE) or block-level filesystem encryption (LUKS / AWS EBS KMS).
    *   *Column-Level*: Client-side or `pgcrypto` envelope encryption for high-risk PII (e.g. Social Security numbers, tax IDs).
*   **Multi-Tenant Isolation via Row-Level Security (RLS)**: Enforcing tenant boundaries at the database engine level so that tenant leaks are impossible even if application queries omit `WHERE tenant_id = ?`.
*   **The Disaster Recovery Doctrine ("An Untested Backup is Not a Backup")**: Backups `MUST` be continuously validated through automated restoration drills measuring compliance against explicit **Recovery Point Objectives (RPO)** and **Recovery Time Objectives (RTO)** using Write-Ahead Log (WAL) archiving for Point-in-Time Recovery (PITR).

$$\text{PostgreSQL Storage} \xrightarrow[\text{Continuous Archiving}]{\text{pgBackRest / WAL-G}} \underbrace{\text{Encrypted S3 / Cloud Bucket}}_{\text{Immutable WORM Vault}} \xrightarrow[\text{Automated Weekly Drill}]{\text{Ephemeral Test Container}} \underbrace{\text{Verification Pass}}_{\text{RPO < 5m, RTO < 30m}}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Prevent Catastrophic Data Loss**: Guarantee that any ransomware event, accidental `DROP TABLE` command, hardware failure, or availability zone outage can be restored to a specific minute in time.
2.  **Eliminate Database Credential Exploitation**: Ensure that an application SQL injection (SQLi) vulnerability cannot be leveraged to drop databases, access system files, or escalate privileges.
3.  **Prevent Multi-Tenant Data Leaks**: Enforce database-enforced row isolation between organizational customers.
4.  **Guarantee Audit & Regulatory Compliance**: Meet GDPR, SOC 2, HIPAA, and PCI-DSS requirements through verifiable backup retention and cryptographic encryption.

---

## 3. Why It Matters

Data is the irreplaceable asset of any software company:
*   **The Superuser Application Risk**: Connecting an API backend as `postgres` or `admin` means a single SQL injection vulnerability or ORM exploit grants the attacker total control over the server, allowing them to read server environment files, exfiltrate passwords, or wipe out the entire database cluster.
*   **The Illusion of the Untested Backup**: Hundreds of companies have discovered during a ransomware attack or database crash that their automated backup cron job had been failing silently for 6 months, or that the dump file was corrupted and unparseable. **An unverified backup file is a dangerous operational delusion.**
*   **The Point-in-Time Recovery Difference**: Nightly `pg_dump` snapshots mean a failure at 4:30 PM results in 16.5 hours of permanently lost transactions (unacceptable RPO). Continuous Write-Ahead Log (WAL) archiving allows restoring to 4:29:59 PM, losing zero committed customer transactions.

---

## 4. When to Use It

Engineers `MUST` enforce these standards across:
*   All production and staging databases storing customer, financial, or stateful application data.
*   The design of database user roles, permissions, and network access control lists (ACLs).
*   Every cloud deployment architecture (AWS RDS, GCP Cloud SQL, self-hosted Kubernetes clusters).
*   Quarterly and automated continuous disaster recovery verification pipelines.

---

## 5. When NOT to Use It

Engineers `MAY` relax certain operational backup requirements only for:
*   **Ephemeral Local Development Databases**: Containerized local databases on developer laptops do not require WAL archiving or off-site backups; they should be reproducible from code migrations and seed scripts.
*   **Pure In-Memory Read Caches**: Redis caches that can be reconstructed completely from primary databases do not require Point-in-Time Recovery, though persistence snapshots (`RDB`/`AOF`) remain recommended for fast restarts.
*   **Throwaway Integration Test Fixtures**: Databases spun up inside CI/CD test runners for the duration of a test suite.

---

## 6. Advantages & Disadvantages

| Practice | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Least Privilege Role Separation** | Mitigates SQLi blast radius; protects schema from accidental runtime DDL modification. | Requires managing multiple database users and migration pipeline permissions. |
| **Row-Level Security (RLS)** | Kernel-level tenant data isolation; impossible for developer to accidentally leak cross-tenant data. | Minor query planning overhead; requires setting session variables (`SET app.current_tenant_id`). |
| **Point-in-Time Recovery (PITR)** | Sub-minute RPO; recover to the exact second before a catastrophic developer mistake. | Requires cloud object storage (S3) for WAL archives and dedicated tooling (`pgBackRest`/`WAL-G`). |
| **Automated Restoration Drills** | 100% empirical certainty that backups work; verifiable RTO metrics for SOC 2 audits. | Requires automated compute resources to spin up temporary test databases to run restore scripts. |

---

## 7. Practical Examples

### Bad Practice: Superuser Access, Missing TLS, and Untested Dump Scripts

```bash
# BAD: Application connects directly as superuser over plain-text network
DATABASE_URL="postgres://postgres:password123@db.example.com:5432/production?sslmode=disable"
```

```bash
# BAD: Naive cron job dump without verification, alerts, or WAL archiving
# If this fails or writes an empty file, nobody knows until disaster strikes!
0 2 * * * pg_dump -U postgres production > /tmp/backup.sql
```

### Good Practice: Role Separation, Row-Level Security, and Verified Backup Protocol

#### Step 1: Least Privilege Role Separation (SQL Setup)

```sql
-- GOOD: Production role separation in PostgreSQL 16+

-- 1. Create Migration Role (DDL permissions; used ONLY in CI/CD migration runner)
CREATE ROLE migration_runner WITH LOGIN PASSWORD '${MIGRATION_PASSWORD}' NOINHERIT;
GRANT CONNECT ON DATABASE production TO migration_runner;
GRANT USAGE, CREATE ON SCHEMA public TO migration_runner;

-- 2. Create Application DML Role (Zero DDL permissions; used by API server)
CREATE ROLE app_user WITH LOGIN PASSWORD '${APP_PASSWORD}' NOINHERIT;
GRANT CONNECT ON DATABASE production TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;

-- Grant only required DML operations on existing and future tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

-- Grant sequence permissions for identity/auto-increment columns
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_user;

-- Revoke all administrative and superuser rights from application user
REVOKE CREATE ON SCHEMA public FROM app_user;
```

#### Step 2: Multi-Tenant Row-Level Security (RLS)

```sql
-- GOOD: Enforcing tenant isolation at the database kernel level
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Create policy ensuring queries can only see/mutate the active tenant's rows
CREATE POLICY tenant_isolation_policy ON orders
    FOR ALL
    USING (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID)
    WITH CHECK (organization_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID);

-- Application middleware sets the session variable before executing queries:
-- SET LOCAL app.current_org_id = '123e4567-e89b-12d3-a456-426614174000';
```

#### Step 3: Production Backup & Restoration Drill Protocol (`pgBackRest`)

```ini
; GOOD: Production pgbackrest.conf configuration for continuous WAL archiving & PITR
[global]
repo1-type=s3
repo1-s3-bucket=company-db-backups-vault
repo1-s3-endpoint=s3.us-east-1.amazonaws.com
repo1-s3-region=us-east-1
repo1-s3-key-type=auto
repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=${BACKUP_ENCRYPTION_KEY}
repo1-retention-full=4
repo1-retention-diff=14

[production]
pg1-path=/var/lib/postgresql/16/main
pg1-user=postgres
```

```bash
# Automated Disaster Recovery Restoration Verification Script (Executed weekly in CI/CD)
#!/usr/bin/env bash
set -euo pipefail

echo "=== STARTING AUTOMATED RESTORATION DRILL ==="
# 1. Spin up clean, ephemeral PostgreSQL test container
# 2. Restore latest backup archive from S3
pgbackrest --stanza=production --type=time "--target=2026-11-03 12:00:00Z" restore

# 3. Boot restored database
pg_ctlcluster 16 test start

# 4. Verify data integrity and record count
RESTORED_ROWS=$(psql -U postgres -d production -t -c "SELECT COUNT(*) FROM accounts;")
if [ "$RESTORED_ROWS" -gt 0 ]; then
    echo "SUCCESS: Restoration verified. Total accounts restored: $RESTORED_ROWS"
    exit 0
else
    echo "FATAL: Backup restored zero records! Data integrity failure!"
    exit 1
fi
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: The "Untested Backup File" Delusion
*   **The Trap**: Relying on nightly `pg_dump` cron jobs without automated restoration verification.
*   **The Consequence**: When a catastrophic failure occurs, the engineering team discovers the dump script failed months ago, was writing empty 0-byte files, or fails during restoration due to missing extension dependencies.
*   **Mitigation**: **Every organization MUST run automated weekly restoration drills** into an isolated staging environment, verifying row counts and table integrity to prove recoverability.

### Trap 2: Running Application Workloads as Superuser
*   **The Trap**: Using the default `postgres` superuser credentials in application `DATABASE_URL` strings.
*   **The Consequence**: A single SQL injection vulnerability or compromised application pod can execute `DROP DATABASE`, create new superuser accounts, or read private keys from the host operating system.
*   **Mitigation**: The application `MUST` connect using a restricted role possessing only `SELECT`, `INSERT`, `UPDATE`, `DELETE` permissions, with zero `CREATE TABLE` or administrative privileges.

### Trap 3: Missing Point-in-Time Recovery (WAL Archiving)
*   **The Trap**: Relying solely on once-a-day snapshots.
*   **The Consequence**: A failure at 3:00 PM requires restoring the previous night's 2:00 AM backup, permanently wiping out 13 hours of customer payments, orders, and user registrations (Recovery Point Objective failure).
*   **Mitigation**: Production databases `MUST` configure continuous Write-Ahead Log (WAL) archiving to cloud storage, enabling **Point-in-Time Recovery (PITR)** to any arbitrary second within the retention window.

---

## 9. Verification Checklist

- [ ] **Role Separation Enforced**: The application runtime connects with a restricted DML-only role (`app_user`). Zero `SUPERUSER` or `CREATE` permissions exist in application connection pools.
- [ ] **TLS Enforcement**: Database connections mandate TLS with strict certificate verification (`sslmode=verify-full`).
- [ ] **Continuous WAL Archiving (PITR)**: Write-Ahead Logs are archived continuously to an encrypted off-site cloud vault, enabling recovery to any exact minute ($\text{RPO} \le 5\text{ minutes}$).
- [ ] **Automated Restoration Testing**: An automated job runs weekly to restore backups into an isolated test environment and verify table integrity ($\text{RTO} \le 30\text{ minutes}$).
- [ ] **Encryption at Rest**: Storage volumes utilize AES-256 block encryption (EBS KMS / LUKS) with managed customer keys.
- [ ] **Multi-Tenant Row-Level Security**: Multi-tenant tables enforce database-level Row-Level Security (RLS) policies guarding tenant isolation.
