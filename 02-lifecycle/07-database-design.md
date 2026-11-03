# Phase 07: Database Design & Data Modeling

---

## 1. Phase Overview
Database Design structures the persistent data tier of the application. It maps real-world entities into relational tables, establishes foreign key relationships, normalizes schemas to eliminate anomalies, plans query indexes for performance, and devises versioned migration strategies.

---

## 2. Inputs
*   Domain Concept Model and Glossary from Phase 02.
*   System Architecture Document (SAD) from Phase 06.
*   Database Standards ([`06-technologies/README.md`](../06-technologies/README.md)).

---

## 3. Activities
1.  **Entity-Relationship (ER) Modeling**: Identify entities, attributes, primary keys, and cardinality (1:1, 1:N, N:M).
2.  **Schema Normalization**: Normalize relations to Third Normal Form (3NF) to eliminate insertion, update, and deletion anomalies.
3.  **Denormalization for Mobile Performance**: Selectively introduce controlled denormalization only where query joins cause proven UI lag.
4.  **Indexing Strategy**: Define indexes for foreign keys and frequently filtered or sorted columns (`WHERE`, `ORDER BY`).
5.  **Room Entity & DAO Drafting**: Draft Kotlin Room `@Entity`, `@Dao`, and `@Database` contracts.
6.  **Migration Strategy Definition**: Plan how schema changes from version 1 to version 2 will be executed without wiping user data (`Migration(1, 2)`).

---

## 4. Expected Outputs
*   Entity Relationship Diagram (ERD).
*   Complete DDL / Room schema definitions.
*   Index plan and query performance considerations.
*   Automated migration test strategy.

---

## 5. Deliverables
*   `06-database-design-document.md` (using template `07-templates/06-database-design-document.md`).
*   Mermaid ER Diagram embedded in documentation.
*   Initial Room Entity & DAO interfaces.

---

## 6. Completion Criteria (Exit Gate)

- [ ] Is every entity defined with a distinct, unambiguous primary key?
- [ ] Are all relationships (foreign keys, cascading actions) explicitly documented?
- [ ] Is the schema normalized to 3NF (with any denormalization justified in writing)?
- [ ] Are query indexes planned for all columns used in search or sort queries?
- [ ] Is a non-destructive database migration strategy in place?
