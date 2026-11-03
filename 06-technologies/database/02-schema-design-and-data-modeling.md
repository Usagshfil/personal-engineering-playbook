# Schema Design and Data Modeling Standards

> **Level 2 Technology Standard — Database & Persistence**  
> **Applicability**: Mandatory for all relational database schemas, migrations, and ORM entity models. Adheres to [Universal Core Standards](../../01-principles/README.md) and [Database Architecture Standards](../../03-architecture/11-database-integration.md).

---

## 1. Definition & Core Concept

**Relational Schema Design and Data Modeling** is the systematic discipline of structuring database tables, columns, data types, and declarative integrity constraints to accurately represent domain entities, ensure data consistency at rest, and eliminate redundancy through normalization.

Core modeling invariants include:
*   **Third Normal Form (3NF) Baseline**: Every non-key attribute must depend on the key, the whole key, and nothing but the key.
*   **Declarative Constraint Enforcement**: Business invariants (e.g. non-negative balances, valid email formats, immutable states) `MUST` be enforced directly inside the database via `CHECK`, `NOT NULL`, `UNIQUE`, and `FOREIGN KEY` constraints, providing a durable defense-in-depth barrier behind application-level validation.
*   **Monetary & Financial Representation (F17)**: Using floating-point types (`FLOAT`/`REAL`/`DOUBLE`) for currency is strictly prohibited. Financial representation `MUST` follow one of two verified patterns:
    *   **Integer Minor Units Pattern**: Store amounts as an integer (`BIGINT`) in the currency's minor units (e.g. cents for USD/EUR), accompanied by an ISO 4217 currency code and explicit scale factor. Note that "cents" is not universal: JPY has 0 minor units ($1\text{ JPY} = 1\text{ unit}$), BHD/KWD use 3 decimal places ($1\text{ KWD} = 1000\text{ fils}$), and cryptocurrencies require 8–18 units.
    *   **Arbitrary-Precision Decimals (`NUMERIC(p,s)`)**: When dealing with fractional shares, foreign exchange rates, tax percentages, or sub-cent precision, use `NUMERIC(p, s)`.
    *   **Rounding Rules**: Rounding is a business rule, not a database type choice. Systems `MUST` standardize on Banker's Rounding (Half-Even: `ROUND_HALF_EVEN`) to eliminate statistical bias, and enforce it consistently across application services and database queries.
*   **Timestamp & Timezone Semantics (F18)**: PostgreSQL `TIMESTAMPTZ` stores an absolute point in time (an instant) internally normalized to UTC; it does *not* preserve the client's original timezone name or offset. Systems `MUST` distinguish between:
    *   **Events and Audit Timestamps**: System events, created/updated timestamps, audit ledgers, and transaction commits `MUST` use `TIMESTAMPTZ`.
    *   **Calendar Concepts & Scheduled Appointments**: Future real-world local events (e.g., flight departure at 09:00 local time, recurring doctor appointment) `MUST` be stored as a local wall-clock timestamp (`TIMESTAMP WITHOUT TIME ZONE` or `DATE` + `TIME`) alongside an explicit **IANA Timezone Identifier** (e.g., `America/New_York`, `Asia/Ho_Chi_Minh`, `Europe/London`). This ensures the scheduled appointment remains intact even if governments alter Daylight Saving Time (DST) transition dates.
    *   **Presentation & Display**: Timezone formatting is a presentation concern; convert UTC instants to the user's localized timezone at the presentation/edge layer.
*   **Nullable Hygiene**: Columns `MUST` be `NOT NULL` by default. Optionality requires explicit domain justification, preventing confusing 3-valued boolean logic (`TRUE`, `FALSE`, `UNKNOWN/NULL`).

$$\text{Domain Invariant} \xrightarrow[\text{Application Validation}]{\text{Boundary DTO}} \underbrace{\text{Database Engine}}_{\text{ACID Boundary}} \longrightarrow \left[ \begin{array}{l} \text{NOT NULL Constraints} \\ \text{CHECK (total_amount_cents >= 0)} \\ \text{FOREIGN KEY ON DELETE RESTRICT} \\ \text{TIMESTAMPTZ (Instant in UTC)} \\ \text{IANA Timezone for Calendar Events} \end{array} \right]$$

---

## 2. Purpose

The purpose of these standards is to:
1.  **Prevent Silent Data Corruption**: Guarantee that invalid, orphaned, or truncated data can never be committed to persistent disk, even if application-level validation contains bugs or is bypassed by manual scripts.
2.  **Eliminate Floating-Point Inaccuracies**: Ensure exact penny-accurate financial math without catastrophic IEEE 754 rounding drift.
3.  **Prevent Anomalous Null Behavior**: Eliminate SQL three-valued logic traps in `WHERE` clauses, index lookups, and aggregate functions (`COUNT`, `AVG`).
4.  **Standardize Identifiers Across Distributed Systems**: Establish unguessable, time-sortable primary keys (`UUIDv7` or `BIGINT IDENTITY`) that resist enumeration attacks and preserve index locality.

