# Transactions and Concurrency Standards

> **Level 2 Technology Standard — Database & Persistence**  
> **Applicability**: Mandatory for all multi-statement database operations, ACID boundary management, concurrent mutations, and queue workers. Adheres to [Universal Core Standards](../../01-principles/README.md) and [System Architecture Standards](../../03-architecture/09-state-management.md).

---

## 1. Definition & Core Concept

**Transactions and Concurrency Management** is the database architecture practice of ensuring that groups of interrelated state mutations execute atomically, consistently, and durably according to mathematical **ACID** properties while managing concurrent access to prevent data anomalies, race conditions, and deadlocks.

Core transactional mechanisms include:
*   **PostgreSQL Multi-Version Concurrency Control (MVCC)**: Instead of locking rows against concurrent reads, readers never block writers, and writers never block readers. Every query sees a consistent snapshot of the database taken at a specific point in logical time.
*   **Isolation Level Discipline**: Understanding the precise anomalies prevented by each isolation level:
    *   **Read Committed** *(PostgreSQL Default)*: Guarantees no Dirty Reads. Each statement sees only rows committed before that statement began.
    *   **Repeatable Read**: Guarantees consistent snapshot across the entire transaction; prevents Non-Repeatable Reads and Phantom Reads.
    *   **Serializable**: Guarantees true serial execution semantics using Serializable Snapshot Isolation (SSI), preventing Write Skew anomalies.
*   **Concurrency Control Paradigms**:
    *   **Optimistic Concurrency Control (OCC)**: Using a `version INT NOT NULL` column to detect concurrent modifications without holding database locks. Ideal for low-contention web requests.
    *   **Pessimistic Locking (`SELECT ... FOR UPDATE`)**: Explicitly locking target rows against concurrent modification. Essential for high-contention financial balance transfers and inventory deductions.
    *   **Lock-Free Queue Consuming (`FOR UPDATE SKIP LOCKED`)**: Allowing multiple concurrent background workers to consume distinct jobs without contention or lock waits.

$$\text{Isolation Spectrum} : \underbrace{\text{Read Committed}}_{\text{Default (No Dirty Reads)}} \longrightarrow \underbrace{\text{Repeatable Read}}_{\text{Snapshot (No Phantoms)}} \longrightarrow \underbrace{\text{Serializable}}_{\text{No Write Skew / Anomalies}}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Guarantee Financial & State Integrity**: Prevent double-spending, negative balances, and phantom reservations under heavy concurrent traffic.
2.  **Eliminate Concurrency Anomalies**: Protect business operations from Dirty Reads, Non-Repeatable Reads, Lost Updates, and Write Skew.
3.  **Prevent and Mitigate Deadlocks**: Establish deterministic lock acquisition protocols so concurrent transactions do not lock each other indefinitely.
4.  **Provide Durable Idempotency Foundations**: Provide atomic unique constraint boundaries that back application-level effectively-once request processing.

---

## 3. Why It Matters

Without strict concurrency controls, concurrent requests produce catastrophic financial anomalies:
*   **The Lost Update Disaster**: Two concurrent transactions read Account Balance = \$100. Transaction A debits \$30 (new balance \$70). Transaction B simultaneously debits \$40 (new balance \$60). Transaction B commits last, overwriting Transaction A's debit. The bank has lost \$30 and the customer account state is corrupted.
*   **The Write Skew Trap in Booking Systems**: Two doctors on call both request taking the evening off. The rule requires at least one doctor on duty. Under Read Committed or Repeatable Read, both doctors concurrently see the other on duty and both requests commit, leaving zero doctors on duty. Only **Serializable Isolation** or explicit row locking detects this write skew.
*   **Deadlock Cascades**: Transaction 1 updates Account A, then attempts to update Account B. Transaction 2 updates Account B, then attempts to update Account A. Both transactions block each other permanently until the database terminates one with a deadlock abort exception.
*   **Long-Running Transaction Connection Leaks**: Keeping an active database transaction open while waiting for an external HTTP API call (e.g. Stripe) ties up connection pool handles for seconds, causing pool exhaustion.

---

## 4. When to Use It

