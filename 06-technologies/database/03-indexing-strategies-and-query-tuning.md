# Indexing Strategies and Query Tuning Standards

> **Level 2 Technology Standard — Database & Persistence**  
> **Applicability**: Mandatory for all relational database queries, table indexes, ORM mapping profiles, and query optimization pipelines. Adheres to [Universal Core Standards](../../01-principles/README.md) and [Database Architecture Standards](../../03-architecture/11-database-integration.md).

---

## 1. Definition & Core Concept

**Database Indexing and Query Tuning** is the engineering discipline of designing auxiliary search data structures (primarily balanced B-Trees, along with specialized GIN, GiST, and BRIN indexes) to minimize disk I/O, reduce CPU latency, and eliminate sequential table scans for critical query workloads without imposing prohibitive write overhead.

Core indexing fundamentals include:
*   **The B-Tree Left-to-Right Prefix Rule**: Composite indexes on `(A, B, C)` can satisfy queries on `WHERE A = 1`, `WHERE A = 1 AND B = 2`, and `WHERE A = 1 AND B = 2 AND C = 3`. However, they *cannot* accelerate queries filtering solely on `WHERE B = 2` or `WHERE C = 3`.
*   **The Selectivity & Ordering Heuristic (F19)**: The sequence `Equality` $\to$ `Range/Inequality` $\to$ `Sort Ordering` $\to$ `Covering (INCLUDE)` is an effective heuristic, but `NOT` an immutable recipe. The optimal index structure depends on predicate selectivity, sort order, query frequency, index size, write volume, and PostgreSQL planner cost estimates. For example, if a range predicate is extraordinarily selective (matching 2 rows out of 10 million), placing it earlier in the index can outperform an equality predicate with low selectivity.
*   **Trade-Offs of Covering Indexes (`INCLUDE`)**: Appending non-key payload columns via `INCLUDE` allows fast Index-Only Scans by avoiding table heap lookups. However, engineers `MUST` evaluate two critical penalties:
    *   **Index Bloat & Buffer Eviction**: Each included column widens the index leaf pages, reducing the number of index tuples per 8KB page and increasing pressure on PostgreSQL `shared_buffers`.
    *   **Write Amplification & HOT Update Elimination**: Updating an included column forces a physical index update across all index leaves. Critically, modifying an indexed column disables PostgreSQL **HOT (Heap-Only Tuple)** optimization, turning an in-page heap update into a heavy table and index write cycle that generates table bloat. Never include high-churn columns (such as `view_count` or `last_accessed_at`) in an `INCLUDE` clause.
*   **Execution Plan Verification (`EXPLAIN (ANALYZE, BUFFERS)`)**: Index design decisions `MUST` be verified through empirical query plans on production-scale data volumes, evaluating `Buffers: shared hit/read`, heap fetch counts, scan types (Index Scan vs. Index-Only Scan vs. Bitmap Index Scan), and execution timing.

$$\text{Composite Index Heuristic} = \underbrace{\text{High-Selectivity Predicates}}_{\text{Col1 = 'VAL'}} \longrightarrow \underbrace{\text{Range / Inequality}}_{\text{Col2 > 100}} \longrightarrow \underbrace{\text{Sort Ordering}}_{\text{ORDER BY Col3}} \longrightarrow \underbrace{\text{Low-Churn Covering}}_{\text{INCLUDE (Col4)}}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Prevent Production Latency Spikes**: Eliminate full sequential table scans (Seq Scans) on multi-million row tables that saturate CPU and exhaust database I/O bandwidth.
2.  **Eliminate the N+1 Query Antipattern**: Ensure application services and ORM layers batch-fetch relational collections in a single roundtrip rather than executing hundreds of sequential queries inside loops.
3.  **Optimize Disk & Memory Footprint**: Maximize the effectiveness of shared buffer cache memory through compact partial indexes and covering indexes rather than bloated redundant indexes.
4.  **Balance Read and Write Throughput**: Prevent excessive indexing that degrades high-frequency transactional insert/update throughput.

---

## 3. Why It Matters

Databases scale reads and writes very differently:
*   **The Cliff of Sequential Scans**: A query running fine in development against 1,000 rows executes in 2 milliseconds via sequential scan. In production with 5,000,000 rows, that identical unindexed query takes 15 seconds, locking memory buffers, spiking CPU to 100%, and causing cascading connection pool exhaustion across all backend APIs.
*   **The Composite Index Order Trap**: Creating an index on `(created_at, status, user_id)` when the query is `WHERE user_id = '123' AND status = 'PENDING' ORDER BY created_at` is almost completely ineffective because the range/sort column (`created_at`) was placed before the high-selectivity equality filters.
*   **The N+1 Catastrophe**: Iterating through 50 orders in TypeScript or Java and invoking `order.getItems()` inside the loop issues 51 separate database queries over the network. Under load, network roundtrip latency dominates, dragging response times from 15ms to 800ms.
*   **Write Degradation**: A table with 15 indexes must perform 15 separate leaf-node writes and disk updates for every single inserted row.

