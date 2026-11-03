# Safe Schema Migrations Standards

> **Level 2 Technology Standard — Database & Persistence**  
> **Applicability**: Mandatory for all database schema evolution scripts, DDL execution pipelines, and continuous deployment workflows. Adheres to [Universal Core Standards](../../01-principles/README.md) and [SDLC Deployment Standards](../../02-lifecycle/11-deployment.md).

---

## 1. Definition & Core Concept

**Safe Schema Migrations** is the disciplined engineering practice of evolving database schemas, tables, columns, indexes, and data formats without causing query lockouts, application downtime, or transaction rollbacks during continuous deployment.

Core migration principles include:
*   **The Expand-and-Contract (Parallel Run) Pattern**: Schema mutations `MUST` be broken down into phased, non-breaking steps so that both the currently running application version ($N$) and the newly deploying application version ($N+1$) can run concurrently against the database without error.
*   **Lock Timeout Discipline**: Every DDL migration script `MUST` set a strict, short `lock_timeout` (e.g. `SET lock_timeout = '2s';`). This prevents DDL operations from waiting indefinitely behind long-running queries while blocking all subsequent incoming read/write traffic.
*   **Non-Blocking DDL Execution**: Production index additions `MUST` use `CREATE INDEX CONCURRENTLY`. Foreign key and check constraints `MUST` be added with `NOT VALID` and validated in a separate non-blocking pass.
*   **Chunked Batch Backfills**: Data migrations across tables exceeding $100,000$ rows `MUST` be executed in small, cursor-paginated chunks with pauses to prevent lock contention, transaction log (WAL) exhaustion, and replication lag.

$$\begin{array}{rcccl}
\text{Phase 1 (Expand)} & : & \text{Add new column/table nullable or with default} & \longrightarrow & \text{Both App } N \text{ and } N+1 \text{ compatible} \\
\text{Phase 2 (Dual-Write)} & : & \text{App } N+1 \text{ writes both old and new formats} & \longrightarrow & \text{Backfill historical data in chunks} \\
\text{Phase 3 (Contract)} & : & \text{App reads new format exclusively} & \longrightarrow & \text{Drop old column/indexes safely}
\end{array}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Eliminate Database-Induced Downtime**: Prevent full table locks (`AccessExclusiveLock`) from causing request queuing, timeout cascades, and service outages during deployments.
2.  **Enable Continuous Deployment (Zero-Downtime Rollouts)**: Guarantee that schema changes are strictly backward-compatible, enabling blue-green and rolling canary deployments without service interruption.
3.  **Prevent Replication Lag & WAL Saturation**: Prevent massive, single-transaction updates from saturating database Write-Ahead Logs (WAL) and stalling read replicas.
4.  **Guarantee Safe Reversibility**: Ensure every migration step can be rolled back or paused safely without destroying production data.

---

## 3. Why It Matters

In high-concurrency production environments, a single naive DDL statement can knock your platform offline within seconds:
*   **The Queue Behind the Exclusive Lock**: Running `ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'active';` on an older engine or adding an unvalidated foreign key acquires an `AccessExclusiveLock`. If a slow read query is currently running, the migration waits for it. Even worse: **all subsequent incoming queries queue up behind the waiting migration lock**, exhausting database connection pools and taking down all customer-facing APIs within 5 seconds.
*   **The Big-Bang Migration Trap**: Renaming a column in a single migration (`ALTER TABLE users RENAME COLUMN phone TO phone_number;`) instantly breaks all active pods running application version $N$. Until all new version $N+1$ containers have booted, all user logins fail with missing column errors.
*   **WAL Disk Exhaustion During Backfills**: Executing `UPDATE accounts SET is_verified = TRUE;` across 10,000,000 rows in a single transaction fills up the WAL buffer, exhausts disk space, causes replica lag to spike to hours, and locks the entire table against concurrent writes for the duration of the query.

---

## 4. When to Use It

