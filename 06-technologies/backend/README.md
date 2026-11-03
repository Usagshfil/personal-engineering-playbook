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

## 2. Technology Version Governance Matrix

To eliminate version drift and guarantee long-term operational reproducibility, backend projects adhere to these baselines:

| Technology / Component | Minimum Supported | Recommended Baseline | Example Version | Governance & Maintenance Policy |
| :--- | :---: | :---: | :---: | :--- |
| **Node.js Runtime** | `18.18.0` | `20.x LTS` | `20.18.0 LTS` | Standardized via `.nvmrc` and `engines` field in `package.json`. |
| **Go Runtime** | `1.21` | `1.22+` | `1.22.6` | Verified via `go.mod` with strict dependency pinning. |
| **Java / Spring Boot** | Java 17 / SB 3.1 | Java 21 / SB 3.3+ | Java 21 / SB 3.3.3 | Virtual Threads (Project Loom) and GraalVM native compilation support. |
| **API Specification** | `3.0.3` | **OpenAPI 3.1** | `3.1.0` | JSON Schema draft 2020-12 alignment; contract-first specification. |
| **Relational Database** | PostgreSQL 14 | **PostgreSQL 16+** | PostgreSQL 16.4 | ACID compliance, connection pooling (PgBouncer), strict migrations. |
| **HTTP Protocols** | HTTP/1.1 | **HTTP/2 + TLS 1.3** | RFC 9110 / 9113 | Mandated for all external endpoints; internal service mesh mTLS. |
| **Error Specification** | — | **RFC 9457 / RFC 7807** | `application/problem+json` | Uniform machine-readable error responses across all services. |
| **Observability** | — | **OpenTelemetry 1.25+** | OTel SDK 1.25.0 | Vendor-neutral traces, metrics, and logs with W3C Trace Context. |

*Last Verified Matrix Date: 2026-11-03*

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

## 5. Technology Standards Catalog

The Backend & API standard is structured into 6 comprehensive guides, each adhering strictly to the **9-Part Pedagogical Schema**:

| # | Standard Guide | Core Focus Areas |
| :---: | :--- | :--- |
| **01** | [`01-rest-api-design.md`](01-rest-api-design.md) | Resource URI modeling, RFC 9110 HTTP semantics, status code discipline, cursor vs offset pagination, OpenAPI 3.1 contract-first. |
| **02** | [`02-data-validation-and-serialization.md`](02-data-validation-and-serialization.md) | Controller boundary validation, schema inference (Zod, Go Validator, Bean Validation), mass assignment prevention, serialization hygiene. |
| **03** | [`03-authentication-and-authorization.md`](03-authentication-and-authorization.md) | OAuth 2.0 / OIDC, short-lived JWT access tokens ($\le 15\text{m}$), secure token rotation, algorithm pinning, RBAC vs ABAC, zero trust. |
| **04** | [`04-service-layer-and-domain-logic.md`](04-service-layer-and-domain-logic.md) | Layered separation (Controller $\to$ Service $\to$ Repository), transaction boundaries (Unit of Work), RFC 9457 Problem Details error handling. |
| **05** | [`05-resilience-and-fault-tolerance.md`](05-resilience-and-fault-tolerance.md) | Distributed rate limiting (Token Bucket), Circuit Breaker pattern, exponential backoff with jitter, `Idempotency-Key` headers for mutating endpoints. |
| **06** | [`06-observability-and-logging.md`](06-observability-and-logging.md) | Structured JSON logging, W3C distributed tracing (`traceparent`), OpenTelemetry RED metrics, automated PII/secret scrubbing, health probes. |

---

## 6. Reading & Implementation Order

When designing or implementing backend services:
1. **API Contracts & Data Boundaries**: Study [`01-rest-api-design.md`](01-rest-api-design.md) and [`02-data-validation-and-serialization.md`](02-data-validation-and-serialization.md).
2. **Security & Identity**: Implement authentication and role-based permissions via [`03-authentication-and-authorization.md`](03-authentication-and-authorization.md).
3. **Core Business Logic & Persistence**: Structure the application core using [`04-service-layer-and-domain-logic.md`](04-service-layer-and-domain-logic.md).
4. **Resilience & Production Hardening**: Protect against cascading failures via [`05-resilience-and-fault-tolerance.md`](05-resilience-and-fault-tolerance.md).
5. **Observability & Diagnostics**: Wire production instrumentation using [`06-observability-and-logging.md`](06-observability-and-logging.md).

---

## 7. Concrete Reference Implementation

A self-contained reference implementation demonstrating these standards in practice is located in:
*   [`examples/representative-api.ts`](examples/representative-api.ts) — Production-grade REST endpoint demonstrating Zod boundary validation, RFC 9457 Problem Details error formatting, `Idempotency-Key` processing, and structured correlation ID logging.