---

## 4. When to Use It

Engineers `MUST` enforce these indexing standards:
*   On every column combination evaluated in frequent or performance-critical `WHERE`, `JOIN`, and `ORDER BY` clauses.
*   When optimizing slow queries identified by database telemetry (`pg_stat_statements`) or APM traces exceeding the 100ms threshold.
*   When fetching parent-child relationships across ORM boundaries (enforcing eager join or batch loading).
*   When indexing nullable soft-deleted columns (using Partial Indexes).

---

## 5. When NOT to Use It

Engineers `SHOULD NOT` add indexes in these scenarios:
*   **Low-Cardinality Columns Alone**: Indexing a boolean column (e.g. `is_active`) on a 1,000,000-row table where 95% of rows are `TRUE` is completely ignored by the query planner because a sequential scan is cheaper than index scan + table heap lookups. Use a **Partial Index** instead (`CREATE INDEX ... WHERE is_active = FALSE`).
*   **Blindly Indexing Every Foreign Key**: Do NOT mindlessly create indexes on every single foreign key column without analyzing access patterns. Foreign keys that are rarely joined or deleted (e.g. static configuration parent references) add pure write overhead for zero read benefit.
*   **Tiny Static Lookup Tables**: Tables with fewer than 500 rows (e.g. `countries`, `roles`) fit inside a single 8KB disk page. The planner will always perform a sequential scan faster than traversing an index tree.

---

## 6. Advantages & Disadvantages

| Indexing Technique | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **B-Tree Composite Index** | Drastically accelerates multi-column equality and range filters in a single traversal. | Inflexible column order; satisfies queries matching left prefixes only; write penalty on mutations. |
| **Partial Index (`WHERE ...`)** | Extremely small disk footprint; fits entirely in RAM; zero write overhead for untargeted rows. | Only accelerates queries containing identical matching `WHERE` filter predicates. |
| **Covering Index (`INCLUDE`)** | Enables Index-Only Scans without reading the underlying heap table pages. | Slightly larger index page size; additional memory consumption in database shared buffers. |
| **GIN Index (Generalized Inverted)** | Enables fast searching inside JSONB documents, arrays, and full-text search vectors. | Significantly heavier write and maintenance cost than B-Trees; larger disk footprint. |

---

## 7. Practical Examples

### Bad Practice: Inverted Composite Order, Unindexed Subqueries, and the N+1 Loop

```sql
-- BAD: Composite index with inverted column ordering
-- Query: SELECT * FROM orders WHERE account_id = '123' AND status = 'CONFIRMED' ORDER BY created_at DESC;
-- HAZARD: Placing created_at first forces range scan before equality filters can be applied!
CREATE INDEX idx_orders_bad ON orders (created_at, status, account_id);
```

```typescript
// BAD: Classical N+1 query loop in application code
export async function getAccountOrdersWithItems(accountId: string) {
  // Query 1: Fetch all orders for account
  const orders = await db.query('SELECT * FROM orders WHERE account_id = $1', [accountId]);

  const results = [];
  // HAZARD: Loop fires N additional roundtrips over the network!
  for (const order of orders.rows) {
    const items = await db.query('SELECT * FROM order_items WHERE order_id = $1', [order.id]);
    results.push({ ...order, items: items.rows });
  }
  return results;
}
```

### Good Practice: Left-to-Right Index Ordering, Partial Indexes, and Batched Fetching

```sql
-- GOOD: Left-to-Right composite index following Equality -> Range/Sort -> Covering
-- Query: SELECT id, total_amount_cents FROM orders WHERE account_id = '123' AND status = 'CONFIRMED' ORDER BY created_at DESC;

CREATE INDEX idx_orders_account_status_created ON orders (
    account_id,         -- 1. Equality filter column
    status,             -- 2. Equality filter column
    created_at DESC     -- 3. Sort ordering column
) INCLUDE (total_amount_cents); -- 4. Covering column (Enables Index-Only Scan!)

-- GOOD: Partial index for soft-deleted table (Zero index bloat for deleted rows)
CREATE INDEX idx_accounts_active_email ON accounts (email) 
WHERE is_active = TRUE;

-- GOOD: GIN Index for fast JSONB querying inside customer attributes
CREATE INDEX idx_accounts_metadata_gin ON accounts USING GIN (metadata jsonb_path_ops);
```