Engineers `MUST` enforce these safe migration practices:
*   Whenever altering existing tables, columns, indexes, types, or constraints in any production, staging, or shared development environment.
*   Whenever backfilling or transforming historical data.
*   Whenever renaming, dropping, or splitting existing database columns or tables.
*   When configuring continuous integration (CI) migration linter gates.

---

## 5. When NOT to Use It

Engineers `MAY` use direct, single-phase migrations only in these scenarios:
*   **Ephemeral Local Development**: Creating, dropping, and seeding fresh database instances locally on developer machines before code is committed to version control.
*   **Brand New Tables**: Creating a completely new table with its primary key and initial constraints does not affect existing production traffic or running application code.
*   **Scheduled Offline Maintenance Windows**: In enterprise legacy batch systems where full application downtime is officially scheduled, documented, and approved by business stakeholders.

---

## 6. Advantages & Disadvantages

| Migration Approach | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Expand-and-Contract** | Zero downtime; supports rolling and blue-green deployments; reversible at every step. | Requires multiple phased PRs and deployments over days/weeks instead of a single quick script. |
| **`CREATE INDEX CONCURRENTLY`** | Builds index without locking writes to the table; zero interruption to production traffic. | Takes up to $3\times$ longer to build; consumes more CPU/IO; cannot run inside an explicit transaction block. |
| **Chunked Batch Updates** | Prevents lock contention and WAL bloat; allows database autovacuum to operate smoothly. | Requires state tracking (cursor offset) and dedicated backfill worker scripts. |
| **Lock Timeouts (`lock_timeout`)** | Fails fast if locks cannot be acquired; protects production APIs from queue-induced outages. | Migration script may fail and need to be retried during low-traffic maintenance periods. |

---

## 7. Practical Examples

### Bad Practice: Blocking DDL, Big-Bang Renames, and Unbounded Single-Transaction Updates

```sql
-- BAD: Catastrophic production outage script
-- Trap 1: No lock_timeout set. Waits indefinitely behind slow queries, blocking all new reads/writes!
-- Trap 2: Building index without CONCURRENTLY locks the entire table against all INSERT/UPDATE/DELETE.
CREATE INDEX idx_orders_customer_id ON orders (customer_id);

-- Trap 3: Big-Bang column rename breaks all running vN application containers instantly!
ALTER TABLE users RENAME COLUMN full_name TO legal_name;

-- Trap 4: Single-transaction 10-million row update exhausts WAL buffer and locks table for minutes!
UPDATE accounts SET status = 'ACTIVE' WHERE status IS NULL;

-- Trap 5: Adding unvalidated foreign key locks table to scan all rows
ALTER TABLE orders ADD CONSTRAINT fk_orders_account FOREIGN KEY (account_id) REFERENCES accounts (id);
```

### Good Practice: Multi-Phase Expand-and-Contract Migration with Lock Timeouts and Non-Blocking DDL

#### Step 1: Expand Phase (Safe Non-Blocking DDL in Migration Script)

```sql
-- GOOD: Production migration script with defensive lock timeouts
SET lock_timeout = '2s';
SET statement_timeout = '5s';

-- 1. Adding a new column with default (Fast metadata-only update in Postgres 11+)
ALTER TABLE users ADD COLUMN legal_name TEXT;

-- 2. Adding a foreign key without blocking full-table scan (NOT VALID)
ALTER TABLE orders 
    ADD CONSTRAINT fk_orders_account 
    FOREIGN KEY (account_id) REFERENCES accounts (id) 
    NOT VALID;

-- 3. Validate constraint in a separate step (Acquires weak SHARE UPDATE EXCLUSIVE lock; zero write blockage!)
ALTER TABLE orders VALIDATE CONSTRAINT fk_orders_account;
```

#### Step 2: Non-Blocking Index Creation (Outside Transaction Block)

```sql
-- GOOD: Must be run outside of a multi-statement transaction block
-- Does not block concurrent INSERT, UPDATE, or DELETE statements!
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);
```

#### Step 3: Chunked Batch Backfill Worker Script (Node.js / TypeScript Example)

