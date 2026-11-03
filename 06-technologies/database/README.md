# Tier 2: Database & Persistence Engineering Standards

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Status**: Active (Priority 4)  
> **Target Engine**: PostgreSQL 16+ (Primary RDBMS), SQLite 3.45+ (Embedded/Mobile), Redis 7+ (Cache/Transient)  
> **Last Verified**: 2026-11-03

---

## 1. Overview & Architectural Placement

This directory defines the **Tier 2 Database & Persistence Engineering Standards** of the Personal Software Engineering Playbook. It translates the timeless principles of Tier 1 (Universal Core) into concrete, idiomatic conventions for relational database schema design, index optimization, zero-downtime schema migrations, ACID transactions, connection pooling, and data disaster recovery.

When designing schemas, writing queries, or executing migrations under this playbook, AI coding agents and human developers must adhere to the **4-Level Instruction Hierarchy**:

$$\text{Tier 3: Project Overlay} \succ \text{Tier 2: Database Standard} \succ \text{Tier 1: Universal Core}$$

> [!CAUTION]
> **The Invariant Safety Gate**: Tier 2 Database conventions can **NEVER** override Tier 1 Universal Safety, Security, or Verification Integrity rules. No database convention may authorize hardcoding database passwords, executing non-reversible unhedged DDL in production, disabling foreign key constraints without explicit architectural approval, storing unencrypted sensitive PII, or claiming zero downtime without automated expand-and-contract migration testing.

---

## 2. Technology Version Governance & Lifecycle Policy

To eliminate database drift and guarantee operational reliability across multi-year production lifecycles, database systems adhere to this version policy:

### Database Version Governance Matrix

| Persistence Engine | Minimum Supported | Recommended Baseline | Code Example Version | EOL & Deprecation Handling | Verification Date | Upgrade & Migration Cadence |
| :--- | :---: | :---: | :---: | :--- | :---: | :--- |
| **PostgreSQL (OLTP)** | `14.0` | **`16.x`** | `16.4` | Upstream PostgreSQL 5-year support cycle. Major versions upgraded $\ge 6$ months before EOL. | 2026-11-03 | Annual planned major upgrade using `pg_upgrade` or logical replication blue-green cutover. |
| **SQLite (Embedded/Mobile)** | `3.39.0` | **`3.45+`** | `3.45.3` | WAL mode mandated. Strict foreign keys (`PRAGMA foreign_keys = ON`) enabled on every connection. | 2026-11-03 | Upgraded with Android/iOS SDK framework baseline cycles. |
| **Redis (Cache/Transient)** | `6.2` | **`7.2+`** | `7.2.4` | Used strictly for ephemeral cache, distributed rate limiting, and temporary locks; never as primary datastore. | 2026-11-03 | Bi-annual audit; Redis Sentinel or Cluster for high availability. |
| **PgBouncer (Pooler)** | `1.18.0` | **`1.22+`** | `1.22.1` | Transaction pooling mode (`pool_mode = transaction`) standard. | 2026-11-03 | Tracked with PostgreSQL infrastructure lifecycle. |
| **Migration Tooling** | — | **Flyway / Liquibase / Goose** | Flyway 10+ | Strict version-controlled, repeatable, forward-only or expand-contract migration scripts. | 2026-11-03 | CI verification on every pull request against clean ephemeral DB. |

---

## 3. Database Selection Guide: RDBMS vs. NoSQL

Do not choose a database based on hype. Default to **PostgreSQL** unless the access patterns and data volume empirically demand a specialized store:

