# Database Governance and Technology Selection Standards

> **Level 2 Technology Standard — Database & Persistence**  
> **Applicability**: Mandatory for all database architecture selections, datastore provisioning, version lifecycle governance, and persistence ownership boundaries. Adheres to [Universal Core Standards](../../01-principles/README.md) and [System Architecture Standards](../../03-architecture/11-database-integration.md).

---

## 1. Definition & Core Concept

**Database Governance and Technology Selection** is the architectural framework governing how datastores are evaluated, selected, standardized, versioned, and maintained across an engineering organization, ensuring that persistent systems meet strict requirements for durability, ACID consistency, operational maintainability, and security.

Core governance tenets include:
*   **The Default RDBMS Primacy Rule**: Engineering teams `MUST` default to **PostgreSQL 16+** for primary transactional (OLTP) workloads unless empirical access patterns, scale requirements ($>100\text{k writes/sec}$), or hardware topologies strictly dictate an alternative.
*   **Anti-Sprawl Governance**: Introducing any datastore outside the approved corporate catalog (PostgreSQL, SQLite, Redis) requires explicit Architectural Review Board (ARB) approval demonstrating that PostgreSQL cannot fulfill the requirement.
*   **Explicit Lifecycle Governance**: Every database engine `MUST` adhere to a documented 6-dimension version policy covering minimum supported versions, recommended production baselines, end-of-support (EOL) migration triggers, and automated verification schedules.
*   **Clear Operational Ownership**: Schema definition, migration scripts, and query performance tuning are owned by **Feature Engineering Teams**; database provisioning, cluster failover, physical storage, and backup infrastructure are owned by **SRE / Platform Teams**.

$$\text{Application Need} \longrightarrow \underbrace{\text{PostgreSQL 16+}}_{\text{Default ACID Store}} \begin{cases} \text{Relational OLTP (Tables)} \\ \text{Semi-Structured (JSONB)} \\ \text{Full-Text Search (tsvector)} \\ \text{Vector Similarity (pgvector)} \end{cases} \xrightarrow[\text{Only When Empirically Justified}]{\text{ARB Exception}} \begin{cases} \text{Redis (Transient Cache)} \\ \text{ClickHouse (Big Data OLAP)} \\ \text{Timescale (Time-Series)} \end{cases}$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Prevent "Polyglot Persistence" Sprawl**: Stop teams from introducing multiple unmanaged database engines (e.g. adding MongoDB, Cassandra, and Neo4j simultaneously) that multiply operational overhead and create fragmented, unsynchronized data silos.
2.  **Eliminate Dual-Write Data Drift**: Prevent distributed data inconsistencies caused by attempting to write the same entity to both an RDBMS and a secondary NoSQL document store without distributed transactions or transactional outboxes.
3.  **Ensure Production Version Currency**: Prevent legacy databases from lingering past upstream vendor End-of-Life (EOL), exposing systems to unpatched security vulnerabilities and engine bugs.
4.  **Standardize Tooling & Observability**: Guarantee uniform query monitoring (`pg_stat_statements`), backup mechanisms (`pgBackRest`), connection pooling (`PgBouncer`), and migration pipelines (`Flyway`) across all microservices.

---

## 3. Why It Matters

Databases are the most difficult component of a software architecture to operate, backup, migrate, and recover:
*   **The Cognitive Load of Polyglot Sprawl**: Operating a database in production requires expertise in replication topologies, memory buffer tuning, WAL management, point-in-time recovery, connection multiplexing, and failover automation. Running five different database technologies across ten teams dilutes organizational expertise and causes catastrophic downtime during incidents.
*   **The Dual-Write Race Condition Trap**: When application code writes to PostgreSQL and then writes to MongoDB or Elasticsearch:
    ```typescript
    // DANGEROUS: Dual-write race condition
    await postgres.orders.create(order);
    await elasticsearch.index(order); // What happens if network drops here?
    ```
    If the second write fails, your search index or document store is permanently out of sync with your system of record.
*   **The Unpatched Engine Vulnerability**: Running PostgreSQL 11 in production three years after upstream EOL means zero security patches for newly discovered memory corruption or remote execution exploits.
*   **PostgreSQL’s Modern Capabilities**: Many developers introduce document stores solely to store flexible JSON, unaware that PostgreSQL’s `JSONB` with GIN indexes frequently outperforms MongoDB for typical transactional access patterns while maintaining full ACID foreign key integrity with surrounding relational data.

---

## 4. When to Use It

Engineers `MUST` enforce this selection and governance standard:
*   When designing new systems, services, or microservices requiring persistent state.
*   When evaluating whether to add a cache, search engine, time-series store, or analytical warehouse.
*   When upgrading database engine major or minor versions in staging and production.
*   When defining cross-team operational ownership, on-call runbooks, and disaster recovery responsibilities.

---

## 5. When NOT to Use It

Engineers `SHOULD NOT` force PostgreSQL when empirical constraints strictly prohibit it:
*   **High-Volume Ingestion Analytics (OLAP)**: Processing billions of analytical event rows per day for aggregate reporting (e.g. clickstreams, ad impressions) is inefficient in transactional row-oriented OLTP databases. Specialized columnar engines (ClickHouse, Snowflake, BigQuery) `SHOULD` be used.
*   **Ephemeral High-Throughput Caching**: Storing high-frequency transient session tokens or rate-limiting counters requiring sub-millisecond in-memory response times `SHOULD` use Redis, not primary relational tables.
*   **Embedded Client Storage**: Client applications (Android, iOS, desktop CLI tools) `MUST` use SQLite rather than attempting to connect remotely to a centralized PostgreSQL cluster.