```typescript
// GOOD: Chunked batch backfill with cursor pagination and vacuum sleep
import { dbPool } from './db';

export async function backfillLegalNameInBatches() {
  const BATCH_SIZE = 1000;
  let lastProcessedId = '00000000-0000-0000-0000-000000000000';
  let totalMigrated = 0;

  while (true) {
    // 1. Fetch small batch by deterministic cursor
    const result = await dbPool.query(
      `UPDATE users 
       SET legal_name = full_name 
       WHERE id IN (
           SELECT id FROM users 
           WHERE id > $1 AND legal_name IS NULL 
           ORDER BY id ASC 
           LIMIT $2
       ) 
       RETURNING id;`,
      [lastProcessedId, BATCH_SIZE]
    );

    if (result.rows.length === 0) {
      console.log(`Backfill complete. Total rows updated: ${totalMigrated}`);
      break;
    }

    lastProcessedId = result.rows[result.rows.length - 1].id;
    totalMigrated += result.rows.length;
    console.log(`Migrated ${totalMigrated} rows. Last ID: ${lastProcessedId}`);

    // 2. Pause between batches to allow autovacuum and replication catch-up
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
}
```

#### Step 4: Contract Phase (Remove Old Column After App Version $N+1$ is 100% Deployed)

```sql
-- GOOD: Contract phase executed after old code is completely decommissioned
SET lock_timeout = '2s';
ALTER TABLE users DROP COLUMN full_name;
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: Missing `lock_timeout` Leading to Catastrophic Connection Starvation
*   **The Trap**: Executing `ALTER TABLE` or `CREATE INDEX` without configuring `SET lock_timeout = '2s'`.
*   **The Consequence**: If an active analytical query is running against the table, the DDL waits in the lock queue. Any incoming customer transaction requesting any lock on that table queues up behind the waiting DDL, quickly consuming all server connection handles and crashing the entire API gateway.
*   **Mitigation**: Every production migration runner `MUST` set a short `lock_timeout` ($\le 2\text{–}3\text{ seconds}$). If the lock cannot be acquired, the migration aborts immediately, allowing production traffic to continue unhindered.

### Trap 2: Creating Indexes Without `CONCURRENTLY`
*   **The Trap**: Running standard `CREATE INDEX idx_name ON table (col);` on a production table.
*   **The Consequence**: Standard index creation acquires a `ShareLock`, allowing read queries but completely blocking all `INSERT`, `UPDATE`, and `DELETE` transactions until the entire index is built (which can take hours on multi-million row tables).
*   **Mitigation**: All production indexes `MUST` be created using `CREATE INDEX CONCURRENTLY`.

### Trap 3: The Big-Bang Column Rename Fallacy
*   **The Trap**: Renaming a column in a single migration script because "the deployment will only take 30 seconds."
*   **The Consequence**: During rolling deployments or container updates, pods running old code ($N$) and new code ($N+1$) co-exist for minutes. Old pods crash because the old column name vanished; rolling back crashes new pods because they expect the new column name.
*   **Mitigation**: Renaming columns `MUST` follow the 4-phase Expand-and-Contract lifecycle: (1) Add new column, (2) Dual-write to both columns in application code, (3) Backfill historical data, (4) Switch reads to new column, (5) Drop old column.

---

## 9. Verification Checklist

- [ ] **Defensive Lock Timeouts**: Every migration script begins with `SET lock_timeout = '2s';` and `SET statement_timeout = '5s';`.
- [ ] **Non-Blocking Indexing**: Indexes on existing production tables are created using `CREATE INDEX CONCURRENTLY` outside multi-statement transaction blocks.
- [ ] **Two-Phase Constraints**: Foreign keys and check constraints are added with `NOT VALID`, then validated in a subsequent non-blocking pass.
- [ ] **Expand-and-Contract Discipline**: Column renames and type changes follow multi-phase backward-compatible deployments; zero big-bang renames exist.
- [ ] **Chunked Backfills**: Large-table data updates are split into batches of $\le 5,000$ rows with sleep intervals between iterations.
- [ ] **Reversible Migrations**: Every forward migration (`V__*.sql`) has a documented, tested rollback or recovery strategy.