Engineers `MUST` enforce these transaction and concurrency standards:
*   Whenever a business operation mutates multiple rows, across multiple tables, or updates inventory/financial balances.
*   When implementing background task queues or distributed job processing (`FOR UPDATE SKIP LOCKED`).
*   When handling concurrent state transitions (e.g. order status transitions, reservation booking).
*   When executing high-risk financial transfers or ledger accounting.

---

## 5. When NOT to Use It

Engineers `SHOULD NOT`:
*   **Wrap Remote HTTP / External Network Calls Inside Database Transactions (AVOID)**: **NEVER** hold an open database transaction while making external network calls (e.g. sending emails, querying payment gateways, calling third-party webhooks). Network latency or timeouts will hold row and table locks open for seconds, starving connection pools.
*   **Use Serializable Everywhere**: While Serializable provides maximum safety, it introduces abort-and-retry overhead ($40001\text{ serialization\_failure}$). Reserve Serializable for complex multi-row invariant checks where pessimistic row locking is infeasible.
*   **Use Heavy Locks on Read-Only Queries**: Never use `SELECT ... FOR UPDATE` on queries that do not intend to mutate the selected rows immediately.

---

## 6. Advantages & Disadvantages

| Concurrency Pattern | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Optimistic Concurrency Control (OCC)** | Zero database lock contention; maximum throughput for read-heavy entities. | Fails fast with optimistic lock exception if another process modified the row; requires client retry. |
| **Pessimistic Locking (`FOR UPDATE`)** | Guarantees mutual exclusion; prevents concurrent updates completely. | Blocks concurrent transactions; can cause lock waits and deadlocks if not sequenced deterministically. |
| **`FOR UPDATE SKIP LOCKED`** | Perfect multi-worker queue throughput; zero lock wait contention; simple and robust. | Requires PostgreSQL 9.5+ or MySQL 8+; only suitable for decoupled queue work items. |
| **Serializable Snapshot Isolation (SSI)** | Absolute protection against all write skew and race conditions; mathematically sound. | High transaction abort rate under heavy write contention; requires automated retry loops. |

---

## 7. Practical Examples

### Bad Practice: Unsafe Check-Then-Act Race Condition (Lost Update)

```sql
-- BAD: Vulnerable to lost update race conditions under concurrent requests
-- Client 1 and Client 2 execute concurrently:

-- Step 1: Read current balance (Both see 100)
SELECT balance FROM accounts WHERE id = 'acc-123';

-- Client 1 debits 30 in application memory (100 - 30 = 70)
-- Client 2 debits 40 in application memory (100 - 40 = 60)

-- Step 2: Overwrite with blind update
UPDATE accounts SET balance = 70 WHERE id = 'acc-123'; -- Client 1 commits
UPDATE accounts SET balance = 60 WHERE id = 'acc-123'; -- Client 2 commits and OVERWRITES Client 1!
```

### Good Practice: Atomic In-Place Updates, Pessimistic Locking, and Optimistic Concurrency

#### Pattern A: Atomic In-Place Mutation (Single Statement)

```sql
-- GOOD: Database-level atomic mutation prevents lost update without explicit locks
UPDATE accounts 
SET balance = balance - 30, updated_at = CURRENT_TIMESTAMP
WHERE id = 'acc-123' AND balance >= 30;

-- Verify rows affected: if rows == 0, abort with InsufficientFundsException
```

#### Pattern B: Pessimistic Row Locking with Deterministic Deadlock Prevention

```sql
-- GOOD: Money transfer between two accounts with deterministic sorting to prevent deadlocks
BEGIN;

-- Step 1: Determine alphabetical/numerical order of account IDs to avoid deadlocks
-- Always lock smaller ID first, larger ID second!
-- Assuming acc-100 < acc-200:

SELECT id, balance 
FROM accounts 
WHERE id = 'acc-100' 
FOR UPDATE; -- Locks acc-100

SELECT id, balance 
FROM accounts 
WHERE id = 'acc-200' 
FOR UPDATE; -- Locks acc-200

-- Step 2: Perform verified mutations
UPDATE accounts SET balance = balance - 50 WHERE id = 'acc-100';
UPDATE accounts SET balance = balance + 50 WHERE id = 'acc-200';

INSERT INTO transaction_ledger (sender_id, receiver_id, amount_cents)
VALUES ('acc-100', 'acc-200', 5000);

COMMIT;
```

