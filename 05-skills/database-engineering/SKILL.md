---
name: database-engineering
description: Design relational databases, entities, relationships, foreign keys, indexes, 3NF normalization, and non-destructive migrations. Use when creating or modifying persistent data models, schemas, or data access objects.
license: MIT
compatibility: Universal (any OS or programming environment)
metadata:
  category: data-engineering
  version: "1.0.0"
  playbook-level: "4"
---

# Database Engineering Skill

## 1. Overview & Capability
The **Database Engineering Skill** guides the systematic design, normalization, query optimization, and migration of relational databases. It defines a repeatable, platform-independent engineering procedure ensuring data integrity, optimized indexing, and zero-loss schema migrations across application updates.

Platform-specific syntax (e.g. Android Room, PostgreSQL DDL, Prisma) is delegated to **Technology Standards ([`06-technologies/README.md`](../../06-technologies/README.md))**.

---

## 2. When to Use & When NOT to Use

### When to Use
*   Designing a new relational database schema or adding persistent entities.
*   Authoring or refactoring Data Access Objects (DAOs) and schema definitions.
*   Authoring and verifying versioned, non-destructive database migrations.
*   Optimizing slow queries via indexing and execution plan analysis.

### When NOT to Use
*   Managing transient in-memory state in a presentation controller (use `coding-and-implementation`).
*   Storing simple key-value settings (use Jetpack DataStore, localStorage, or Redis).
*   Writing network HTTP DTOs (use `coding-and-implementation`).

---

## 3. Required Inputs & Prerequisites
*   Domain entities and business rules from `requirement-engineering`.
*   System Architecture Document (SAD) from `system-architecture`.
*   Active technology standard reference ([`06-technologies/README.md`](../../06-technologies/README.md); consult official platform documentation per the interim fallback protocol).

---

## 4. Step-by-Step Deterministic Workflow

```
1. Entity-Relationship Modeling ──> 2. Normalization (3NF) ──> 3. Index & Performance Planning ──> 4. Schema & DAO Authoring ──> 5. Migration & Verification
```

### Step 1: Entity-Relationship (ER) Modeling
1.  Identify core real-world entities (e.g. `User`, `Order`, `OrderItem`).
2.  Assign unambiguous primary keys (e.g. auto-increment integer or UUID string).
3.  Define relationship cardinalities:
    *   **1-to-Many**: Foreign key in child table.
    *   **Many-to-Many**: Associative junction table with composite primary key.
4.  Generate Mermaid ER Diagram.

### Step 2: Schema Normalization (3NF)
1.  **1NF**: Eliminate repeating groups; ensure all column values are atomic.
2.  **2NF**: Ensure all non-key columns depend on the entire primary key.
3.  **3NF**: Ensure no transitive dependencies (non-key columns depend *only* on the primary key).
4.  *Selective Denormalization*: Document explicit justification if introducing denormalized counters to avoid expensive multi-table joins.

### Step 3: Indexing Strategy
1.  Add indexes to all foreign key columns.
2.  Add indexes to columns frequently filtered (`WHERE status = ?`) or sorted (`ORDER BY created_at DESC`).
3.  Avoid over-indexing: each index slows down `INSERT` and `UPDATE` operations.

### Step 4: Schema & Data Access Layer Implementation
Implement the data tier following the active project technology standard:
*   **Android (Room)**: Author `@Entity(tableName = "...", indices = [...])` and `@Dao` interfaces returning reactive `Flow`. Refer to [`06-technologies/README.md`](../../06-technologies/README.md) (Tier 2 Roadmap / official Android Room documentation).
*   **Backend / Relational SQL**: Author versioned SQL DDL or ORM models. Refer to [`06-technologies/README.md`](../../06-technologies/README.md) (Tier 2 Roadmap / official PostgreSQL / SQL standards).
*   *Universal Rule*: Always use parameterized queries (`:param` or prepared statements) to eliminate SQL injection vulnerabilities.

### Step 5: Versioned Migration & Verification Strategy
1.  Increment database schema version ($N \rightarrow N+1$).
2.  Author an explicit, non-destructive migration script (e.g., `ALTER TABLE ... ADD COLUMN ...`).
3.  Write automated migration tests verifying that pre-existing records remain intact without corruption:
    *   *Android*: Use Room `MigrationTestHelper`.
    *   *Backend*: Use Flyway/Liquibase test harness or test containers.

---

## 5. Expected Outputs & Artifact Formats
*   `06-database-design-document.md` (DDD) with Mermaid ERD.
*   Schema definition and DAO/repository files.
*   Automated migration test suite verifying schema transition.

---

## 6. Quality & Verification Checklist
- [ ] Is every entity defined with a distinct primary key?
- [ ] Are all foreign keys indexed to prevent full table scans during joins?
- [ ] Is the schema normalized to 3NF (or denormalization explicitly justified in writing)?
- [ ] Are all queries parameterized to eliminate SQL injection?
- [ ] Is destructive fallback migration strictly forbidden in production release builds?

---

## 7. Common Mistakes & Pitfalls
*   **Destructive Migrations in Production**: Calling destructive fallback migrations that silently wipe user data on update.
*   **Storing Media Files in BLOBs**: Storing large binary blobs directly in database columns instead of saving files to filesystem storage and persisting relative file paths.
*   **Running Synchronous Queries on Main/UI Thread**: Executing blocking queries on the application's primary thread, causing UI freezes.

---

## 8. Real-World Example Walkthrough
**Scenario**: Adding a Category Tagging feature to a Task Tracker.
*   *Entities*: `TaskEntity` (1) $\leftrightarrow$ (Many) `TaskCategoryCrossRef` (Many) $\leftrightarrow$ (1) `CategoryEntity`.
*   *Index*: Composite index on `(task_id, category_id)` to optimize join lookups.
*   *Migration*: Migration from schema v2 to v3 creates the cross-reference table without touching existing `tasks` table data.
*   *Verification*: Test asserts that 100 pre-existing tasks are preserved and queryable after the migration executes.

---

## 9. Related Skills & Hand-Offs
*   $\rightarrow$ Hands off to `coding-and-implementation` to build repositories consuming the data access layer.
*   $\rightarrow$ Hands off to `testing-and-qa` to verify automated migration test suites.

---

## 10. Tool Compatibility & Limitations
*   Antigravity, Cursor, and Claude Code can write schema definitions and SQL migrations reliably.
*   Always inspect existing schemas before authoring new migration SQL.
