# Tier 2: Backend & API Engineering Standards

> **Tier**: Tier 2 (Technology Standards Layer)  
> **Status**: Active (Priority 3)  
> **Target Version**: Node.js 20+ LTS / Go 1.22+ / Spring Boot 3.3+, OpenAPI 3.1, RFC 9110, RFC 9457  
> **Last Verified**: 2026-11-03

---

## 1. Overview & Architectural Placement

This directory defines the **Tier 2 Backend & API Engineering Standards** of the Personal Software Engineering Playbook. It translates the timeless principles of Tier 1 (Universal Core) into concrete, idiomatic conventions for modern backend services, RESTful APIs, and distributed microservices.

When developing backend services under this playbook, AI coding agents and human developers must adhere to the **4-Level Instruction Hierarchy**:

$$\text{Tier 3: Project Overlay} \succ \text{Tier 2: Backend Standard} \succ \text{Tier 1: Universal Core}$$

> [!CAUTION]
> **The Invariant Safety Gate**: Tier 2 Backend conventions can **NEVER** override Tier 1 Universal Safety, Security, or Verification Integrity rules. No backend convention may authorize hardcoding database credentials or API secrets, disabling input validation or sanitization at system boundaries, logging plain-text passwords or PII, or claiming API compliance without automated test verification.

---

## 2. Technology Version Governance & Support Policy

To eliminate version drift and guarantee long-term operational reproducibility, backend projects adhere to explicit versioning and lifecycle policies. Backend platforms are not interchangeable drop-ins; each ecosystem has distinct operational trade-offs and lifecycle policies.

### Ecosystem Version Governance Matrix

| Ecosystem / Component | Minimum Supported | Recommended Baseline | Code Example Version | EOL & Deprecation Handling | Verification Date | Upgrade & Migration Cadence |
| :--- | :---: | :---: | :---: | :--- | :---: | :--- |
| **Node.js Runtime** | `20.9.0 LTS` | `20.x LTS (Iron)` | `20.18.0 LTS` | Deprecated when upstream LTS reaches EOL; upgrade to next LTS within 6 months. | 2026-11-03 | Bi-annual audit; pin via `.nvmrc` and `engines` field in `package.json`. |
| **Go Runtime** | `1.21.0` | `1.22+` | `1.22.6` | Follows Go upstream policy (supported for 2 latest major releases: $N$ and $N-1$). | 2026-11-03 | Upgraded annually; strict dependency hygiene via `go.mod` and `go.sum`. |
| **Java / Spring Boot** | Java 17 / SB 3.1 | Java 21 / SB 3.3+ | Java 21 / SB 3.3.3 | Non-LTS versions prohibited in production. SB minor releases upgraded every 6 months. | 2026-11-03 | Annual JDK LTS alignment; Spring OpenRewrite for automated migration recipes. |
| **Relational Database** | PostgreSQL 14 | **PostgreSQL 16+** | PostgreSQL 16.4 | Upgraded before upstream EOL (PostgreSQL 5-year support cycle). Minor versions automated. | 2026-11-03 | Major version upgrades planned annually with pg_upgrade / blue-green replication. |
| **API Specification** | `3.0.3` | **OpenAPI 3.1** | `3.1.0` | 3.0.x maintained in maintenance mode; all new endpoints require 3.1 contract-first. | 2026-11-03 | Continuous schema linting via Spectral in CI/CD pipeline. |
| **Error Format** | RFC 7807 | **RFC 9457** | `application/problem+json` | Deprecates bespoke JSON error schemas. Uniform across all service boundaries. | 2026-11-03 | Enforced by API gateway validation filters. |
| **Observability** | OTel 1.20+ | **OTel SDK 1.25+** | OTel SDK 1.25.0 | Upstream OpenTelemetry semantic conventions tracked continuously. | 2026-11-03 | SDK dependencies updated quarterly. |

### Ecosystem Selection & Architectural Fit Guide

Do not choose a backend runtime based on personal habit. Select according to domain characteristics:

*   **Node.js (TypeScript)**:
    *   *Best for*: I/O-heavy APIs, JSON-centric BFF (Backend-For-Frontend) layers, serverless functions, shared data models with web frontends (Next.js/React full-stack).
    *   *Avoid for*: CPU-bound data crunching, heavy cryptographic computing, or complex thread-bound batch processing.
*   **Go**:
    *   *Best for*: High-throughput networking microservices, API gateways, distributed systems infrastructure, telemetry collectors, and containerized utilities requiring sub-second cold starts and minimal memory footprints (<30MB RSS).
    *   *Avoid for*: Complex object-oriented domain models with deep inheritance hierarchies or heavy enterprise workflow orchestration.