#### Pattern C: Optimistic Concurrency Control (OCC)

```sql
-- GOOD: Optimistic locking using version column
-- 1. Read entity with version
SELECT id, total_amount_cents, version FROM orders WHERE id = 'ord-555';

-- 2. Update conditionally checking version; increment version atomically
UPDATE orders 
SET total_amount_cents = 7500, version = version + 1, updated_at = CURRENT_TIMESTAMP
WHERE id = 'ord-555' AND version = 3;

-- If rows affected == 0, another concurrent transaction committed first!
-- Application raises OptimisticLockException and re-reads fresh state.
```

#### Pattern D: High-Throughput Worker Queue (`SKIP LOCKED`)

```sql
-- GOOD: Multi-worker background job polling without contention
BEGIN;

SELECT id, job_type, payload
FROM background_jobs
WHERE status = 'PENDING' AND scheduled_at <= CURRENT_TIMESTAMP
ORDER BY scheduled_at ASC
LIMIT 10
FOR UPDATE SKIP LOCKED; -- Skips rows currently locked by other concurrent worker pods!

UPDATE background_jobs
SET status = 'PROCESSING', started_at = CURRENT_TIMESTAMP
WHERE id = ANY($selected_ids);

COMMIT;
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: The Remote HTTP Call Inside Transaction Pitfall
*   **The Trap**: Starting a database transaction, updating a row, making a remote HTTP call to Stripe or SendGrid, and then committing.
*   **The Consequence**: If the third-party HTTP gateway takes 5 seconds to respond or times out, the database row lock and connection handle are held for 5 seconds. Under high traffic, all connection pool handles are rapidly exhausted, taking down the entire backend application.
*   **Mitigation**: **NEVER make remote network calls inside database transactions.** Execute external calls *outside* transactions, or use the **Transactional Outbox Pattern** to record the intent in the database first and process the external dispatch asynchronously.

### Trap 2: Inconsistent Lock Acquisition Order (The Deadlock Trap)
*   **The Trap**: Worker 1 transfers money from Account A to Account B (locking A then B). Worker 2 simultaneously transfers money from Account B to Account A (locking B then A).
*   **The Consequence**: A mutual circular lock wait causes an instant database deadlock error, aborting one or both transactions.
*   **Mitigation**: Transactions mutating multiple rows `MUST` sort the row IDs deterministically (e.g. `WHERE id IN (A, B) ORDER BY id`) and acquire locks in uniform sorted order across all application endpoints.

### Trap 3: The Check-Then-Act Race Condition
*   **The Trap**: Executing `SELECT balance FROM accounts`, evaluating `balance >= amount` in application memory, and then executing `UPDATE accounts SET balance = new_balance`.
*   **The Consequence**: Under concurrent requests, multiple threads read the original balance simultaneously and all succeed in debiting, driving account balances negative.
*   **Mitigation**: Use atomic SQL conditions (`WHERE balance >= amount`) or lock the row defensively with `FOR UPDATE`.

---

## 9. Verification Checklist

- [ ] **Zero External Network Calls in Transactions**: Database transactions do not wrap HTTP client calls, email dispatches, or third-party webhooks.
- [ ] **Deterministic Lock Ordering**: Multi-row update transactions sort primary keys to prevent circular deadlock waits.
- [ ] **Lost Update Prevention**: Concurrent balance or inventory modifications use atomic updates (`balance = balance - X WHERE balance >= X`), pessimistic locking (`FOR UPDATE`), or optimistic concurrency (`version = version + 1`).
- [ ] **Queue Worker Efficiency**: Background polling workers utilize `FOR UPDATE SKIP LOCKED` to prevent lock contention between worker pods.
- [ ] **Short Transaction Budgets**: Transactions are bounded and execute within milliseconds; statement timeouts are configured.
- [ ] **Durable Idempotency Synergy**: Database unique constraints enforce exact deduplication for incoming idempotency keys.