---

## 3. Why It Matters

Application code is transient and evolves rapidly across microservices, cron jobs, and background workers. The database schema is the permanent, durable Single Source of Truth:
*   **The Shared Database Hazard**: Even if your primary API server validates inputs perfectly with Zod or Hibernate Validator, data imports, administrative scripts, or secondary worker services can bypass application validation and insert corrupt records if the database lacks declarative constraints.
*   **The Floating-Point Accounting Disaster**: Storing account balances as `FLOAT4` or `FLOAT8` causes $0.10 + 0.20 = 0.30000000000000004$, leading to compounding rounding errors that fail financial audits and cause reconciliation discrepancies.
*   **Three-Valued Logic Traps**: In ANSI SQL, `NULL = NULL` evaluates to `UNKNOWN` (falsy), not `TRUE`. Queries like `SELECT * FROM users WHERE is_active != TRUE` silently omit users where `is_active IS NULL`, producing phantom bugs in production reports.
*   **Orphaned Child Records**: Omitting `FOREIGN KEY` constraints allows child rows (e.g. order line items) to reference non-existent parent records (orders), resulting in broken joins and unhandled application null pointers.

---

## 4. When to Use It

Engineers `MUST` enforce these schema design standards:
*   When creating new relational tables or modifying existing schemas across PostgreSQL, SQLite, or MySQL.
*   When mapping application domain entities and value objects to persistent database tables.
*   When defining financial, transactional, identity, or auditing records requiring auditability and mathematical precision.
*   When selecting primary keys, foreign keys, and column constraints.

---

## 5. When NOT to Use It

Engineers `MAY` depart from strict 3NF normalization only under these controlled conditions:
*   **Pragmatic Denormalization for Read-Heavy OLAP**: Pre-aggregating totals (e.g. `cached_total_cents` on an order table) or denormalizing customer names into an invoice table `MAY` be permitted only when read volume exceeds write volume by orders of magnitude and query latency cannot be resolved via covering indexes. Denormalized fields `MUST` be updated atomically within the same transaction or maintained via database triggers / Materialized Views.
*   **Semi-Structured Polymorphic Metadata (`JSONB`)**: Storing arbitrary third-party webhook payloads or user-defined custom attributes in a `JSONB` column is acceptable, provided core queryable relational entities remain structured in first-class columns.
*   **Append-Only Event Logs**: Event sourcing streams or high-throughput telemetry logs `MAY` omit heavy check constraints to maximize write ingestion throughput, provided immutability is guaranteed.

---

## 6. Advantages & Disadvantages

| Design Choice | Advantages | Disadvantages & Trade-offs |
| :--- | :--- | :--- |
| **Strict Constraints (`CHECK`, `FK`)** | Impossible to persist corrupt data; self-documenting schema; zero orphaned rows. | Minor write latency overhead (<2%) during inserts/updates; requires explicit migration sequencing. |
| **`TIMESTAMPTZ` (UTC Always)** | Eliminates daylight savings bugs, server timezone drift, and international scheduling errors. | Requires explicit timezone conversion when presenting localized dates to end-users. |
| **`NUMERIC` / Integer Cents** | 100% exact math; passes financial and compliance audits; zero IEEE 754 drift. | Requires slightly more storage (variable bytes) and CPU cycles than hardware-native binary floats. |
| **`NOT NULL` by Default** | Predictable two-valued boolean logic; eliminates null-pointer exceptions in application code. | Requires explicit default values or careful schema evolution when adding new columns. |

---

## 7. Practical Examples

### Bad Practice: Primitive Obsession, Missing Constraints, and Dangerous Floats

```sql
-- BAD: Missing constraints, floating-point money, ambiguous timestamps, and null traps
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,                     -- Predictable auto-increment ID vulnerable to enumeration (BOLA)
    customer_id INT,                           -- Missing FOREIGN KEY constraint; can reference non-existent customer
    total_amount FLOAT8,                       -- HAZARD: Floating-point money causes compounding rounding errors!
    status VARCHAR(50),                        -- Unconstrained string; allows 'completed', 'COMPLETED', 'pending_spelt_wrong'
    is_discounted BOOLEAN,                     -- Nullable boolean creates confusing 3-valued logic (TRUE, FALSE, NULL)
    created_at TIMESTAMP                       -- Missing timezone (stored as server-local timestamp; daylight saving hazard)
);
```

### Good Practice: Strict 3NF Schema with Check Constraints, Exact Money, and UUIDv7