*   **Java (Spring Boot / Kotlin)**:
    *   *Best for*: Large enterprise applications with complex domain modeling (DDD), mission-critical transactional consistency, integration with legacy enterprise systems, and massive multithreaded backends leveraging Java 21 Virtual Threads (Loom).
    *   *Avoid for*: Lightweight CLI tools or ultra-low memory serverless deployments.

---

## 3. Recommendation Strength Taxonomy (RFC 2119)

Guidelines in this directory adhere to standard normative keywords:

*   **MUST**: Mandatory requirement for security, data integrity, or correctness (e.g. strict boundary input validation, parameter sanitization, short-lived JWT access tokens, zero secrets in source code, RFC 9110 status code semantics).
*   **SHOULD**: Strong default recommendation for production backend systems (e.g. OpenAPI 3.1 contract-first documentation, RFC 9457 Problem Details error formats, OpenTelemetry structured JSON logging). Documented exceptions require architectural approval.
*   **MAY**: Optional technique or design pattern appropriate for complex enterprise systems (e.g. Event-Driven Architecture, Outbox Pattern, Cursor-based pagination for massive data tables).
*   **AVOID**: Prohibited anti-pattern that introduces security vulnerabilities, data corruption, or operational outages (e.g. Mass Assignment vulnerabilities, unhedged retry storms, monolithic God Services, unindexed database scans).

---

## 4. Scale & Complexity Selection Guide: Modular Monolith vs. Microservices

Selecting a microservices architecture prematurely is among the most catastrophic engineering blunders. Adhere to this architectural fit matrix:

| Dimension | Default Recommendation: **Modular Monolith** | Advanced Scale: **Microservices** |
| :--- | :--- | :--- |
| **Team Size** | 1 to 20 engineers working on unified domain. | Multiple autonomous, cross-functional teams (>30 engineers). |
| **Deployment Cadence** | Single unified CI/CD deployment pipeline. | Services require independent, continuous deployment cadences. |
| **Data Boundaries** | Single database with strictly bounded module schemas. | Independent, strictly isolated databases per service. |
| **Transaction Model** | Simple, reliable in-process ACID transactions. | Complex distributed transactions (Saga pattern, eventual consistency). |
| **Network Overhead** | In-memory function invocations (zero latency/network failure). | RPC/HTTP network latency, serialization cost, network partitions. |
| **Operational Cost** | Simple container orchestration; single log/metric stream. | Service mesh, distributed tracing, complex observability infrastructure. |

> [!IMPORTANT]
> **The Architecture Rule of Default**: Always start with a well-structured **Modular Monolith** with clear internal module boundaries. Decompose into independent microservices ONLY when distinct scalability bottlenecks, team ownership boundaries, or isolated deployment cadences empirically demand it.

---

## 5. Tier 1 to Tier 2 Backend Mapping & Classification Matrix

The following matrix categorizes all backend guidance into explicit architectural tiers to distinguish non-negotiable universal invariants from technology-specific realizations and heuristics:

| Backend Standard Guide | Core Pattern | Mapped Tier 1 Rule | Classification |
| :--- | :--- | :--- | :--- |
| **01. REST API Design** | RFC 9110 HTTP Status Codes | Principle 01 (Clean Code) & Arch 10 (APIs) | **Implements Tier 1 Invariant** |
| **01. REST API Design** | URI Hierarchy Depth ($\le 2$ Levels) | Principle 02 (Simplicity) | **Context-Dependent Recommendation** |
| **01. REST API Design** | OpenAPI 3.1 Contract-First | Lifecycle 04 (Design) & Arch 10 (APIs) | **Specializes Universal Pattern** |
| **02. Data Validation** | Boundary Schema Parsing | Principle 04 (Fail-Fast) & Security 03 (Input Validation) | **Implements Tier 1 Invariant** |
| **02. Data Validation** | Zod / Go-Validator / Bean DTOs | Principle 03 (Modularity) & Security 03 | **Technology-Specific Realization** |
| **03. Auth & Authorization** | Zero Hardcoded Secrets & Alg Pinning | Security 01 (Secrets) & Security 02 (Auth) | **Implements Tier 1 Invariant** |
| **03. Auth & Authorization** | Object-Level Authorization (BOLA/IDOR) | Security 02 (Auth) & Security 07 (Threats) | **Implements Tier 1 Invariant** |
| **03. Auth & Authorization** | Short-Lived Access Token ($\le 15\text{m}$) | Security 02 (Auth) & Security 08 (Config) | **Context-Dependent Recommendation** |
| **04. Service Layer** | Thin Transport Adapters & Domain Rules | Architecture 02 (Clean Arch) & Principle 03 | **Specializes Universal Pattern** |
| **04. Service Layer** | RFC 9457 Problem Details Formatting | Principle 01 (Clean Code) & Principle 04 | **Specializes Universal Pattern** |
| **05. Resilience** | Timeouts on All Outbound Network Calls | Principle 06 (Resilience) & Arch 07 (Modular) | **Implements Tier 1 Invariant** |
| **05. Resilience** | Distributed Rate Limiting & Circuit Breakers | Principle 06 (Resilience) & Arch 07 (Modular) | **Context-Dependent Recommendation** |
| **05. Resilience** | Idempotency-Key Effectively-Once Mutating | Principle 04 (Fail-Fast) & Arch 10 (APIs) | **Specializes Universal Pattern** |
| **06. Observability** | Zero Sensitive Data & Secret Logging | Security 06 (Logging) & Rule 7 (Zero Leaks) | **Implements Tier 1 Invariant** |
| **06. Observability** | Structured JSON Logs & W3C Trace Context | Principle 08 (Simplicity) & Security 06 | **Specializes Universal Pattern** |
| **06. Observability** | Decoupled `/healthz` vs `/readyz` Probes | Principle 06 (Resilience) & Lifecycle 08 | **Specializes Universal Pattern** |