---

## 6. Advantages & Disadvantages

| Architectural Strategy | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Standardized PostgreSQL Stack** | Deep organizational mastery; single backup/monitoring pipeline; ACID multi-table consistency; rich extension ecosystem (`pgvector`, `JSONB`). | Requires vertical scaling for extreme write volumes ($>50\text{k writes/sec}$); requires careful connection pooling. |
| **Polyglot Persistence Architecture** | Niche optimization for specific data models (e.g. Graph traversal in Neo4j, document sharding in DynamoDB). | Extreme operational complexity; dual-write synchronization failures; fragmented backup procedures; high cloud costs. |
| **Scheduled Version Lifecycle** | Guaranteed security compliance; zero surprise EOL panics; access to modern engine performance optimizations. | Requires planned annual maintenance drills and regression testing of query execution plans. |

---

## 7. Practical Examples

### Bad Practice: Premature Polyglot Persistence Sprawl with Unsynchronized Dual-Writes

```typescript
// BAD: Application-level dual writes between PostgreSQL and MongoDB
// HAZARD 1: Zero atomic transaction boundary across two disparate engines
// HAZARD 2: Doubles infrastructure and operational cost for no empirical gain
import { pgPool } from './postgres';
import { mongoClient } from './mongo';

export async function createCustomerProfile(userId: string, profileData: any) {
  // Write 1: Relational user record
  await pgPool.query('INSERT INTO users (id, email) VALUES ($1, $2)', [userId, profileData.email]);

  // Write 2: Document profile (If this crashes, database state is permanently split and inconsistent!)
  const db = mongoClient.db('profiles');
  await db.collection('user_profiles').insertOne({
    userId,
    preferences: profileData.preferences,
    metadata: profileData.metadata,
  });

  return { status: 'SUCCESS' };
}
```

### Good Practice: Unified PostgreSQL Architecture Combining Relational Invariants and JSONB

```sql
-- GOOD: Unified PostgreSQL 16+ schema combining strict relational integrity with flexible JSONB
-- Eliminates dual-write synchronization failures; backed by a single atomic ACID transaction!

CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY,
    email TEXT NOT NULL,
    organization_id UUID NOT NULL,
    
    -- Semi-structured preferences and metadata stored safely inside JSONB
    preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Exact audit timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Relational Integrity Constraints
    CONSTRAINT fk_user_profiles_org FOREIGN KEY (organization_id)
        REFERENCES organizations (id) ON DELETE RESTRICT,
    CONSTRAINT chk_email_valid CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    
    -- Invariant: Ensure essential JSONB keys exist and match type
    CONSTRAINT chk_preferences_object CHECK (jsonb_typeof(preferences) = 'object')
);

-- Accelerate internal JSONB lookups using a Generalized Inverted Index (GIN)
CREATE INDEX idx_user_profiles_preferences_gin ON user_profiles USING GIN (preferences jsonb_path_ops);
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: Premature Polyglot Persistence (The NoSQL Fad Trap)
*   **The Trap**: Adopting MongoDB or DynamoDB because a feature involves JSON, or adopting a Graph database because entities have relationships.
*   **The Consequence**: The team must now maintain two completely distinct database clusters, two backup strategies, and two monitoring systems. Application code must coordinate dual-writes, inevitably leading to data synchronization bugs that require complex reconciliation scripts.
*   **Mitigation**: **Exhaust PostgreSQL’s native capabilities first.** PostgreSQL supports `JSONB`, recursive CTEs for graph traversal, `tsvector` for full-text search, and `pgvector` for AI embeddings—all protected by ACID transactions.

### Trap 2: Running EOL Database Engines in Production
*   **The Trap**: Leaving a database on PostgreSQL 11 or 12 because "it’s running fine and an upgrade is risky."
*   **The Consequence**: The engine ceases receiving critical security and data-corruption bug patches. Cloud providers eventually force involuntary, uncoordinated upgrades during maintenance windows, breaking application drivers and crashing production unexpectedly.
*   **Mitigation**: Formalize the **N-1 Upstream Policy**: Plan and execute major database upgrades annually, ensuring production engines are never within 6 months of upstream community EOL.

### Trap 3: Blurred Operational Ownership Boundaries
*   **The Trap**: Developers assume SREs optimize slow queries; SREs assume developers manage database backups and failover testing.
*   **The Consequence**: Unindexed queries saturate production databases without developer awareness, and backups are discovered to be failing only when a disaster occurs.
*   **Mitigation**: Clearly delineate ownership: Feature teams own schemas, migrations, indexes, and queries; SRE/Platform teams own provisioning, hardware sizing, automated backups, and cluster high availability.

---

## 9. Verification Checklist

- [ ] **RDBMS Primacy**: PostgreSQL 16+ is the default engine for all transactional workloads; any secondary datastore has formal architectural approval.
- [ ] **Zero Uncoordinated Dual-Writes**: Application code does not execute uncoordinated writes across two separate datastores without a Transactional Outbox or 2PC protocol.
- [ ] **Engine Support Currency**: The database engine version is within active upstream vendor support (PostgreSQL $\ge 14$, recommended $16+$).
- [ ] **Standardized Tooling**: Database migrations use automated version-controlled tools (Flyway, Liquibase, or Goose); ad-hoc manual SQL execution in production is prohibited.
- [ ] **Monitored Query Telemetry**: `pg_stat_statements` is enabled on all database clusters to track slow queries, buffer reads, and execution counts.
- [ ] **Documented Operational Ownership**: Schema evolution and query tuning are explicitly assigned to feature teams; infrastructure and recovery are assigned to SRE/Platform.