```sql
-- GOOD: Production-grade PostgreSQL 16+ schema with strict typing and declarative constraints

-- 1. Custom Domain / Enum for Order Status
CREATE TYPE order_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'SHIPPED',
    'CANCELLED'
);

-- 2. Normalized Accounts Table
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    organization_id UUID NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_accounts_org_email UNIQUE (organization_id, email),
    CONSTRAINT chk_accounts_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 3. Normalized Orders Table with Strict Constraints
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL,
    status order_status NOT NULL DEFAULT 'PENDING',
    
    -- Monetary value stored as exact integer cents or NUMERIC(14, 2)
    total_amount_cents BIGINT NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    
    -- Explicit timezone-aware UTC timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Declarative Invariants
    CONSTRAINT fk_orders_account FOREIGN KEY (account_id) 
        REFERENCES accounts (id) ON DELETE RESTRICT,
    CONSTRAINT chk_orders_amount_positive CHECK (total_amount_cents >= 0),
    CONSTRAINT chk_orders_currency_iso CHECK (currency ~ '^[A-Z]{3}$')
);

-- 4. Normalized Line Items Table
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    item_sku TEXT NOT NULL,
    quantity INT NOT NULL,
    unit_price_cents BIGINT NOT NULL,
    
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) 
        REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT chk_order_items_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price_non_negative CHECK (unit_price_cents >= 0),
    CONSTRAINT uq_order_items_order_sku UNIQUE (order_id, item_sku)
);
```

---

## 8. Common Mistakes & Pitfalls

### Trap 1: Using `FLOAT` or `DOUBLE PRECISION` for Monetary Data
*   **The Trap**: Declaring price, tax, or balance columns as `FLOAT`, `REAL`, or `DOUBLE PRECISION`, or assuming all currencies have 2 decimal minor units ("cents").
*   **The Consequence**: Binary floating-point representation cannot exactly represent base-10 fractions (such as $0.10$ or $0.05$). Cumulative arithmetic across thousands of transactions results in balance discrepancies and accounting failure. Furthermore, hardcoding a divide-by-100 logic corrupts currencies like JPY (zero minor units) or KWD (three decimal places).
*   **Mitigation**: Engineers `MUST` store monetary values as **exact integer minor units** (`BIGINT`) with currency code and scale, or **arbitrary-precision decimals** (`NUMERIC(p, s)`). Enforce Banker's Rounding (Half-Even) across the business domain.

### Trap 2: Relying Solely on Application-Level Validation Without Database Constraints
*   **The Trap**: Validating that an email is unique or a balance is non-negative exclusively inside TypeScript/Java code, leaving the database table with no `UNIQUE` or `CHECK` constraints.
*   **The Consequence**: Race conditions under concurrent requests allow duplicate emails to be created simultaneously. Background workers or manual maintenance scripts inadvertently write invalid data directly into the table.
*   **Mitigation**: Database tables `MUST` define declarative constraints (`CHECK`, `UNIQUE`, `FOREIGN KEY`) as an unbypassable layer of defense.

### Trap 3: Nullable Booleans and the Three-Valued Logic Trap
*   **The Trap**: Creating a column like `is_verified BOOLEAN` without a `NOT NULL DEFAULT FALSE` constraint.
*   **The Consequence**: SQL recognizes three truth values: `TRUE`, `FALSE`, and `UNKNOWN` (represented by `NULL`). Queries evaluating `WHERE is_verified = FALSE` will NOT match rows where `is_verified` is `NULL`, producing subtle, critical bugs in access control or user notifications.
*   **Mitigation**: All boolean columns `MUST` be declared `NOT NULL DEFAULT FALSE` (or `TRUE`), unless `NULL` represents a strictly defined third business state (in which case a descriptive `ENUM` or `VARCHAR` is far clearer).

---

## 9. Verification Checklist

- [ ] **Strict Normalization**: The schema satisfies 3NF; non-key attributes depend strictly on the primary key without transitive redundancies.
- [ ] **Exact Monetary Types**: All currency and financial balance columns use `NUMERIC(p,s)` or `BIGINT` minor units with ISO currency codes and explicit scale. Zero floating-point types (`FLOAT`, `REAL`, `DOUBLE`) exist. Banker's Rounding (Half-Even) is enforced.
- [ ] **Semantic Timestamps**: System events and audit timestamps are declared as `TIMESTAMPTZ` (UTC instants); local calendar concepts and appointments store wall-clock time plus explicit IANA timezone strings.
- [ ] **Defensive Constraints**: Tables define declarative `NOT NULL`, `CHECK`, and `UNIQUE` constraints enforcing core domain invariants.
- [ ] **Explicit Foreign Keys**: All relational foreign keys specify an explicit `ON DELETE` rule (`RESTRICT`, `CASCADE`, or `SET NULL`).
- [ ] **Nullable Discipline**: Columns are `NOT NULL` by default. Boolean columns are never nullable without documented enum justifications.