---

## 6. Technology Standards Catalog

The Backend & API standard is structured into 6 comprehensive guides, each adhering strictly to the **9-Part Pedagogical Schema**:

| # | Standard Guide | Core Focus Areas |
| :---: | :--- | :--- |
| **01** | [`01-rest-api-design.md`](01-rest-api-design.md) | Resource URI modeling, RFC 9110 HTTP semantics, status code discipline, cursor vs offset pagination, OpenAPI 3.1 contract-first. |
| **02** | [`02-data-validation-and-serialization.md`](02-data-validation-and-serialization.md) | Controller boundary validation, schema inference (Zod, Go Validator, Bean Validation), mass assignment prevention, serialization hygiene. |
| **03** | [`03-authentication-and-authorization.md`](03-authentication-and-authorization.md) | OAuth 2.0 / OIDC, policy-driven JWT lifetimes, refresh token rotation & reuse detection, algorithm pinning, RBAC vs ABAC, BOLA/IDOR prevention. |
| **04** | [`04-service-layer-and-domain-logic.md`](04-service-layer-and-domain-logic.md) | Layered separation (Controller $\to$ Service $\to$ Repository), transaction boundaries (Unit of Work), RFC 9457 Problem Details error handling. |
| **05** | [`05-resilience-and-fault-tolerance.md`](05-resilience-and-fault-tolerance.md) | Distributed rate limiting, Circuit Breaker pattern, exponential backoff with full jitter, idempotency keys with payload fingerprinting. |
| **06** | [`06-observability-and-logging.md`](06-observability-and-logging.md) | Structured JSON logging, W3C distributed tracing (`traceparent`), OpenTelemetry RED metrics, automated PII/secret scrubbing, health probes. |

---

## 7. Reading & Implementation Order

When designing or implementing backend services:
1. **API Contracts & Data Boundaries**: Study [`01-rest-api-design.md`](01-rest-api-design.md) and [`02-data-validation-and-serialization.md`](02-data-validation-and-serialization.md).
2. **Security & Identity**: Implement authentication and role-based permissions via [`03-authentication-and-authorization.md`](03-authentication-and-authorization.md).
3. **Core Business Logic & Persistence**: Structure the application core using [`04-service-layer-and-domain-logic.md`](04-service-layer-and-domain-logic.md).
4. **Resilience & Production Hardening**: Protect against cascading failures via [`05-resilience-and-fault-tolerance.md`](05-resilience-and-fault-tolerance.md).
5. **Observability & Diagnostics**: Wire production instrumentation using [`06-observability-and-logging.md`](06-observability-and-logging.md).

---

## 8. Concrete Reference Implementation

A self-contained reference implementation demonstrating these standards in practice is located in:
*   [`examples/representative-api.ts`](examples/representative-api.ts) — Production-grade REST endpoint demonstrating Zod boundary validation, RFC 9457 Problem Details error formatting, `Idempotency-Key` processing with payload fingerprinting, and structured correlation ID logging.
*   [`examples/representative-api.test.ts`](examples/representative-api.test.ts) — Automated test suite verifying happy path, validation failures, concurrent lock contention, payload mismatch, and error mappings.