| Engine Category | Primary Candidates | Optimal Workloads & Access Patterns | Anti-Patterns (When NOT to Use) |
| :--- | :--- | :--- | :--- |
| **Relational (RDBMS)** | **PostgreSQL** *(Default)* | Structured transactional data, complex relationships, strict ACID consistency, reporting with joins, JSONB semi-structured documents. | Unbounded append-only time-series data at $>100\text{k ops/sec}$, unstructured multi-terabyte blobs. |
| **Embedded Relational** | **SQLite** | Mobile apps (Room/CoreData), desktop software, local developer environments, edge IoT devices, read-heavy low-concurrency caches. | Multi-server distributed architectures, high-concurrency write workloads. |
| **In-Memory Key-Value** | **Redis / Valkey** | Sub-millisecond session storage, rate limiting counters, distributed locks, pub/sub messaging, transient read caching. | Primary system of record requiring durable multi-table ACID transactions and complex query filters. |
| **Document Store** | MongoDB, DynamoDB | Rapidly evolving polymorphic documents without relational joins, massive single-key key-value lookups partitioned across shards. | Relational business domains (banking, e-commerce orders/inventory), financial auditing requiring atomic cross-document invariants. |
| **Time-Series Engine** | TimescaleDB, ClickHouse | High-frequency telemetry metrics, IoT sensor streams, append-only audit event logs, analytical aggregations (OLAP). | Transactional OLTP workloads requiring frequent updates, row-level deletions, and transactional foreign keys. |

> [!IMPORTANT]
> **The Architecture Rule of Default**: Always start with **PostgreSQL**. PostgreSQL’s advanced capabilities (`JSONB`, partial indexes, full-text search, generated columns, and extensions like `pgvector` and `TimescaleDB`) fulfill 95% of production system requirements without introducing multi-database synchronization overhead.

---

## 4. Recommendation Strength Taxonomy (RFC 2119)

Guidelines in this directory adhere to standard normative keywords:

*   **MUST**: Mandatory requirement for data integrity, security, or crash recovery (e.g. `TIMESTAMPTZ` for timestamps, `NUMERIC` for monetary values, `NOT NULL` by default, transactional migration scripts, automated restoration tests).
*   **SHOULD**: Strong default recommendation for production reliability (e.g. Expand-and-Contract migration pattern, composite index prefix ordering, connection pool sizing limits, partial indexes for soft-deleted rows).
*   **MAY**: Optional optimization technique appropriate for specialized high-throughput tables (e.g. table partitioning by range, covering indexes with `INCLUDE`, hash indexes, unlogged staging tables).
*   **AVOID**: Prohibited anti-pattern that causes data corruption, downtime, or performance collapse (e.g. `FLOAT` for money, missing `WHERE` clauses on bulk updates, long-running transactions holding table locks, querying in tight application loops creating N+1 queries).

---

## 5. Tier 1 to Tier 2 Database Mapping & Classification Matrix

| Database Standard Guide | Core Pattern | Mapped Tier 1 Rule | Classification |
| :--- | :--- | :--- | :--- |
| **01. Governance & Selection** | RDBMS Primacy (PostgreSQL 16+) | Architecture 01 (Principles) & Arch 11 (Database) | **Specializes Universal Pattern** |
| **01. Governance & Selection** | Anti-Sprawl & N-1 Version Lifecycle | Lifecycle 04 (Design) & Security 04 (Supply Chain) | **Implements Tier 1 Invariant** |
| **02. Schema Design** | 3NF Normalization & Constraint Guards | Principle 01 (Clean Code) & Principle 03 (Modularity) | **Implements Tier 1 Invariant** |
| **02. Schema Design** | Explicit Monetary Types (`NUMERIC`, Banning `FLOAT`) | Principle 04 (Fail-Fast) & Security 03 (Sanitization) | **Implements Tier 1 Invariant** |
| **02. Schema Design** | Primary Key Strategy (`UUIDv7` vs `BIGINT IDENTITY`) | Architecture 10 (APIs) & Security 02 (Auth) | **Technology-Specific Realization** |
| **03. Indexing & Tuning** | Composite Index Left-to-Right Ordering Rule | Principle 02 (Simplicity) & Principle 08 (Performance) | **Specializes Universal Pattern** |
| **03. Indexing & Tuning** | Execution Plan Verification (`EXPLAIN ANALYZE`) | Principle 05 (Verification Integrity) | **Implements Tier 1 Invariant** |
| **03. Indexing & Tuning** | Foreign Key Indexing Heuristics | Principle 08 (Simplicity) & Architecture 11 | **Context-Dependent Recommendation** |
| **04. Safe Migrations** | Expand-and-Contract Non-Breaking Changes | Lifecycle 08 (Deployment) & Principle 06 (Resilience) | **Specializes Universal Pattern** |
| **04. Safe Migrations** | Explicit Lock Timeouts (`lock_timeout = '2s'`) | Principle 06 (Resilience) & Lifecycle 08 | **Implements Tier 1 Invariant** |
| **04. Safe Migrations** | Non-Blocking DDL (`CREATE INDEX CONCURRENTLY`) | Principle 06 (Resilience) & Lifecycle 08 | **Technology-Specific Realization** |
| **05. Transactions** | ACID Guarantees & MVCC Isolation Levels | Architecture 02 (Clean Arch) & Principle 04 | **Specializes Universal Pattern** |
| **05. Transactions** | Optimistic Locking vs Pessimistic `FOR UPDATE` | Architecture 09 (State) & Principle 06 | **Specializes Universal Pattern** |
| **05. Transactions** | Durable Deduplication Foundation for Idempotency | Principle 04 (Fail-Fast) & Architecture 10 (APIs) | **Specializes Universal Pattern** |
| **06. Connection Pooling** | Hardware-Derived Pool Sizing Formula | Principle 08 (Simplicity) & Principle 06 | **Context-Dependent Recommendation** |
| **06. Connection Pooling** | PgBouncer Transaction Mode & Saturation Shedding | Principle 06 (Resilience) & Lifecycle 08 | **Technology-Specific Realization** |
| **07. Security & Recovery** | Principle of Least Privilege Database Roles | Security 01 (Secrets) & Security 02 (Auth) | **Implements Tier 1 Invariant** |
| **07. Security & Recovery** | Point-in-Time Recovery (PITR) & WAL Archiving | Security 05 (Privacy) & Lifecycle 08 (Ops) | **Implements Tier 1 Invariant** |
| **07. Security & Recovery** | Mandatory Automated Restoration Drill Verification | Principle 05 (Verification Integrity) | **Implements Tier 1 Invariant** |