```typescript
// GOOD: Eliminating N+1 using a single batch query with SQL IN / ANY operator
export async function getAccountOrdersWithItemsOptimized(accountId: string) {
  // Query 1: Fetch orders
  const orders = await db.query(
    'SELECT id, account_id, status, total_amount_cents, created_at FROM orders WHERE account_id = $1',
    [accountId]
  );
  if (orders.rows.length === 0) return [];

  const orderIds = orders.rows.map(o => o.id);

  // Query 2: Fetch ALL items for ALL retrieved orders in a SINGLE network roundtrip
  const items = await db.query(
    'SELECT id, order_id, item_sku, quantity, unit_price_cents FROM order_items WHERE order_id = ANY($1)',
    [orderIds]
  );

  // Group items by order_id in memory (sub-millisecond CPU cost)
  const itemsByOrderId = new Map<string, any[]>();
  for (const item of items.rows) {
    if (!itemsByOrderId.has(item.order_id)) {
      itemsByOrderId.set(item.order_id, []);
    }
    itemsByOrderId.get(item.order_id)!.push(item);
  }

  return orders.rows.map(order => ({
    ...order,
    items: itemsByOrderId.get(order.id) || [],
  }));
}
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: Misordering Columns in Composite Indexes (The Prefix Fallacy)
*   **The Trap**: Placing sort or range columns (`created_at`) before high-selectivity equality columns (`account_id`, `status`) in a composite index definition.
*   **The Consequence**: The B-Tree index traversal cannot perform a direct binary tree seek on the equality columns; it must perform an expensive range scan across all dates, discarding non-matching rows.
*   **Mitigation**: Always follow the strict **Left-to-Right Ordering Rule**: Place equality columns (`=`) first, followed by range/inequality columns (`<`, `>`, `BETWEEN`), followed by `ORDER BY` columns.

### Trap 2: Wrapping Indexed Columns in SQL Functions
*   **The Trap**: Writing queries like `WHERE LOWER(email) = 'user@example.com'` or `WHERE DATE(created_at) = '2026-11-03'` when standard B-Tree indexes exist on `email` or `created_at`.
*   **The Consequence**: Standard B-Tree indexes store raw column values, not function results. Applying an unindexed function forces the database engine to perform a full sequential scan across every row in the table.
*   **Mitigation**: Write queries against raw column bounds (`WHERE created_at >= '2026-11-03 00:00:00Z' AND created_at < '2026-11-04 00:00:00Z'`) or create an explicit **Expression Index** (`CREATE INDEX idx_email_lower ON users (LOWER(email))`).

### Trap 3: The N+1 Query Loop in ORMs and Microservices
*   **The Trap**: Iterating through an array of entities in application code and executing an individual child query per iteration.
*   **The Consequence**: Latency scales linearly with $N$ ($N \times \text{network roundtrip}$). With 100 records, a 2ms database query becomes a 250ms blocking network bottleneck.
*   **Mitigation**: Engineers `MUST` use explicit eager joins (`LEFT JOIN`), batched `ANY($1)` / `IN (...)` queries, or dataloaders to fetch relational collections in a fixed number of roundtrips ($O(1)$).

---

## 9. Verification Checklist

- [ ] **Empirical Verification (`EXPLAIN ANALYZE`)**: Critical and high-frequency queries have been verified with `EXPLAIN (ANALYZE, BUFFERS)`; zero unhedged sequential scans exist on large tables.
- [ ] **Composite Prefix Ordering**: Multi-column indexes place Equality columns first, followed by Range columns, followed by Sort columns.
- [ ] **Partial Indexes on Flag Columns**: Low-cardinality status or soft-delete columns (e.g. `is_active`, `deleted_at`) use partial indexes rather than full-table indexes.
- [ ] **Zero N+1 Query Loops**: Parent-child relationships are retrieved via single joins or batched `ANY(...)` lookups; zero individual database queries are fired inside loops.
- [ ] **No Function Wrapping**: Search predicates avoid wrapping indexed columns in functions unless explicit expression indexes are configured.
- [ ] **Covering Index Optimization & HOT Trade-Off**: High-frequency read queries utilize `INCLUDE` columns only for low-churn data where Index-Only Scans justify the additional leaf page bloat and loss of Heap-Only Tuple (HOT) update optimization.