---

## 6. Technology Standards Catalog

The Database & Persistence standard is structured into 7 comprehensive guides, each adhering strictly to the **9-Part Pedagogical Schema**:

| # | Standard Guide | Core Focus Areas |
| :---: | :--- | :--- |
| **01** | [`01-database-governance-and-technology-selection.md`](01-database-governance-and-technology-selection.md) | Relational vs NoSQL taxonomy, PostgreSQL 16+ baseline, operational ownership, version lifecycle policy, anti-sprawl governance. |
| **02** | [`02-schema-design-and-data-modeling.md`](02-schema-design-and-data-modeling.md) | 3NF normalization, pragmatic denormalization heuristics, strict types (`NUMERIC`, `TIMESTAMPTZ`), check/foreign key constraints, nullable hygiene. |
| **03** | [`03-indexing-strategies-and-query-tuning.md`](03-indexing-strategies-and-query-tuning.md) | B-Tree index mechanics, composite index ordering, partial/covering/GIN indexes, `EXPLAIN (ANALYZE, BUFFERS)` execution plans, eliminating N+1 queries. |
| **04** | [`04-safe-schema-migrations.md`](04-safe-schema-migrations.md) | Expand-and-contract pattern, zero-downtime conditional realism, `lock_timeout` protection, non-blocking DDL (`CONCURRENTLY`), batch backfills. |
| **05** | [`05-transactions-and-concurrency.md`](05-transactions-and-concurrency.md) | ACID properties, PostgreSQL MVCC, isolation levels (Read Committed to Serializable), concurrency anomalies, optimistic vs pessimistic locking. |
| **06** | [`06-connection-pooling-and-resilience.md`](06-connection-pooling-and-resilience.md) | Connection pool sizing physics, client (HikariCP) vs server (PgBouncer) pooling, saturation management, timeout budgets, lightweight health probes. |
| **07** | [`07-data-security-backup-and-recovery.md`](07-data-security-backup-and-recovery.md) | Least privilege database roles, encryption at rest/transit/column, Row-Level Security (RLS), PITR continuous WAL archiving, restoration verification. |

---

## 7. Concrete Reference Implementation

A self-contained PostgreSQL reference implementation demonstrating these standards in practice is located in:
*   [`examples/representative-schema-and-migration.sql`](examples/representative-schema-and-migration.sql) — Production-grade SQL implementation demonstrating role separation, 3NF tables with strict constraints, indexes, safe expand-and-contract migration with batch backfilling, optimistic concurrency queries, and rollback testing.
